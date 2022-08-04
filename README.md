# Wordle 5

Figuring out different ways to guess 5 different Wordle words without repeating any letter.
Inspired by [Stand-up Maths video](https://www.youtube.com/watch?v=_-AfhLQfb6w).

A good write-up of the algorithm used is found on [Benjamin Paassen's Gitlab repository](https://gitlab.com/bpaassen/five_clique/-/tree/main/).
I think I'm fundamentally using the same algorithm, just a little bit more optimized.
As a result my code runs in about 2 minutes (or 1 minute with PyPy) with the same set of words that takes his
code around 19 minutes. My version also uses significantly less memory (0.2GB vs 1.5 GB).

The two main tricks that make my version significantly faster are:
1. Not storing neighbor relationships twice. If A and B are neighbors my algorithm adds B to A's set of neighbors but DOESN'T add A to B's set of neighbors. This both drastically reduces memory usage and cuts down the number of iterations.
2. Encoding words into numbers so the same number represents all of the words made of same letters.