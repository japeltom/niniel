# cython: profile=False

import cython

from libc.stdlib cimport malloc, free, realloc
from libc.string cimport memcpy, memset
from cpython.bytes cimport PyBytes_FromStringAndSize

cdef extern from "Python.h":
    object PyUnicode_DecodeASCII(const char *s, Py_ssize_t size, const char *errors)

cdef extern from "general_.h":
    void odometer_init(char *word, int n)
    int  odometer_increment(char *word, int n, int base)
    int* ff_trans_expand_cols(int *trans, int capacity, int old_A, int new_A, int k)
    int* ff_trans_expand_rows(int *trans, int old_capacity, int new_capacity, int A)


def all_words(int letters, int base = 2, str prefix = "", str suffix = ""):
    """Generate all words of length `letters` over the alphabet
    {0, 1, ..., `base` - 1} in lexicographic order. Optionally a fixed prefix
    and/or suffix can be specified.

    Args:
        letters (int): The length of each generated word.
        base (int): The alphabet size. Must be from 1 to 36.
        prefix (str): Fixed string prepended to every word. Defaults to empty.
        suffix (str): Fixed string appended to every word. Defaults to empty.

    Yields:
        str: The next word of length `letters` that starts with `prefix` and
            ends with `suffix`.

    Raises:
        ValueError: If `base` is not between 1 and 36.
        ValueError: If `letters` is negative.
        ValueError: If the length of `prefix` or `suffix` exceeds `letters`.
        ValueError: If `prefix` or `suffix` contain characters that are not
            valid for the given `base`.
        ValueError: If `prefix` and `suffix` overlap but are inconsistent for
            the given length.

    Examples:
        >>> list(all_words(2))
        ['00', '01', '10', '11']
        >>> list(all_words(3, base=3, prefix="1"))
        ['100', '101', '102', '110', '111', '112', '120', '121', '122']
        >>> list(all_words(4, suffix="0"))
        ['0000', '0010', '0100', '0110', '1000', '1010', '1100', '1110']
    """

    if base < 1 or base > 36:
        raise ValueError("The parameter `base` must be from 1 to 36.")
    if letters < 0:
        raise ValueError("The parameter `letters` must be nonnegative.")

    cdef int prefix_len = len(prefix)
    cdef int suffix_len = len(suffix)
    cdef int gen_len = letters - prefix_len - suffix_len

    if prefix_len > letters:
        raise ValueError(f"Prefix length {prefix_len} exceeds `letters` ({letters}).")
    if suffix_len > letters:
        raise ValueError(f"Suffix length {suffix_len} exceeds `letters` ({letters}).")
    valid_chars = "0123456789abcdefghijklmnopqrstuvwxyz"[:base]
    for ch in prefix:
        if ch not in valid_chars:
            raise ValueError(f"Prefix character {ch!r} is not valid for base {base}.")
    for ch in suffix:
        if ch not in valid_chars:
            raise ValueError(f"Suffix character {ch!r} is not valid for base {base}.")

    if gen_len < 0:
        overlap_len = prefix_len + suffix_len - letters
        if prefix[letters - suffix_len:] != suffix[:overlap_len]:
            raise ValueError(f"Prefix {prefix!r} and suffix {suffix!r} have incompatible overlaps.")
        yield prefix + suffix[overlap_len:]
        return

    if gen_len == 0: yield prefix + suffix; return
    if base == 1: yield prefix + "0" * gen_len + suffix; return

    cdef:
        char *result  = <char *>malloc((letters + 1)*sizeof(char))
        bytes pb, sb
    if not result:
        raise MemoryError()

    try:
        result[letters] = '\0'
        if prefix_len > 0:
            pb = prefix.encode("ascii")
            memcpy(result, <const char *>pb, prefix_len)
        if suffix_len > 0:
            sb = suffix.encode("ascii")
            memcpy(result + (letters - suffix_len), <const char *>sb, suffix_len)
        odometer_init(result + prefix_len, gen_len)
        yield PyUnicode_DecodeASCII(result, letters, NULL)
        while odometer_increment(result + prefix_len, gen_len, base):
            yield PyUnicode_DecodeASCII(result, letters, NULL)
    finally:
        free(result)


cdef inline bytes _circ_key(int *circ, int p, int n, int *key_buf, Py_ssize_t key_nbytes):
    """Return a bytes deduplication key for the factor of length n ending at
    position p.

    Reads circ[(p+1)%n .. p%n] (the last n encoded letters) and flattens the
    wrap with at most two memcpy calls into key_buf before handing off to
    PyBytes_FromStringAndSize.
    """

    cdef int start_idx = (p + 1) % n
    if start_idx == 0:
        return PyBytes_FromStringAndSize(<const char *>circ, key_nbytes)
    memcpy(key_buf, circ + start_idx, (n - start_idx) * sizeof(int))
    memcpy(key_buf + (n - start_idx), circ, start_idx * sizeof(int))
    return PyBytes_FromStringAndSize(<const char *>key_buf, key_nbytes)


@cython.boundscheck(False)
@cython.wraparound(False)
def find_factors(str w, int n, bint next_length=False):
    """Generator that yields all distinct factors of ``w`` of length ``n`` in
    order of first appearance, optionally filtered by a predicate.

    Args:
        w (str): Input word.
        n (int): Factor length.
        next_length (bool): If True, the factors of length n+1 are yielded
            after all factors of length ``n``. This is strictly cheaper than a
            second call with n+1 in place of ``n``.

    Yields:
        str: Distinct factors of length ``n`` in the order of appearance. If
            ``next_length`` is True, distinct factors of length ``n + 1`` are
            also returned (order not guaranteed).

    Raises:
        ValueError: If n is negative.

    Examples:
        >>> list(find_factors("abaab", 2))
        ['ab', 'ba', 'aa']
        >>> list(find_factors("aaaa", 2))
        ['aa']
        >>> list(find_factors("abcd", 1))
        ['a', 'b', 'c', 'd']
        >>> list(find_factors("abaab", 2, next_length=True))
        ['ab', 'ba', 'aa', 'aba', 'baa', 'aab']
    """

    """
    The idea is to build an maintain a Rauzy graph for the factors of length n.
    In order to support unicode charecters, we map the characters to integers
    and work with them. Some fancy bookkeeping is done for efficiency.
    """

    if n < 0:
        raise ValueError("The parameter `n` must be nonnegative.")

    cdef:
        int l, A, capacity, old_capacity, k, state, p, letter, j, new_start, s
        int *circ              # Circular buffer of last n encoded letters.
        int *key_buf           # Flat scratch buffer for key construction, size n.
        int *trans             # Flat 2-D transition table, capacity * A entries.
        int *_tmp              # Scratch pointer for safe allocation calls.
        Py_ssize_t key_nbytes  # Byte width of one factor key = n * sizeof(int).
        bytes factor_key
        str factor_str, ch
        dict factor_map, char_to_idx
        list idx_to_char, factor_strs

    circ    = NULL
    key_buf = NULL
    trans   = NULL

    # Case n = 0.
    if n == 0:
        yield ""
        if next_length:
            for fac in find_factors(w, 1, next_length=False):
                yield fac
        return

    l = len(w)
    if n > l:
        return

    try:
        key_nbytes = <Py_ssize_t>n * sizeof(int)

        # Create a circular buffer (encoded) for the current factor of length
        # n.
        circ = <int *>malloc(n * sizeof(int))
        if not circ:
            raise MemoryError()
        # Allocate memory for a scratch buffer.
        key_buf = <int *>malloc(n * sizeof(int))
        if not key_buf:
            raise MemoryError()

        # Phase 1: initialize the encoding data structures by reading the
        # positions 0..n-1. After this, the data structures are enlargened by
        # demand. Notice that after this loop circ[0..n-1] contains the prefix
        # of length n (encoded as integers).
        # ---------------------------------------------------------------------
        char_to_idx = {} # Maps characters to integers.
        idx_to_char = [] # The reverse map.
        A = 0            # Observed alphabet size.
        for p in range(n):
            ch = w[p]
            letter = char_to_idx.get(ch, -1)
            if letter == -1:
                char_to_idx[ch] = A
                idx_to_char.append(ch)
                letter = A
                A += 1
            circ[p] = letter

        # We allocate a Rauzy graph transition table. We assume A transitions
        # per state, where A is the number of letters observed so far. We
        # increase the size on demand.
        # ---------------------------------------------------------------------
        capacity = 8 # Upper bound on the number of states.
        trans = <int *>malloc(capacity*A * sizeof(int))
        if not trans:
            raise MemoryError()
        memset(trans, 0xFF, capacity*A * sizeof(int)) # Set all transitions to -1 (i.e., no transition).

        # --------------------------------------------------------------
        # Initialise with the first factor w[0:n].
        # After phase 1 the circular buffer is contiguous (start_idx == 0)
        # so circ[0..n-1] is the initial factor's key directly.
        # --------------------------------------------------------------
        factor_map   = {} # Stores the mapping from factor keys to state indices.
        factor_key   = _circ_key(circ, n - 1, n, key_buf, key_nbytes)
        factor_map[factor_key] = 0
        factor_strs  = [w[:n]] if next_length else None # Stores the reverse mapping of factor map (needed only if next_length is True).
        state        = 0 # Current state.
        k            = 0 # Number of states in the Rauzy graph - 1.

        yield w[:n]

        # Main scan.
        # ---------------------------------------------------------------------
        for p in range(n, l):
            # Encode w[p] to an integer, and expand the alphabet if needed.
            ch = w[p]
            letter = char_to_idx.get(ch, -1)
            if letter == -1:
                # New letter: update the encoding and resize the transition
                # table with one extra column.
                char_to_idx[ch] = A
                idx_to_char.append(ch)

                _tmp = ff_trans_expand_cols(trans, capacity, A, A + 1, k)
                if not _tmp: raise MemoryError()
                trans  = _tmp
                letter = A
                
                A += 1
                
            # Update the circular buffer with the new encoded letter.
            circ[p % n] = letter

            # Read the next state from the transition table.
            j = trans[state*A + letter]

            if j == -1:
                # No transition. Check if the factor is genuinely new and yield
                # if so.
                
                # Get the actual factor for the current state. We need to check
                # if it is already in factor_map (a new transition to an
                # existing state) or if the factor is genuinely new.
                factor_key = _circ_key(circ, p, n, key_buf, key_nbytes)
                j = factor_map.get(factor_key, -1)
                if j == -1:
                    # Genuinely new factor: grow capacity if needed.
                    if k + 1 >= capacity:
                        old_capacity = capacity
                        capacity = int(1.5*capacity) if capacity > 512 else capacity*2
                        _tmp = ff_trans_expand_rows(trans, old_capacity, capacity, A)
                        if not _tmp: raise MemoryError()
                        trans = _tmp

                    k += 1
                    j = k
                    new_start = p - n + 1
                    factor_map[factor_key] = k
                    factor_str = w[new_start:p + 1]
                    if next_length:
                        factor_strs.append(factor_str)
                    yield factor_str

                trans[state*A + letter] = j

            state = j

        # If next_length is True, yield also the factors of length n+1 that are
        # easily deducible from the collected date.
        # ---------------------------------------------------------------------
        if next_length:
            for s in range(k + 1):
                for letter in range(A):
                    if trans[s*A + letter] != -1:
                        factor_str = factor_strs[s] + idx_to_char[letter]
                        yield factor_str
    finally:
        if circ != NULL: free(circ)
        if key_buf != NULL: free(key_buf)
        if trans != NULL: free(trans)
