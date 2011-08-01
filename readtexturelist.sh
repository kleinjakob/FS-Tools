#!/bin/bash
#   FS Tools 1.0
#   Copyright (C) 2009-2011 Jakob Klein, mail@kleinjakob.at
#
#   This file is part of FS Tools.
#
#   FS Tools is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   FS Tools is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

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
