#!/bin/bash
rm -f mycode.out
echo 'Generating the object files'
g++  mycode.cpp -o mycode.out
echo 'All ready, running...'
./mycode.out