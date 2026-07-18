"""Tests for niniel.abelian."""

import pytest

from niniel.cow.abelian import test_abelian_equivalent as is_abelian_equivalent


# ---------------------------------------------------------------------------
# Test the function test_abelian_equivalent.
# ---------------------------------------------------------------------------

class TestAbelianEquivalent:

    @pytest.mark.parametrize("u,v", [
        ("abc", "bca"),
        ("abc", "cab"),
        ("abc", "acb"),
        ("aab", "aba"),
        ("aab", "baa"),
        ("aabb", "abab"),
        ("aabb", "baba"),
        ("aaabbb", "ababab"),
        ("aabbcc", "abcabc"),
        ("aabbcc", "cabcab"),
    ])
    def test_equivalent_k1(self, u, v):
        """Test pairs that are abelian equivalent."""

        assert is_abelian_equivalent(u, v)

    @pytest.mark.parametrize("u,v", [
        ("abc", "abd"),
        ("aaa", "aa"),
        ("ab", "abb"),
        ("xyz", "abc"),
        ("aaaa", "aaab"),
        ("aabb", "aaab"),
        ("0011", "0111"),
    ])
    def test_not_equivalent_k1(self, u, v):
        """Test pairs that are not abelian equivalent."""

        assert not is_abelian_equivalent(u, v)

    @pytest.mark.parametrize("word", ["hello", "test", "abc", "a", ""])
    def test_identical_words_k1(self, word):
        """Test that identical words are abelian equivalent."""

        assert is_abelian_equivalent(word, word)

    @pytest.mark.parametrize("word,k", [
        ("hello", 2),
        ("test", 2),
        ("abc", 3),
        ("abcdef", 1),
        ("abcdef", 2),
        ("abcdef", 3),
        ("abcdef", 4),
        ("aabbcc", 1),
        ("aabbcc", 2),
        ("aabbcc", 3),
    ])
    def test_identical_words_all_k(self, word, k):
        """Test that identical words are k-abelian equivalent"""

        assert is_abelian_equivalent(word, word, k=k)

    @pytest.mark.parametrize("u,v", [
        ("ab", "abc"),
        ("hello", "helo"),
        ("a", "aa"),
        ("", "a"),
        ("abc", "abcd"),
    ])
    def test_different_lengths(self, u, v):
        """Test that words of different lengths are not equivalent."""

        assert not is_abelian_equivalent(u, v)

    def test_empty_strings(self):
        """Test empty string cases."""

        assert is_abelian_equivalent("", "")
        assert is_abelian_equivalent("", "", k=2)

    @pytest.mark.parametrize("u,v", [
        ("aabaa", "abaaa"),
        ("00101", "01001"),
        ("10010", "10100"),
        ("ααβαα", "αβααα"),
    ])
    def test_equivalent_k2(self, u, v):
        """Test pairs that are 2-abelian equivalent."""

        assert is_abelian_equivalent(u, v, k=2)

    @pytest.mark.parametrize("u,v,k", [
        ("aaba", "baab", 2),
        ("aaba", "abaa", 3),
        ("ααβα", "βααβ", 2),
    ])
    def test_not_equivalent_all_k(self, u, v, k):
        """Test pairs that are not k-abelian equivalent."""

        assert not is_abelian_equivalent(u, v, k=k)
    
    def test_exceptions(self):
        """Test that invalid inputs raise exceptions."""
        
        with pytest.raises(ValueError):
            is_abelian_equivalent("abc", "abc", k=0)
