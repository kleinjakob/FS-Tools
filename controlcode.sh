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

debug=0
addshortcut=1
lightstatenum=$2
statelabels=""
extralabels=""

function process_string {
	# $1 ... used light string
	# $4 ... submodel_basename
	# $2 ... inheritedI
	# $3 ... inheritedO

	
	# If debug flag is set, print remaining string comment.
	if [[ $debug -eq 1 ]]; then
		echo "    ;Remaining String (${#1}): $1"
	fi
	
	# Echo the label of the current test.
	echo "${2}state_I${3}_O${4}_label label word"
	
	#for (( i=0; i < ${#1}; i++ ))
	#do
	#	echo ${1:$i:1}
	#done
	
	# Select the appropriate Light Mask depending on next light in queue.
	case ${1:0:1} in
		n)
			name="LIGHT_NAV_MASK"
			;;
		b)
			name="LIGHT_BEACON_MASK"
			;;
		l)
			name="LIGHT_LANDING_MASK"
			;;
		t)
			name="LIGHT_TAXI_MASK"
			;;
		s)
			name="LIGHT_STROBE_MASK"
			;;
		p)
			name="LIGHT_PANEL_MASK"
			;;
		r)
			name="LIGHT_RECOGNITION_MASK"
			;;
		w)
			name="LIGHT_WING_MASK"
			;;
		o)
			name="LIGHT_LOGO_MASK"
			;;
		*)
			echo "ERROR: Unknown Letter '${1:0:1}' in Light String!" >&2
			exit 1;
			;;
	esac
	
	# Write the test if the current first light in the list is switched OFF (!)
	echo "    IFMSK ${2}state_I${3}_O${4}${1:0:1}_longjump_label, dict_${lightstatenum}_lightStates, $name"
	echo "    BGL_JUMP_32 ${2}state_I${3}${1:0:1}_O${4}_label"
	echo "${2}state_I${3}_O${4}${1:0:1}_longjump_label label word"
	echo "    BGL_JUMP_32 ${2}state_I${3}_O${4}${1:0:1}_label"
	
	if [[ ${#1} -gt 1 ]]
	then
		# Recursively work on substrings.
		process_string "${1:1:${#1}-1}" "$2" "${3}" "${4}${1:0:1}"
		process_string "${1:1:${#1}-1}" "$2" "${3}${1:0:1}" "${4}"
	else
		# Output to label list for end.
		statelabels="${statelabels}${2}state_I${3}_O${4}${1:0:1}_label label word\n"
		statelabels="${statelabels};#insert# ${2}state_I${3}_O${4}${1:0:1}_label\n"
		statelabels="${statelabels}    BGL_JUMP_32 ${2}state_end_label\n"
		statelabels="${statelabels}${2}state_I${3}${1:0:1}_O${4}_label label word\n"
		statelabels="${statelabels};#insert# ${2}state_I${3}${1:0:1}_O${4}_label\n"
		statelabels="${statelabels}    BGL_JUMP_32 ${2}state_end_label\n"
		
		# Output for extra label dump if selected.
		extralabels="${extralabels}${2}state_I${3}_O${4}${1:0:1}_label\n"
		extralabels="${extralabels}${2}state_I${3}${1:0:1}_O${4}_label\n"
	fi
}

# Check argument length of light string.
if [[ ${#1} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <used light string in lower case! (e.g. lpo )> <dict_lightState number> <submodel_basename> [<Dump States extra if filename is set>]"
	exit 1;
fi

# Check argument length of light state number.
if [[ ${#2} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <used light string in lower case! (e.g. lpo )> <dict_lightState number> <submodel_basename> [<Dump States extra if filename is set>]"
	exit 1;
fi

# Check argument length of submodel_basename.
if [[ ${#3} -lt 1 ]]; then
	echo "Argument Error! Usage `basename $0` <used light string in lower case! (e.g. lpo )> <dict_lightState number> <submodel_basename> [<Dump States extra if filename is set>]"
	exit 1;
fi

# Print a comment where the insert should start.
echo "; Code Modified by Jakob Klein's Model Toolset Starts here"
# echo "; START OF MOD SUBSTITUTE at BGL_BEGIN 0800h ; version = 8.00"
echo "    BGL_BEGIN 0800h ; version = 8.00"

# Print a Light-Off Shortcut test is selected.
if [[ $addshortcut -eq 1 ]]; then
	echo "    IFMSK ${3}state_I_O${1}_label, dict_${lightstatenum}_lightStates, -1"
fi

# Process the string recursively (This is the "Mother Call").
process_string $1 $3

# If extra dump of state labels is selected, write them to the filename given.
if [[ ${#4} -gt 1 ]]; then
	echo -e "${extralabels}" > $4
fi

# Write statelabels and final labels and comments
echo -e "${statelabels}"
echo "${3}state_end_label label word"
echo "; Code Modified by Jakob Klein's Model Toolset ends here"
# echo "; END OF MOD INSERT before ..._lights_done label word"

