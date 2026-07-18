from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension("niniel.cow.general", ["src/niniel/cow/general.pyx", "src/niniel/cow/general_.c"]),
    Extension("niniel.cow.abelian", ["src/niniel/cow/abelian.pyx"]),
]

setup(
    ext_modules=cythonize(
        extensions,
        compiler_directives={"language_level": "3"},
    ),
)
