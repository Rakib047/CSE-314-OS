#!/bin/bash

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

# Usage example:
submissions_dir="$1"
targets_dir="$2"
tests_dir="$3"
answers_dir="$4"

organize_code_files "$submissions_dir" "$targets_dir"