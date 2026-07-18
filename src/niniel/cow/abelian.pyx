# cython: embedsignature=True
cimport cython

from niniel.cow.general import occurrences, find_factors


@cython.boundscheck(False)
@cython.wraparound(False)
cdef bint _test_abelian_equivalent_k1(str u, str v):
    cdef:
        dict counts = {}
        str c
        int count
    
    # Count characters in u (increment).
    for c in u:
        count = counts.get(c, 0)
        counts[c] = count + 1
    
    # Subtract counts for characters in v (decrement).
    for c in v:
        count = counts.get(c, 0)
        counts[c] = count - 1
    
    # Check if all counts are zero.
    for count in counts.values():
        if count != 0:
            return False
    
    return True


@cython.boundscheck(False)
@cython.wraparound(False)
cdef bint _test_abelian_equivalent_k_general(str u, str v, int k):
    cdef:
        long l = len(u)
        str w
    
    # Test that the prefixes and suffixes of length k - 1 are equal.
    # Notice that this is not necessary, but it can detect False earlier.
    if u[:k-1] != v[:k-1]: 
        return False
    if u[l - (k - 1):l] != v[l - (k - 1):l]: 
        return False

    # Test that each factor of u of length k occurs in v equally many times.
    # TODO: The efficiency could likely be improved.
    for w in find_factors(u, k):
        if occurrences(w, u) != occurrences(w, v):
            return False

    return True


@cython.boundscheck(False)
@cython.wraparound(False)
cpdef bint test_abelian_equivalent(str u, str v, int k = 1):
    """Test if words ``u`` and ``v`` are k-abelian equivalent.

    Args:
        u (str): The first word.
        v (str): The second word.
        k (int): The abelian order. Defaults to 1.

    Raises:
        ValueError: If `k` is not positive.

    Returns:
        bool: True if ``u`` and ``v`` are k-abelian equivalent, False
            otherwise.

    Examples:
        >>> test_abelian_equivalent("abc", "bca")
        True
        >>> test_abelian_equivalent("abc", "abd")
        False
        >>> test_abelian_equivalent("aabaa", "abaaa", k=2)
        True
    """
    
    if k <= 0:
        raise ValueError("The parameter k must be positive.")

    if len(u) != len(v): 
        return False

    if k == 1:
        return _test_abelian_equivalent_k1(u, v)
    else:
        return _test_abelian_equivalent_k_general(u, v, k)
