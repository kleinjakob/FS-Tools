#!/bin/bash
#   FS Tools
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
#   along with FS Tools.  If not, see <http://www.gnu.org/licenses/>.

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

