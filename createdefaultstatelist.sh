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
#   along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

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
