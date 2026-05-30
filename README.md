# niniel
Small, simple, and fast math library concentrating on combinatorics on words.

## Purpose
The purpose of this library is to collect the code I have written over the
years to assist me in doing research in combinatorics on words. The aim of the
library is to be small (few dependencies), simple (you do not need to absorb a
complicated framework), and fast (Python and SageMath are slow). Additionally,
the library is expected to be correct (ensured via testing).

The current version has very few functions, but this is subject to change over time. It takes time to translate old
code into good and tested code.

## Installation
You need to install Cython and a C compiler on you system. After this, you can just run `install.sh` to install the
library to your currently active virtual environment. The dependencies listed in `requirements.txt` are not needed to
use the library.

## Use
The objects of study in combinatorics on words are words, that is, sequences of
symbols. In niniel, a word is represented as a Python string (Unicode is
supported). The idea is that you do whatever word manipulation you want on
Python strings and occasionally call niniel utility functions to perform some
more complicated tasks on words.

The following code lists all words of length $20$ over a ternary alphabet. The function `all_words` is quite convenient
to find examples and counter examples.

```python
from niniel.cow.general import all_words

for w in all_words(20, 3):
    print(w)
```

The next code block finds all factors of length $3$ of the word $abbabaabbaababba$.

```python
from niniel.cow.general import find_factors

for w in find_factors("abbabaabbaababba", 3):
    print(w)
```

Please study the docstrings of the functions `all_words` and `find_factors` in `src/cow/niniel/cow/general.pyx` to
learn more.
