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

# Activate Die on Error
set -e

# $1 input folder
# $2 output folder
# $3 mother file
# $4 brightmaterials file

# Version String for GIT Tags (git tags are in format v1.005 while for
# presentation the version should be formated 1.5)
VERSION="1.2"

inputfolder="";
outputfolder="";
motherfile="";
brightmaterials="";
tmpfolder="/tmp/";

# Handle Default Options
# Version is printed without the default copyright notice!
if [[ "$1" == "--version" ]]; then
	echo "FS Tools ${VERSION}"
	cat <<-END
	Copyright (C) 2009-2011 Jakob Klein

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	END
	exit;
fi

# Print Default Copyright Notice
echo "FS Tools ${VERSION}"
cat <<-END
Copyright (C) 2009-2011 Jakob Klein
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

END

if [[ "$1" == "--licence" ]]; then
	cat gpl.txt;
	exit;
fi

if [[ "$1" == "--help" ]]; then
	cat <<-END
	Useage:
	  ./fstools.sh [Option] | [Arguments]
	
	Possible Options:
	  --version   Prints a short information about the version of this script.
	  --help      Prints this short text on invocation.
	  --licence   Prints the Licence under which this program is released (GPL3).
	
	Optional Arguments:
	  If you give arguments, you have to give all four, or none at all.
	  By giving the arguments you skip the interactive qestionaire about the
	  input and output folders, the mother input file and the bright materials
	  table.
	  
	  Argument 1:   absolute input folder name ending in a trailing slash (/)
	                e.g. "/path/to/input/folder/"
	  Argument 2:   absolute output folder name ending in a trailing slash (/)
	                e.g. "/path/to/output/folder/"
	  Argument 3:   name of the mother file in the input folder
	                e.g. "motherfile.asm"
	  Argument 4:   name of the bright materials table file in the input folder
	                e.g. "brightmaterials.csv"

	  Coming together as:
	    ./fstools.sh "/path/to/input/folder/" "/path/to/output/folder/"
	      "motherfile.asm" "brightmaterials.csv"
	
	For further information see the README included in the original package.
	
	END
	exit;
fi

if [[ ${#1} -gt 0 && ${#2} -gt 0 && ${#3} -gt 0 && ${#4} -gt 0 ]]; then
	inputfolder="$1";
	outputfolder="$2";
	motherfile="$3";
	brightmaterials="$4";
else
	echo -e "You are running this script in interactive mode!\n";
	
	echo "Please give the full path to the folder of the input files (terminating in /):";
	read inputfolder;
	echo "Please give the full path to the folder of the output files (terminating in /):";
	read outputfolder;
	echo "Please give the name of the 'mother' input file:";
	read motherfile;
	echo "Please give the name of the 'material definition' file:";
	read brightmaterials;
	echo -e "\n";
fi

## echo "${inputfolder}${motherfile}";

# Copy Motherfile into tmp folder and make includes relative.
perl -pe 's/\r\n/\n/' < "${inputfolder}${motherfile}" | perl -pe 's/include\s*.*[\\\/]([^\\\/]*\.asm)/include    $1/' > "${tmpfolder}${motherfile}"

# Make Submodel List.
perl -e 'my $type = undef; while (<>) { if (/LOD_.*L\s+label\s+BGLCODE/) { $type = "EXTERIOR" } if (/INSIDE_.*L\s+label\s+BGLCODE/) { $type = "INTERIOR" } if (/include\s*(.*\.asm)/) { print $type . "\t" . $1 . "\n"; } }' < "${tmpfolder}${motherfile}" > "${tmpfolder}submodels.txt"

# Get lightstate number.
lightstate_number=`perl -e 'while (<>) { if (/dict_(.*)_lightStates/) { print $1 . "\n"; exit 0; } } exit 1;' < "${tmpfolder}${motherfile}"`;

## echo $lightstate_number;

# Copy Submodel Files into tmp folder.
while IFS="" read line; do
	subfile=`echo "$line" | cut -f2`;
	perl -pe 's/\r\n/\n/' < "${inputfolder}${subfile}" > "${tmpfolder}${subfile}"
done < "${tmpfolder}submodels.txt"

# Ask if we should add the shadow call line to show shadow in interior too.
echo "Should we activate the external's shadow for the internal too (yN)?";
read answer;

answer=`echo "$answer" | perl -e '$answer = <>; if ($answer =~ /^[yYjJ1]/) { print 1; } else { print 0; }'`;
## echo $answer;

if [[ $answer -eq 1 ]]; then
	# VARIANT 1: Move the shadow call infront of the inside test. (Erroneous!)
	## sed -n '/IFMSK \+inside.*GEN_MODEL_OUTSIDE+GEN_MODEL_DISPLAY/{h;:a;n;/BGL_CALL \+shadow/{p;x;bb;};H;x;s/\([^\n]*\)\n\([^\n]*\)$/\2\n\1/;x;ba;};:b;p' < "${tmpfolder}${motherfile}" > "${tmpfolder}${motherfile}_mod"
	
	# VARIANT 2: Insert a Call to shadow model before call for internal model.
	perl -pe 's/^(inside3\s+label\s+BGLCODE\s*)/$1    BGL_CALL        shadow\n/;' < "${tmpfolder}${motherfile}" > "${tmpfolder}${motherfile}_mod"
		
	# Substitute original file with modified file.
	mv "${tmpfolder}${motherfile}_mod" "${tmpfolder}${motherfile}"
fi

# Check if there are multiple Models.
numextmodels=`grep "EXTERIOR" < "${tmpfolder}submodels.txt" | wc -l`;
numintmodels=`grep "INTERIOR" < "${tmpfolder}submodels.txt" | wc -l`;

# Ask if we should merge the external models if there are many.
if [[ $numextmodels -gt 1 ]]; then
	echo "There are more than one external models, do you want wo merge them (yN)?";
	read answer;
	
	answer=`echo "$answer" | perl -e '$answer = <>; if ($answer =~ /^[yYjJ1]/) { print 1; } else { print 0; }'`;
	## echo $answer;
	
	if [[ $answer -eq 1 ]]; then
		# Do the steps to merge the models.
		perl -pe 's/(^\s*IFSIZEV LOD_.+,\s*\d+\s*,\s*\d+\s*)/;$1/;
s/(^\s*IFSIZEV SHADOW_.+,\s*\d+\s*,\s*\d+\s*)/;$1/;
s/BGL_JUMP_32\s*LOD_/BGL_CALL_32    LOD_/;
s/^(model_inside\s*label\s*BGLCODE\s*)$/    BGL_RETURN\n$1/;
s/^(model_crash\s*label\s*BGLCODE\s*)$/    BGL_RETURN\n$1/;' < "${tmpfolder}${motherfile}" > "${tmpfolder}${motherfile}_mod"
		# TODO: Unchecked!  Better check for other methods of ending a LOD-sequence as well!
		
		# Substitute original file with modified file.
		mv "${tmpfolder}${motherfile}_mod" "${tmpfolder}${motherfile}"
	fi
fi

# Ask if we should merge the internal models if there are many.
if [[ $numintmodels -gt 1 ]]; then
	echo "There are more than one internal models, do you want wo merge them (Yn)?";
	read answer;
	
	answer=`echo "$answer" | perl -e '$answer = <>; if ($answer =~ /^[nN0]/) { print 0; } else { print 1; }'`;
	## echo $answer;
	
	if [[ $answer -eq 1 ]]; then
		# Do the steps to merge the internal models.
		perl -pe 's/(^\s*IFIN1 INSIDE_.+,\s*dict_.*cockpit_detail)/;$1/; 
s/BGL_JUMP_32\s*INSIDE_/BGL_CALL_32    INSIDE_/;
s/^(Landing_Lights\s*label\s*BGLCODE\s*)$/    BGL_RETURN\n$1/;' < "${tmpfolder}${motherfile}" > "${tmpfolder}${motherfile}_mod"
		
		# Substitute original file with modified file.
		mv "${tmpfolder}${motherfile}_mod" "${tmpfolder}${motherfile}"
	fi
fi

# TODO: Implement SuperScale Mod for INTERIOR and EXTERIOR

# Setup for work on each model file.
maxnumlines=`wc -l < "${tmpfolder}submodels.txt"`;
linenum="0";

## echo $maxnumlines;
	
# Work on each submodel file.
while [ $linenum -lt $maxnumlines ]; do
	#IFS="" read line;
	let linenum=$linenum+1;
	
	line=`sed -n ${linenum}p < "${tmpfolder}submodels.txt"`;
	
	modeltype=`echo "$line" | cut -f1`;
	subfile=`echo "$line" | cut -f2`;
	
	# Get submodel basename.
	submodel_basename=`perl -e 'while (<>) { if (/(.*)_top label BGLCODE/) { print $1 . "\n"; exit 0; } } exit 1;' < "${tmpfolder}${subfile}"`;
	
	echo -e "Working now on Model:\n$submodel_basename ($modeltype)\nFile:\n$subfile\n";
	
	# Add Light Code Strings.
	echo -e "Please give the light code string (any of 'nbltsprwo' in lower case) or leave empty for default light code:";
	read lightcode;
	
	# If there is a lightcode, indicating needed modification
	if [[ ${#lightcode} -gt 0 ]]; then
		echo -e "Using Light String '$lightcode'\n";
		
		# Make Texture List for File.
		./readtexturelist.sh "${tmpfolder}${subfile}" > "${tmpfolder}${subfile}_textures.txt"

		# Make Control Code Template.
		./controlcode.sh "$lightcode" "$lightstate_number" "${submodel_basename}_" "${tmpfolder}${subfile}_statelabellist.txt" > "${tmpfolder}${subfile}_controlcodetemplate.txt"
		
		# Make Texture Table Template.
		./createstatetemplate.sh "${tmpfolder}${subfile}_textures.txt" "${tmpfolder}${subfile}_statelabellist.txt" "$lightcode" > "${tmpfolder}${subfile}_statelabellist.csv"
		
		# Let user Edit Texture Table.
		if which oocalc &> /dev/null; then
			oocalc "${tmpfolder}${subfile}_statelabellist.csv"
		else
			echo -e "Open Office Calc or Libre Office Calc not found!\nPlease edit the file '${tmpfolder}${subfile}_statelabellist.csv' by hand before continuing.";
		fi
		echo -e "Waiting until editing of file '${tmpfolder}${subfile}_statelabellist.csv' is completed!\nPlease press enter when ready to continue...";
		read
		
		# Update controlcode from Texture Table.
		./updatefromtemplate.sh "${tmpfolder}${subfile}_statelabellist.csv" "${tmpfolder}${subfile}_textures.txt" "${tmpfolder}${subfile}_controlcodetemplate.txt" > "${tmpfolder}${subfile}_controlcode.txt"
		
		# Insert Updated Control Code into Model.
		sed -n "/BGL_BEGIN 0800h/r ${tmpfolder}${subfile}_controlcode.txt
//{:a;n;/_lights_done label word/{bb;};ba;};:b;p;" < "${tmpfolder}${subfile}" > "${tmpfolder}${subfile}_mod"
		
		# Substitute original file with modified file.
		mv "${tmpfolder}${subfile}_mod" "${tmpfolder}${subfile}"
	else
		echo -e "Using Default Light System\n";

		# Make Texture List for File.
		./readtexturelist.sh "${tmpfolder}${subfile}" > "${tmpfolder}${subfile}_textures.txt"
		
		# Create Texture Table.
		./createdefaultstatelist.sh "${tmpfolder}${subfile}_textures.txt" "${tmpfolder}${subfile}" "${submodel_basename}" > "${tmpfolder}${subfile}_statelabellist.csv"
		
		# Let user Edit Texture Table.
		if which oocalc &> /dev/null; then
			oocalc "${tmpfolder}${subfile}_statelabellist.csv"
		else
			echo -e "Open Office Calc or Libre Office Calc not found!\nPlease edit the file '${tmpfolder}${subfile}_statelabellist.csv' by hand before continuing.";
		fi
		echo -e "Waiting until editing of file '${tmpfolder}${subfile}_statelabellist.csv' is completed!\nPlease press enter when ready to continue...";
		read
		
		# Update controlcode from Texture Table.
		./updatefromdefaultlist.pl "${tmpfolder}${subfile}_statelabellist.csv" "${tmpfolder}${subfile}" > "${tmpfolder}${subfile}_mod"
		
		# Substitute original file with modified file.
		mv "${tmpfolder}${subfile}_mod" "${tmpfolder}${subfile}"
	fi
	
	# Material Edits.
	if [[ ${#brightmaterials} -gt 0 ]]; then
		# Do modifications.
		./brightmaterialedits.pl "${inputfolder}${brightmaterials}" "${tmpfolder}${subfile}" > "${tmpfolder}${subfile}_mod"
		
		# Substitute original file with modified file.
		mv "${tmpfolder}${subfile}_mod" "${tmpfolder}${subfile}"
	fi
done

echo "Modifications are complete!";

# Copy Files into output folder.
while IFS="" read line; do
	subfile=`echo "$line" | cut -f2`;
	perl -pe 's/\n/\r\n/' < "${tmpfolder}${subfile}" > "${outputfolder}${subfile}"
	if [[ -f "${tmpfolder}${subfile}_statelabellist.csv" ]]; then
		cp "${tmpfolder}${subfile}_statelabellist.csv" "${outputfolder}";
	fi
done < "${tmpfolder}submodels.txt"

perl -pe 's/\n/\r\n/' < "${tmpfolder}${motherfile}" > "${outputfolder}${motherfile}"

# Test if wine is installed or we are under Windows (Cygwin) anyways.
if which wine &> /dev/null || [[ `uname` == CYGWIN* ]]; then
	# Test if BGLC_9.exe is in current folder.
	if [[ -f BGLC_9.exe ]] ; then
		# Ask if we should compile.
		echo "Should we start compilation for you now (Yn)?";
		read answer;

		answer=`echo "$answer" | perl -e '$answer = <>; if ($answer =~ /^[nN0]/) { print 0; } else { print 1; }'`;
		## echo $answer;

		if [[ $answer -eq 1 ]]; then
			startdir=`pwd`;

			# Copy BGLC_9.exe into output dir as it has problems with absolute and non-zero-depth-realtive paths under linux!
			cp BGLC_9.exe "${outputfolder}";
	
			cd "${outputfolder}";
			chmod a+x BGLC_9.exe;
	
			# Start compilation with MDL switch depending if Linux or Cygwin
			if which wine &> /dev/null; then
				wine BGLC_9.exe "/MDL" "${motherfile}"
			else
				./BGLC_9.exe "/MDL" "${motherfile}"
			fi
	
			rm BGLC_9.exe;
	
			cd "${startdir}";
		fi
	fi
fi
