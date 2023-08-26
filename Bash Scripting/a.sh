#!/bin/bash

verbose=false
execute=true

if [[ $# -lt 4 ]]; then
  echo "Insufficient arguments. Usage: $0 <submission_folder> <target_folder> <test_folder> <answer_folder>"
  exit 1
fi


# Check if the fifth argument exists
if [ $# -ge 5 ]; then
    if [ $5 == -v ]
    then
        verbose=true
    fi

    if [ $# -ge 6 ] && [ "$6" == "-noexecute" ]; then
        execute=false
    fi
fi


organize_code_files() {
    local submissions_dir="$1"
    local targets_dir="$2"

    mkdir -p "$targets_dir/C"
    mkdir -p "$targets_dir/Java"
    mkdir -p "$targets_dir/Python"

    for zipfile in "$submissions_dir"/*.zip; do
        mainFile=$(basename "$zipfile")
        studentID="${mainFile##*_}"
        studentID="${studentID%%.*}"

        if $verbose; then
            echo "organizing code for $studentID"
        fi

        unzip -j "$zipfile" *.{c,java,py} -d temp >/dev/null 2>&1

        if [ -f temp/*.c ]; then
            mkdir -p "$targets_dir/C/$studentID"
            cp temp/*.c "$targets_dir/C/$studentID/main.c"
        elif [ -f temp/*.java ]; then
            mkdir -p "$targets_dir/Java/$studentID"
            cp temp/*.java "$targets_dir/Java/$studentID/main.java"
        elif [ -f temp/*.py ]; then
            mkdir -p "$targets_dir/Python/$studentID"
            cp temp/*.py "$targets_dir/Python/$studentID/main.py"
        fi

        rm -rf temp
    done
}

compile_and_test() {
    local targets_dir="$1"
    local tests_dir="$2"
    local answers_dir="$3"
    local results_file="$4"

    echo "student_id,type,matched,not_matched" > "$results_file"

    for lang in C Java Python; do
        for student_dir in "$targets_dir/$lang"/*; do
            studentID=$(basename "$student_dir")

            if $verbose; then
            echo "executing code for $studentID"
            fi

            if [ "$lang" = "C" ]; then
                gcc "$student_dir/main.c" -o "$student_dir/main.out" >/dev/null 2>&1
                binary="$student_dir/main.out"
            elif [ "$lang" = "Java" ]; then
                javac -d "$student_dir" "$student_dir/main.java" >/dev/null 2>&1
                binary="java -cp $student_dir Main"
            elif [ "$lang" = "Python" ]; then
                binary="python3 $student_dir/main.py"
            fi

            matchCount=0
            notMatchCount=0
            totalTest=$(ls -1q "$tests_dir"/*.txt | wc -l)

            for ((i=1; i<=totalTest; i++)); do
                testfile="$tests_dir/test$i.txt"
                outfilename="out$i.txt"

                $binary < "$testfile" > "$student_dir/$outfilename" 2>/dev/null

                answerfile="$answers_dir/ans$i.txt"

                if diff -q "$student_dir/$outfilename" "$answerfile" >/dev/null 2>&1; then
                    ((matchCount++))
                else
                    ((notMatchCount++))
                fi
            done

            echo "$studentID,$lang,$matchCount,$notMatchCount" >> "$results_file"
        done
    done
}

# Usage example:
submissions_dir="$1"
targets_dir="$2"
tests_dir="$3"
answers_dir="$4"

organize_code_files "$submissions_dir" "$targets_dir"
results_file="$targets_dir/result.csv"

if $execute; then
    compile_and_test "$targets_dir" "$tests_dir" "$answers_dir" "$results_file"
fi