#!/bin/bash

texturesfile=$1
asmfile=$2
submodel_basename=$3

line="#State Tag (DEFAULT)"

while read textureline; do
	texturename=$(echo "$textureline" | cut -f2)
	line="${line}\tTexturename (Default: ${texturename})\tTexturetype"
done < "$texturesfile"

echo -e "${line}"

./defaultstatelist.pl "${submodel_basename}" < "$asmfile"
