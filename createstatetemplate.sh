#!/bin/bash

texturesfile=$1
statefile=$2
lightcode=$3

if [[ ${#3} -gt 0 ]]; then
	line="#State Tag ($lightcode)"
else
	line="#State Tag"
fi

while read textureline; do
	texturename=$(echo "$textureline" | cut -f2)
	line="${line}\tTexturename (Default: ${texturename})\tTexturetype"
done < "$texturesfile"

echo -e "${line}"


while read stateline; do
	if [[ ${#stateline} -gt 0 ]]; then
		line="${stateline}"
	
		while read textureline; do
			texturename=$(echo "$textureline" | cut -f2)
			texturetype=$(echo "$textureline" | cut -f3)
			line="${line}\t${texturename}\t${texturetype}"
		done < "$texturesfile"
	
		echo -e "${line}"
	fi
done < "$statefile"

