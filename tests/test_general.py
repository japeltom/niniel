"""Tests for niniel.cow.general."""

import pytest

from niniel.cow.general import all_words, find_factors, occurrences


# ---------------------------------------------------------------------------
# Test the function all_words.
# ---------------------------------------------------------------------------

class TestAllWords:

    @pytest.mark.parametrize("base", [2, 3, 4])
    @pytest.mark.parametrize("letters", [0, 1, 2, 3, 5, 8])
    def test_count(self, letters, base):
        """Test that the number of generated words is correct."""

        result = set(all_words(letters, base))
        assert len(result) == base**letters

    @pytest.mark.parametrize("base,letters,prefix,expected_count", [
        (2, 5, "0",  2**4),
        (2, 5, "10", 2**3),
        (3, 5, "1",  3**4),
        (3, 6, "21", 3**4),
        (4, 4, "3",  4**3),
    ])
    def test_count_with_prefix(self, base, letters, prefix, expected_count):
        """Test that the number of generated words with a given prefix is
        correct."""

        result = set(all_words(letters, base, prefix=prefix))
        assert len(result) == expected_count

    @pytest.mark.parametrize("base,letters,suffix,expected_count", [
        (2, 5, "1",   2**4),
        (2, 5, "01",  2**3),
        (3, 5, "2",   3**4),
        (3, 6, "12",  3**4),
        (4, 4, "0",   4**3),
    ])
    def test_count_with_suffix(self, base, letters, suffix, expected_count):
        """Test that the number of generated words with a given suffix is
        correct."""

        result = set(all_words(letters, base, suffix=suffix))
        assert len(result) == expected_count

    def test_correct_length(self):
        """Test that the returned words are of correct length."""

        for base in (2, 3):
            for letters in (0, 1, 3, 5):
                for w in all_words(letters, base):
                    assert len(w) == letters

    def test_order(self):
        """Test that the words are generated in lexicographic order."""

        for base in (2, 3):
            for letters in (2, 4):
                words = list(all_words(letters, base))
                assert words == sorted(words)

    def test_start_with_prefix(self):
        """Test that the generated words have the correct prefix."""

        prefix = "10"
        for w in all_words(len(prefix) + 4, 2, prefix=prefix):
            assert w.startswith("10")

    def test_full_prefix(self):
        """Test that only a single word is generated when the prefix is of
        generation length."""

        prefix = "101"
        result = list(all_words(len(prefix), 2, prefix=prefix))
        assert result == [prefix]

    def test_end_with_suffix(self):
        """Test that the generated words have the correct suffix."""

        suffix = "01"
        for w in all_words(len(suffix) + 4, 2, suffix=suffix):
            assert w.endswith(suffix)

    def test_full_suffix(self):
        """Test that only a single word is generated when the suffix is of
        generation length."""

        suffix = "110"
        result = list(all_words(len(suffix), 2, suffix=suffix))
        assert result == [suffix]

    def test_prefix_suffix(self):
        """Test that the generated words have the correct prefix and suffix."""

        prefix = "10"; suffix = "01"
        for w in all_words(len(prefix) + len(suffix) + 2, 2, prefix=prefix, suffix=suffix):
            assert w.startswith("10") and w.endswith("01")

    def test_full_prefix_suffix(self):
        """Test that only a single word is generated when the prefix and suffix
        exhaust the generation length."""

        prefix = "01"; suffix = "10"
        result = list(all_words(len(prefix) + len(suffix), 2, prefix=prefix, suffix=suffix))
        assert result == [prefix + suffix]

    def test_overlap(self):
        """Tests that the code works as intended when the prefix and suffix
        overlap."""

        prefixes = ["01", "010", "010"]
        suffixes = ["10", "101", "010"]
        overlaps = ["010", "0101", "010"]
        for prefix, suffix, overlap in zip(prefixes, suffixes, overlaps):
            result = list(all_words(len(overlap), 2, prefix=prefix, suffix=suffix))
            assert result == [overlap]

        # Test that an exception is raised for incompatible prefix, suffix
        # pairs.
        with pytest.raises(ValueError):
            list(all_words(2, 2, prefix="01", suffix="10"))
        with pytest.raises(ValueError):
            list(all_words(3, 2, prefix="01", suffix="01"))
        with pytest.raises(ValueError):
            list(all_words(4, 2, prefix="010", suffix="001"))

    def test_edge_cases(self):
        """Test parameter edge cases."""

        with pytest.raises(ValueError):
            list(all_words(-1, 2))
        with pytest.raises(ValueError):
            list(all_words(3, 0))
        with pytest.raises(ValueError):
            list(all_words(3, 37))
        with pytest.raises(ValueError):
            list(all_words(2, 2, prefix="010"))
        with pytest.raises(ValueError):
            list(all_words(2, 2, suffix="010"))
        with pytest.raises(ValueError):
            list(all_words(3, 2, prefix="2"))  # "2" not in base-2 alphabet


# ---------------------------------------------------------------------------
# Test function find_factors.
# ---------------------------------------------------------------------------

def _fibonacci_prefix(length):
    """Return a prefix of the Fibonacci word (over {a,b}) of the given
    length."""

    a, b = "a", "ab"
    while len(b) < length:
        a, b = b, b + a
    return b[:length]


def _champernowne_prefix(depth):
    """Return the prefix of the binary Champerowne word of the given depth."""

    w = ""
    for l in range(1, depth + 1):
        for u in all_words(l):
            w += u
    return w


class TestFindFactors:

    def test_known_factors(self):
        """Test for known factors of a word in the order of appearance."""

        assert list(find_factors("abaab", 2)) == ["ab", "ba", "aa"]
        assert list(find_factors("aaaa", 2)) == ["aa"]
        assert list(find_factors("abcd", 1)) == ["a", "b", "c", "d"]
        assert list(find_factors("abbabaabbaababbacabbabaabbaababbad", 1)) == ["a", "b", "c", "d"]

    def test_empty(self):
        """Tests that factors of length 0 are counted correctly."""

        assert list(find_factors("abc", 0)) == [""]
        assert list(find_factors("", 0)) == [""]
        assert list(find_factors("", 1)) == []

    def test_exceeds_length(self):
        """Tests that exceeding length returns nothing."""

        assert list(find_factors("ab", 5)) == []

    def test_equal_length(self):
        """Tests that there is a single factor for full length."""

        assert list(find_factors("hello", 5)) == ["hello"]

    def test_unicode(self):
        """Test that non-ASCII characters are handled correctly."""

        w = "\u03b1\u03b2\u03b1"  # αβα
        assert list(find_factors(w, 2)) == ["\u03b1\u03b2", "\u03b2\u03b1"]

    @pytest.mark.parametrize("n", range(1, 51))
    def test_fibonacci_complexity(self, n):
        """Test that factors of the Fibonacci word are counted correctly."""

        w = _fibonacci_prefix(max(3*n + 10, 200))
        assert len(list(find_factors(w, n))) == n + 1

    @pytest.mark.parametrize("n", range(1, 6))
    def test_champernowne_complexity(self, n):
        """Test that a prefix of the binary Champerowne word has the correct
        number of factors."""

        w = _champernowne_prefix(n)
        assert len(list(find_factors(w, n))) == 2**n

    @pytest.mark.parametrize("w,n", [
        ("abaab", 2),
        ("abcabc", 1),
        ("aaaaab", 3),
        ("abcde", 4),
    ])
    def test_next_length_prefix(self, w, n):
        """Test that the leading block equals the leading block when next_length=False."""

        expected_n = list(find_factors(w, n))
        result = list(find_factors(w, n, next_length=True))
        assert result[:len(expected_n)] == expected_n

    @pytest.mark.parametrize("w,n", [
        ("abaab", 2),
        ("abcabc", 1),
        ("aaaaab", 3),
        ("abcde", 4),
    ])
    def test_next_length_factors(self, w, n):
        """Test that the trailing block is correct when next_length=True."""

        n_factors = list(find_factors(w, n))
        result = list(find_factors(w, n, next_length=True))
        assert set(result[len(n_factors):]) == set(find_factors(w, n + 1))

    @pytest.mark.parametrize("n", range(1, 21))
    def test_next_length_fibonacci(self, n):
        """Test next_length on Fibonacci."""

        w = _fibonacci_prefix(max(3*(n + 1) + 10, 200))
        n_factors = list(find_factors(w, n))
        result = list(find_factors(w, n, next_length=True))
        assert set(result[len(n_factors):]) == set(find_factors(w, n + 1))


# ---------------------------------------------------------------------------
# Test the function occurrences.
# ---------------------------------------------------------------------------

class TestOccurrences:

    def test_basic_occurrences(self):
        """Test basic occurrence counting."""

        assert occurrences("a", "banana") == 3
        assert occurrences("b", "banana") == 1
        assert occurrences("c", "banana") == 0
        assert occurrences("n", "banana") == 2

        assert occurrences("ab", "ababa") == 2
        assert occurrences("a", "aaaa") == 4
        assert occurrences("x", "hello") == 0
        assert occurrences("lo", "hello") == 1

    def test_overlapping_occurrences(self):
        """Test that overlapping occurrences are counted correctly."""

        assert occurrences("aa", "aaaa") == 3
        assert occurrences("010", "01010") == 2
        assert occurrences("aaa", "aaaaa") == 3

    def test_edge_cases(self):
        """Test edge cases like empty strings and full matches."""

        assert occurrences("", "hello") == 6 # Empty string matches at every position.
        assert occurrences("", "") == 1
        assert occurrences("hello", "hello") == 1
        assert occurrences("x", "") == 0

    def test_longer_than_word(self):
        """Test when substring is longer than the word."""

        assert occurrences("hello world", "hello") == 0

    def test_no_occurrences(self):
        """Test when there are no occurrences."""

        assert occurrences("xyz", "abcdef") == 0
        assert occurrences("ab", "xxxxxx") == 0
        assert occurrences("hello", "world") == 0

    @pytest.mark.parametrize("sub,word,expected", [
        ("0", "0101010", 4),
        ("1", "0101010", 3),
        ("01", "0101010", 3),
        ("10", "0101010", 3),
        ("010", "0101010", 3),
        ("101", "0101010", 2),
    ])
    def test_binary_patterns(self, sub, word, expected):
        """Test occurrence counting in binary patterns."""

        assert occurrences(sub, word) == expected

    def test_unicode(self):
        """Test that unicode characters are handled correctly."""

        assert occurrences("α", "αβα") == 2
        assert occurrences("β", "αβα") == 1
        assert occurrences("αβ", "αβα") == 1
        assert occurrences("αβα", "αβαβαβ") == 2
