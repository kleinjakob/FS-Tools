#!/bin/bash

foundfirsttexture=0
texturenumber=0

# Check arguments' validity.
if [[ ${#1} -lt 1 ]]; then
  echo "Argument Error! Usage `basename $0` <submodel asm file>"
  exit
fi

while read line; do
  # If alread in the first texture list,
  if [[ foundfirsttexture -eq 1 ]]; then
    # Check if end.
    if [[ $line = *TEXTURE_LIST_END* ]]; then
      foundfirsttexture=0
      exit
    fi
    
    # Read textures to stdout.
    texturename=$(echo "$line" | cut -d\" -f2)
    texturetype=$(echo "$line" | cut -d\  -f2)
    texturecolor=$(echo "$line" | cut -d\< -f2 | cut -d\> -f1)
    texturevalue=$(echo "$line" | cut -d\, -f6)
    echo -e "$texturenumber\t$texturename\t$texturetype\t$texturecolor\t$texturevalue"
    texturenumber=$(($texturenumber + 1))
  fi

  # Check if line is the first texture list begin.
  if [[ $line = *TEXTURE_LIST_BEGIN* ]]; then
    foundfirsttexture=1
  fi
done < "$1"
