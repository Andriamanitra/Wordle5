#!/usr/bin/env julia

"""
    word_to_num(word)

Convert word into a 26-bit number, each bit representing
presence of a letter.
Assumes the word is made of only lowercase letters a-z.

# Examples
```julia-repl
julia> word_to_num("a")
1

julia> word_to_num("abc")
7

julia> word_to_num("cabaca")
7
```
"""
function word_to_num(word::String)
    num = UInt32(0)
    for letter in word
        num |= UInt32(1) << (letter - 'a')
    end
    return num
end


"""
Make a dict where keys are numbers representing words and values are
sets of neighbors for that node. For performance reasons only the
neighbors that come AFTER the node are stored.
"""
function make_graph(words_by_num::Dict{UInt32, Vector{String}})
    nodes = Dict{UInt32, Set{UInt32}}()
    word_nums = words_by_num |> keys |> collect |> sort

    for (i, k1) in enumerate(word_nums)
        neighbors = Set{UInt32}()
        # check which other keys have no bits (letters) in common
        for k2 in word_nums[i+1:end]
            if (k1 & k2) == 0
                push!(neighbors, k2)
            end
        end
        nodes[k1] = neighbors
    end

    return nodes
end


# there's intersect(::Set, i...) in standard library but this specialized method is faster
function intersect(setA::Set{T}, setB::Set{T}) where T
    Set(a for a in setA if a in setB)
end


"Finds sets of 5 nodes that are all connected to each other."
function find_cliques(graph::Dict{UInt32, Set{UInt32}})
    result = Vector{Vector{UInt32}}()
    for (i, i_neighbors) in graph
        for j in i_neighbors
            ij_neighbors = intersect(i_neighbors, graph[j])
            for k in ij_neighbors
                ijk_neighbors = intersect(ij_neighbors, graph[k])
                for m in ijk_neighbors
                    ijkm_neighbors = intersect(ijk_neighbors, graph[m])
                    for n in ijkm_neighbors
                        push!(result, [i, j, k, m, n])
                    end
                end
            end
        end
    end
    result
end


"Turns a list of numbers representing words into a string."
function clique_to_str(nums::Vector{UInt32}, num2word::Dict{UInt32, Vector{String}})
    words = [join(sort(num2word[num]), "|") for num in nums]
    return join(sort(words), ",")
end


function main()
    wordsfile = "../test.txt"
    outputfile = "jlresults.txt"
    help_text = "Usage: ./main.jl [-w WORDSFILE] [-o OUTPUTFILE]"

    while length(ARGS) > 0
        arg = popfirst!(ARGS)
        if arg == "-w" || arg == "--wordsfile"
            wordsfile = popfirst!(ARGS)
        elseif arg == "-o" || arg == "--outputfile"
            outputfile = popfirst!(ARGS)
        elseif arg == "-h" || arg == "--help"
            println(help_text)
            exit(0)
        else
            println(help_text)
            exit(1)
        end
    end

    t0 = time()

    println("Reading words (from $wordsfile)...")
    words = readlines(wordsfile)

    words_by_num = Dict{UInt32, Vector{String}}()
    for word in words
        letters = Set(word)
        if length(word) == 5 && length(letters) == 5
            # anagrams are equivalent after word_to_num so they
            # will be stored in a list
            num = word_to_num(word)
            if haskey(words_by_num, num)
                push!(words_by_num[num], word)
            else
                words_by_num[num] = [word]
            end
        end
    end

    println("Found $(length(words_by_num)) distinct 5-letter words",
            "with 5 distinct letters (after removing anagrams)")

    println("Building a graph...")
    graph = make_graph(words_by_num)

    println("Finding cliques of 5 words...")
    cliques = find_cliques(graph)
    clique_strs = [clique_to_str(cliq, words_by_num) for cliq in cliques]

    t1 = time()
    msecs = round(Int, 1000 * (t1 - t0))

    println("Done! Found $(length(clique_strs)) cliques in $(msecs/1000) seconds.")

    sort!(clique_strs)

    open(outputfile, "w") do f
        for cliq in clique_strs
            write(f, "$cliq\n")
        end
    end

    println("Results were written to $outputfile")
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
