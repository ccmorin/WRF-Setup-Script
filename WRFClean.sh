#!/bin/bash
. variables
print_help() {
	echo "This script cleans WRF and WPS installations and (optionally) backs up their namelist files."
	echo "This script does NOT require sudo and should not be run as sudo, root, etc."
	echo "Usage: ./WRFClean.sh [([wrf] [wps] [-a]|-h|--help)] (in any order, case insensitive)"
	echo "wrf -> clean WRF"
	echo "wps -> clean WPS"
	echo "-a -> appends -a to the clean calls"
	echo "-h -> display this help text"
	echo "--help -> -h"
	echo "If 'wrf' or 'wps' is provided, it will only clean the ones that are provided"
	echo "\t(so, './WRFClean.sh' is equivalent to './WRFClean.sh wrf wps')"
}

#In order to run the WRF and WPS clean scripts as the user that called this script
#(so that the files can be edited without sudo) when this script is called, we have to use sudo to
#specifically switch back to that user for the duration of the command.
#If we aren't running as sudo, then we don't need this command, so it is set to ""
unsudo=""
if ( $SUDO_USER ); then
	unsudo="sudo -u $SUDO_USER"
	echo "This script should NOT be run as sudo."
	echo "Therefore, each command will call $unsudo first"
fi


clean_wrf=false
clean_wps=false
use_a=false

for var in "$@"
do
	var=$(echo "$var" | tr '[:upper:]' '[:lower:]')
	if [ "$var" == "-a" ]; then
		use_a=true
	elif [ "$var" == "wrf" ]; then
		clean_wrf=true
	elif [ "$var" == "wps" ]; then
		clean_wps=true
	else
		print_help
		kill -INT $$
	fi
done
text="wrf and wps installations"
if ( $clean_wrf ); then
	text="wrf"
	if ( $clean_wps ); then
		text=$text" and wps installations"
	else
		text=$text" installation"
	fi
elif ( $clean_wps ); then
	text="wps installation"
else
	clean_wrf=true
	clean_wps=true
fi
if ( $use_a ); then
	text=$text" with ./clean -a"
else
	text=$text"with ./clean"
fi

read -p "This script will clean your $text.  Press [Enter] to continue, [q] to quit. " cont
cont=$(echo "$cont" | tr '[:upper:]' '[:lower:]')
if [ "$cont" == "q" ]; then
	kill -INT $$
fi

if ( ! $keep_namelists ); then
	read -p "keep_namelists in 'variables' is currently set to false. If you proceed, you will loose any existing namelist files. Is this okay? [y/N] " yn
	yn=$(echo "$yn" | tr '[:upper:]' '[:lower:]')
	if [ "$yn" != "y" ]; then
		keep_namelists=true
		echo "Changed keep_namelists to true for this run. Please change the value in 'variables' if you wish to avoid this prompt."
	else
		read -p "Leaving keep_namelists false. Some existing namelists may be deleted. Press [Enter] to continue."
	fi
fi

set -e
set -o nounset

if ( $clean_wrf ); then
	cd $WRF_path
	if ( $keep_namelists ) && [ -e "./run/namelist.input" ]; then
		$unsudo cp "./run/namelist.input" "$backup_dir/namelist.input.back"
	fi
	if ( $use_a ); then
		$unsudo ./clean -a
	else
		$unsudo ./clean
	fi
	cd ../
fi

if ( $clean_wps ); then
	cd $WPS_path
	if [ $keep_namelists -a -e "./namelist.wps" ]; then
		$unsudo cp "./namelist.wps" "$backup_dir/namelist.wps.back"
	fi
	if ( $use_a ); then
		$unsudo ./clean -a
	else
		$unsudo ./clean
	fi
	cd ../
fi
