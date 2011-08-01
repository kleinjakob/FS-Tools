#!/bin/bash

# $1 First Input File
# $2 Second Input File

tmpfolder="/tmp/";

head -n 1 "$1" > "${tmpfolder}compf1.txt";
head -n 1 "$2" > "${tmpfolder}compf2.txt";

diff -q "${tmpfolder}compf1.txt" "${tmpfolder}compf2.txt";

rm "${tmpfolder}compf1.txt" "${tmpfolder}compf2.txt"
