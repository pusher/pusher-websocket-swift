#! /bin/sh

set -e # Ensure Script Exits immediately if any command exits with a non-zero status

# calling this function will ultimately set the following variables 
#	SWIFT_VERSION
#	IPHONEOS_DEPLOYMENT_TARGET
#	MACOSX_DEPLOYMENT_TARGET
#	TVOS_DEPLOYMENT_TARGET
#
# by reading them  from the appropriate xcconfig file, either 
#	MINIMUM_SUPPORTED_VERSIONS.xconfig
#	LATEST_SUPPORTED_VERSIONS.xconfig
#
# depending on the WORKING_DIRECTORY arg passed


# Usage: `getXcconfigValueFor WORKING_DIRECTORY`
function readAllXcconfigVersionValuesFor {
	
	echo "------ BEGIN: $FUNCNAME $@ ------"

	local WORKING_DIRECTORY="$1"
	echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
	
	# Remove trailing slashs
	local WORKING_DIRECTORY_TRIMMED=$(echo $WORKING_DIRECTORY | sed 's:/*$::')
	echo "WORKING_DIRECTORY_TRIMMED=$WORKING_DIRECTORY_TRIMMED"
	
	if [[ "$WORKING_DIRECTORY_TRIMMED" == *"-Latest" ]]; then
		XCCONFIG_FILENAME="LATEST_SUPPORTED_VERSIONS.xcconfig"
	elif [[ "$WORKING_DIRECTORY_TRIMMED" == *"-Minimum" ]]; then
		XCCONFIG_FILENAME="MINIMUM_SUPPORTED_VERSIONS.xcconfig"
	else
		echo "ERROR: Unable to determine version requirements because the working directory does not end with either '-Latest' or '-Minimum'." >&2
		echo "------ END: $FUNCNAME $@ ------"	
		say "Failure. Unable to determine version requirements"
		exit 1
	fi
	
	local XCCONFIG_FILEPATH="$WORKING_DIRECTORY/../$XCCONFIG_FILENAME"
	echo "XCCONFIG_FILEPATH=$XCCONFIG_FILEPATH"
	
	while read -r LINE || [ -n "$LINE" ]; do 
		LINE_TRIMMED="${LINE/ = /=}"  
		echo $LINE_TRIMMED  
		if [[ "$LINE_TRIMMED" == "//"* ]]; then
			echo "   ...looks like a comment ignoring"
		else 
			echo "   ... setting varaiable"
			eval "$LINE_TRIMMED"
		fi
	done < "$XCCONFIG_FILEPATH"
	
	echo "SWIFT_VERSION=$SWIFT_VERSION"
	echo "IPHONEOS_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET"
	echo "MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET"
	echo "TVOS_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET"

	echo "------ END: $FUNCNAME $@ ------"
}
