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

# Example usage: ./updatefromtemplate.sh FA_RJ100_WV_statetable_r001.csv FA_RJ100_WV_textures.txt FA_RJ100_WV_control.txt > FA_RJ100_WV_control_new.txt

# Input $1 lightstates csv, $2 texturelist txt, $3 control asm, output to stdout.

# Check arguments' validity.
if [[ ${#1} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <lightstates csv file> <testurelist txt file> <control asm file>"
	exit
fi

if [[ ${#2} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <lightstates csv file> <testurelist txt file> <control asm file>"
	exit
fi

if [[ ${#3} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <lightstates csv file> <testurelist txt file> <control asm file>"
	exit
fi

# Work on each line of control asm file.
while IFS="" read controlline; do

	if [[ "${controlline:0:9}" = ";#insert#" ]]; then
	
		substitutionname=$(echo "$controlline" | cut -d\  -f2)

		# Work on each line of the lightstates csv file to see if the line matches the the requested substitution.
		while read statesline; do
			# If Stateline starts with Quoted Fields: unquote.
			if [[ "${statesline:0:1}" = "\"" ]]; then
				# Remove Quotes from fields if any.
				statesline=`echo "$statesline" | perl -pe 's/^\"//g; s/\"$//g; s/\"\t/\t/g; s/\t\"/\t/g;'`;
			fi
			
			case ${statesline:0:1} in
				\#)
					# Do nothing (comment)
					;;
				*)
					statename=$(echo "$statesline" | cut -f1)
					if [[ $statename = $substitutionname ]]; then
						listelements=$(echo "$statesline" | cut -f2- | sed -e "y/\t/\ /")
			
						istexturename=1
						texturename=""
						texturenum=0

						texturelist="    TEXTURE_LIST_BEGIN\n"

						for item in $listelements; do
							if [[ $istexturename -eq 1 ]]; then
								istexturename=0

								# Sets and translates lowercase name of texture to upper.
								texturename=$(echo $item | tr "[:lower:]" "[:upper:]")
					
								if [[ ${#texturename} -gt 63 ]]; then
									echo "ERROR! ${texturename} too long (${#texturename} of max 63 characters)."
									exit
								fi
					
							else
								istexturename=1
					
								nexttexturenum=$(($texturenum + 1))
					
								texturelist="${texturelist}    TEXTURE_DEF  ${item}, <`sed -n ${nexttexturenum}p $2 | cut -f4`>, `sed -n ${nexttexturenum}p $2 | cut -f5`, \"${texturename}\" ; ${texturenum}\n"
					
								texturenum=$nexttexturenum
							fi
						done
			
						texturelist="${texturelist}    TEXTURE_LIST_END"
			
						echo -e "$texturelist"
					fi
					;;
			esac
		# Done with Lightstates csv file.
		done < $1
	
	else
		echo -e "$controlline"
	fi
# Done with control asm file.
done < $3

