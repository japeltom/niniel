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


@cython.boundscheck(False)
@cython.wraparound(False)
cpdef tuple test_abelian_cyclic_avoidance(str w, int k):
    """Test if the word ``w`` avoids abelian k-powers cyclically.
    
    Args:
        w (str): The word to test.
        k (int): The power parameter.

    Returns:
        tuple: A tuple with three elements:
            - bool: True if the word avoids abelian k-powers circularly, 
              False otherwise.
            - int or None: If an abelian k-power is found, the period of this
              power; None if the word avoids abelian k-powers cyclically.
            - int or None: If an abelian k-power is found, the starting 
              position of it; None if the word avoids abelian k-powers
              cyclically.

    Examples:
        >>> test_abelian_cyclic_avoidance("abc", 2)
        (True, None, None)
        >>> test_abelian_cyclic_avoidance("aa", 2)
        (False, 1, 0)
    """

    cdef:
        str s = w * (k + 1)
        int m, pos, i
        bint obstruction
        str fst
        int w_len = len(w)
        int half_len = w_len // 2
    
    # By a general result, we only need to consider periods up to half the
    # length of w.
    for m in range(1, half_len + 1):
        for pos in range(0, w_len):
            # Test if s has an abelian k-power of period m starting at pos.
            obstruction = True
            fst = s[pos:pos + m]
            for i in range(1, k):
                if not test_abelian_equivalent(s[pos + i*m:pos + (i+1)*m], fst):
                    obstruction = False
                    break

            if obstruction:
                return (False, m, pos)

    return (True, None, None)
