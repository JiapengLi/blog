#!/bin/bash

#./replace.sh "https://img.risinghf.com" "https://img.juzuq.com"

old=$1
new=$2

for file in ./*.md; do
	# -b to keep file line ending, or it will force use LF
	cat "$file" | sed -b "s,$old,$new,g" > tmp
	mv tmp "$file"
done
