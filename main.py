#!/usr/bin/env python3

import time
import argparse
from collections import defaultdict
from collections.abc import Iterator


def word_to_num(word: str) -> int:
    """
    Convert word into a 26-bit number, each bit representing
    presence of a letter.
    Assumes the word is made of only lowercase letters a-z.

    Examples:
    ========

    word_to_num("abc") == 0b111 == 7
    word_to_num("abcd") == 0b1111 == 15
    word_to_num("ca") == 0b101 == 5
    """
    num = 0
    for letter in word:
        num |= 1 << (ord(letter) - ord('a'))
    return num


def make_graph(words_by_num: dict[int, list[str]]) -> dict[int, set[int]]:
    """
    Make a dict where keys are numbers representing words and values are
    sets of neighbors for that node. For performance reasons only the
    neighbors that come AFTER the node are stored.
    """
    nodes = {}
    word_nums = sorted(words_by_num.keys())
    for i, k1 in enumerate(word_nums):
        neighbors = set()
        # check which other keys have no bits (letters) in common
        for k2 in word_nums[i + 1:]:
            if (k1 & k2) == 0:
                neighbors.add(k2)
        nodes[k1] = neighbors
    return nodes


def find_cliques(graph: dict[int, set[int]]) -> Iterator[list[int]]:
    """
    Finds sets of 5 nodes that are all connected to each other.
    """
    for i, i_neighbors in graph.items():
        for j in i_neighbors:
            ij_neighbors = i_neighbors & graph[j]
            for k in ij_neighbors:
                ijk_neighbors = ij_neighbors & graph[k]
                for m in ijk_neighbors:
                    ijkm_neighbors = ijk_neighbors & graph[m]
                    for n in ijkm_neighbors:
                        yield [i, j, k, m, n]


def clique_to_str(nums: list[int], num2word: dict[int, list[str]]) -> str:
    """
    Turns a list of numbers representing words into a string.

    Example:
    =======

    clique_to_str(
        [31, 992, 31744, 1015808, 61865984],
        {
            31: ['abcde', 'deabc'],
            992: ['fghij'],
            31744: ['klmno'],
            1015808: ['pqrst'],
            61865984: ['uvxyz']
        }
    ) == "abcde|deabc,fghij,klmno,pqrst,uvxyz"
    """
    words = ["|".join(sorted(num2word[num])) for num in nums]
    return ",".join(sorted(words))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-w",
        "--wordsfile",
        type=str,
        metavar="WORDSFILE",
        default="test.txt",
    )
    parser.add_argument(
        "-o",
        "--outputfile",
        type=str,
        metavar="OUTPUTFILE",
        default="results.txt",
    )
    args = parser.parse_args()

    t0 = time.time()

    print(f"Reading words (from {args.wordsfile})...")
    with open(args.wordsfile, "r") as f:
        words = [word.rstrip() for word in f]

    words_by_num = defaultdict(list)
    for word in words:
        letters = set(word)
        if len(word) == 5 and len(letters) == 5:
            # anagrams are equivalent after word_to_num so they
            # will be stored in a list
            words_by_num[word_to_num(word)].append(word)
    print(f"Found {len(words_by_num)} distinct 5-letter words",
          "with 5 distinct letters (after removing anagrams)")

    print("Building a graph...")
    graph = make_graph(words_by_num)

    print("Finding cliques of 5 words...")
    cliques = find_cliques(graph)
    clique_strs = sorted(clique_to_str(cliq, words_by_num) for cliq in cliques)

    with open(args.outputfile, "w") as f:
        for cliq in clique_strs:
            f.write(f"{cliq}\n")

    t1 = time.time()

    print(f"Done! Found {len(clique_strs)} cliques in {t1 - t0:.3f} seconds.")
    print(f"Results were written to {args.outputfile}")


if __name__ == "__main__":
    main()
