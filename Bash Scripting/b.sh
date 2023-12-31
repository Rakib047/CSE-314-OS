#!/bin/bash

compile_and_test() {
    local targets_dir="$1"
    local tests_dir="$2"
    local answers_dir="$3"
    local results_file="$4"

    echo "student_id,type,matched,not_matched" > "$results_file"

    for lang in C Java Python; do
        for student_dir in "$targets_dir/$lang"/*; do
            studentID=$(basename "$student_dir")

            if [ "$lang" = "C" ]; then
                gcc "$student_dir/main.c" -o "$student_dir/main.out" >/dev/null 2>&1
                binary="$student_dir/main.out"
            elif [ "$lang" = "Java" ]; then
                javac -d "$student_dir" "$student_dir/main.java" >/dev/null 2>&1
                binary="java -cp $student_dir Main"
            elif [ "$lang" = "Python" ]; then
                binary="python3 $student_dir/main.py"
            fi

            match_count=0
            not_match_count=0
            total_tests=$(ls -1q "$tests_dir"/*.txt | wc -l)

            for ((i=1; i<=total_tests; i++)); do
                testfile="$tests_dir/test$i.txt"
                outfilename="out$i.txt"

                $binary < "$testfile" > "$student_dir/$outfilename" 2>/dev/null

                answerfile="$answers_dir/ans$i.txt"

                if diff -q "$student_dir/$outfilename" "$answerfile" >/dev/null 2>&1; then
                    ((match_count++))
                else
                    ((not_match_count++))
                fi
            done

            echo "$studentID,$lang,$match_count,$not_match_count" >> "$results_file"
        done
    done
}

# Usage example:
submissions_dir="$1"
targets_dir="$2"
tests_dir="$3"
answers_dir="$4"

results_file="$targets_dir/result.csv"
compile_and_test "$targets_dir" "$tests_dir" "$answers_dir" "$results_file"
