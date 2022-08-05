use std::collections::{HashMap, HashSet, VecDeque};
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::process::exit;

fn print_help(executable: &str) {
    println!("Usage: {} [-w WORDSFILE] [-o OUTPUTFILE]", executable);
}

fn parse_args() -> (String, String) {
    let mut wordsfile = String::from("../test.txt");
    let mut outputfile = String::from("rsults.txt");
    let mut args: VecDeque<String> = env::args().collect();
    let executable = args.pop_front().unwrap();

    while !args.is_empty() {
        let arg = args.pop_front().expect("arg error");
        if arg == "-w" || arg == "--wordsfile" {
            wordsfile = args.pop_front().expect("No wordsfile specified");
        } else if arg == "-o" || arg == "--outputfile" {
            outputfile = args.pop_front().expect("No outputfile specified");
        } else if arg == "-h" || arg == "--help" {
            print_help(&executable);
            exit(0)
        } else {
            print_help(&executable);
            exit(1)
        }
    }
    (wordsfile, outputfile)
}

fn main() {
    let (wordsfile, outputfile) = parse_args();
    println!("Reading words (from '{}')", wordsfile);
    let file = File::open(wordsfile).expect("Unable to open file");
    let lines = io::BufReader::new(file).lines();
    let mut words_by_num: HashMap<u32, Vec<String>> = HashMap::new();
    for line in lines {
        if let Ok(line) = line {
            if line.len() == 5 && line.chars().collect::<HashSet<_>>().len() == 5 {
                // mapping from word to number such that all anagrams map to the same number
                let mut num: u32 = 0;
                for b in line.bytes() {
                    num |= 1 << (b - 97);
                }
                if let Some(words_vec) = words_by_num.get_mut(&num) {
                    words_vec.push(line)
                } else {
                    words_by_num.insert(num, vec![line]);
                }
            }
        }
    }

    let start_time = std::time::Instant::now();

    let nums = words_by_num.keys().collect::<Vec<&u32>>();
    println!(
        "Found {} distinct 5-letter words with 5 distinct letters (after removing anagrams)",
        nums.len()
    );
    println!("Creating graph...");
    let mut graph: HashMap<u32, HashSet<u32>> = HashMap::new();
    for (i, num_a) in nums.iter().enumerate() {
        let mut neighbors: HashSet<u32> = HashSet::new();
        for j in i + 1..nums.len() {
            let num_b = nums[j];
            if *num_a & num_b == 0 {
                neighbors.insert(*num_b);
            }
        }
        graph.insert(**num_a, neighbors);
    }
    let graph = graph;
    let mut results: Vec<Vec<u32>> = Vec::new();
    println!("Finding cliques of 5 words...");
    for (i, i_neighbors) in &graph {
        for j in i_neighbors {
            let j_neighbors: &HashSet<u32> = &graph[j];
            let ij_neighbors: HashSet<u32> =
                i_neighbors.intersection(&j_neighbors).copied().collect();
            for k in &ij_neighbors {
                let k_neighbors: &HashSet<u32> = &graph[k];
                let ijk_neighbors: HashSet<u32> =
                    ij_neighbors.intersection(&k_neighbors).copied().collect();
                for m in &ijk_neighbors {
                    let m_neighbors: &HashSet<u32> = &graph[m];
                    let ijkm_neighbors: HashSet<u32> =
                        ijk_neighbors.intersection(&m_neighbors).copied().collect();
                    for n in &ijkm_neighbors {
                        results.push(vec![*i, *j, *k, *m, *n]);
                    }
                }
            }
        }
    }
    let mut result_lines = results
        .iter()
        .map(|w_nums| {
            let mut result_words: Vec<String> = w_nums
                .into_iter()
                .map(|x| {
                    let mut v = words_by_num
                        .get(&x)
                        .expect("code must be bugged, found no words with that number?")
                        .clone();
                    v.sort();
                    v.join("|")
                })
                .collect();
            result_words.sort();
            result_words.join(",")
        })
        .collect::<Vec<String>>();

    result_lines.sort();

    println!(
        "Done! Found {} cliques in {:.3} seconds.",
        results.len(),
        start_time.elapsed().as_secs_f32()
    );

    std::fs::write(&outputfile, result_lines.join("\n")).expect("Unable to write results to file");
    println!("Results were written to {}", &outputfile);
}
