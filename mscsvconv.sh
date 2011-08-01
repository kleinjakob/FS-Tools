#!/bin/bash

# Substitute ; to /t in file $1.

touch $1_new

while read line; do
	echo $line | sed -e "y/;/\t/" >> $1_new
done < $1

rm $1
mv $1_new $1
