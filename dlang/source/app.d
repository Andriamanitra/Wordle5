import std.array;
import std.range;
import std.uni;
import std.getopt;
import std.stdio;
import std.conv;
import std.string : splitLines;
import std.file;
import std.algorithm;
import core.time;

uint toNum(in string word) {
    uint num = 0;
    foreach (letter; word) {
        uint shiftAmount = letter - 'a';
        num |= 1 << shiftAmount;
    }
    return num;
}

bool[uint][uint] makeGraph(in string[][uint] wordsByNum) {
    bool[uint][uint] nodes;

    auto wordNums = wordsByNum.keys;
    wordNums.sort;

    foreach(i, a; wordNums) {
        bool[uint] neighbors;
        foreach(b; wordNums[i + 1 .. $]) {
            if ((a & b) == 0) {
                neighbors[b] = true;
            }
        }
        nodes[a] = neighbors;
    }
    return nodes;
}

pure bool[uint] setIntersection(in bool[uint] setA, in bool[uint] setB) {
    bool[uint] result;
    foreach (k; setA.keys) {
        if (k in setB) {
            result[k] = true;
        }
    }
    return result;
}

uint[][] findCliques(in bool[uint][uint] graph) {
    uint[][] result;
    foreach (i; graph.keys) {
        auto i_neighbors = graph[i];
        foreach (j; i_neighbors.keys) {
            auto ij_neighbors = setIntersection(i_neighbors, graph[j]);
            foreach (k; ij_neighbors.keys) {
                auto ijk_neighbors = setIntersection(ij_neighbors, graph[k]);
                foreach (m; ijk_neighbors.keys) {
                    auto ijkm_neighbors = setIntersection(ijk_neighbors, graph[m]);
                    foreach(n; ijkm_neighbors.keys) {
                        result ~= [i, j, k, m, n];
                    }
                }
            }
        }
    }
    return result;
}



void main(string[] args) {
    string wordsFileName = "../test.txt";
    string outputFileName = "dresults.txt";
    auto getoptResult = getopt(
        args,
        "wordsfile|w", "WORDSFILE", &wordsFileName,
        "outputfile|o", "OUTPUTFILE", &outputFileName
    );
    if (getoptResult.helpWanted) {
        defaultGetoptPrinter("./main [-w WORDSFILE]", getoptResult.options);
        return;
    }

    auto tBefore = MonoTime.currTime;

    writeln("Reading words (from ", wordsFileName, ")...");
    auto words = std.file.readText(wordsFileName).splitLines;
    string[][uint] wordsByNum;
    foreach(word; words) {
        if (word.length != 5 || word[].array.sort.uniq.walkLength != 5) continue;
        auto num = word.toNum;
        if (num in wordsByNum) {
            wordsByNum[num] ~= word;
        } else {
            wordsByNum[num] = [word];
        }
    }

    writeln(
        "Found ",
        wordsByNum.length,
        " distinct 5-letter words with 5 distinct letters (after removing anagrams)"
    );

    writeln("Building a graph...");
    auto graph = makeGraph(wordsByNum);

    writeln("Finding cliques of 5 words...");
    auto cliques = findCliques(graph);

    string[] cliquesStrs;
    foreach (cliq; cliques) {
        cliquesStrs ~= cliq.map!(num => wordsByNum[num].sort.join('|')).array.sort.join(',');
    }

    auto tAfter = MonoTime.currTime;
    long nsecs = ticksToNSecs(tAfter.ticks - tBefore.ticks);

    writefln("Done! Found %d cliques in %.3f seconds.", cliques.length, nsecs / 1e9);

    auto outputFile = File(outputFileName, "w");
    foreach(s; cliquesStrs.sort) {
        outputFile.writeln(s);
    }
    writeln("Results were written to ", outputFileName);
}
