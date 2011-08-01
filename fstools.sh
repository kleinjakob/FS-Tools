#!/bin/bash

# $1 input folder
# $2 output folder
# $3 mother file

inputfolder="";
outputfolder="";
motherfile="";
brightmaterials="";
tmpfolder="/tmp/";

if [[ ${#1} -gt 0 && ${#2} -gt 0 && ${#3} -gt 0 && ${#4} -gt 0 ]]; then
	inputfolder="$1";
	outputfolder="$2";
	motherfile="$3";
	brightmaterials="$4";
else
	echo -e "Hello!\n\nYou are running this script in interactive mode!\n";
	
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
		
		# TODO: Implement External Model Merge.
		
		echo "WARNING!  External Model Merge is not yet implemented."
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
		oocalc "${tmpfolder}${subfile}_statelabellist.csv"
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
		oocalc "${tmpfolder}${subfile}_statelabellist.csv"
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
	
	# Start compilation with MDL switch
	wine BGLC_9.exe "/MDL" "${motherfile}"
	
	rm BGLC_9.exe;
	
	cd "${startdir}";
fi

