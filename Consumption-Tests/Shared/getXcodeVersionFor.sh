#! /bin/sh

set -e # Ensure Script Exits immediately if any command exits with a non-zero status

function getXcodeVersionFor { # outputs value to $XCODE_VERSION var
	
	echo "------ BEGIN: $FUNCNAME $@ ------"

	local WORKING_DIRECTORY="$1"
	echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
	
	# Remove trailing slashs
	local WORKING_DIRECTORY_TRIMMED=$(echo $WORKING_DIRECTORY | sed 's:/*$::')
	echo "WORKING_DIRECTORY_TRIMMED=$WORKING_DIRECTORY_TRIMMED"
	
	if [[ "$WORKING_DIRECTORY_TRIMMED" == *"-Latest" ]]; then
		XCODE_VERSION_FILENAME="LATEST_SUPPORTED_XCODE_VERSION"
	elif [[ "$WORKING_DIRECTORY_TRIMMED" == *"-Minimum" ]]; then
		XCODE_VERSION_FILENAME="MINIMUM_SUPPORTED_XCODE_VERSION"
	else
		echo "ERROR: Unable to determine Xcode version requirements because the working directory does not end with either '-Latest' or '-Minimum'." >&2
		echo "------ END: $FUNCNAME $@ ------"	
		say "Failure. Unable to determine Xcode version"
		exit 1
	fi
	
	local XCODE_VERSION_FILEPATH="$WORKING_DIRECTORY/../$XCODE_VERSION_FILENAME"
	echo "XCODE_VERSION_FILEPATH=$XCODE_VERSION_FILEPATH"
	
	XCODE_VERSION=$( head -n 1 "$XCODE_VERSION_FILEPATH" )
	echo "XCODE_VERSION=$XCODE_VERSION"
	
	echo "------ END: $FUNCNAME $@ ------"
}
