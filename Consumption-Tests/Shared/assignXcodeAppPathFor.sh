#! /bin/sh

# Usage `assignXcodeAppPathFor XCODE_VERSION`
function assignXcodeAppPathFor { # outputs path to $XCODE_APP_PATH var
	
	echo "------ BEGIN: $FUNCNAME $@ ------"
	
	local SCRIPT_DIRECTORY="$(dirname $0)"
	echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

	local DESIRED_XCODE_VERSION="$1"
	echo "DESIRED_XCODE_VERSION=$DESIRED_XCODE_VERSION"
	
	echo "*** Attempting to identify Xcode (xcodebuild) with version '$DESIRED_XCODE_VERSION' ***"
	
	for CANDIDATE_XCODE_APP_PATH in /Applications/*Xcode*.app/; do 
		echo $CANDIDATE_XCODE_APP_PATH;
		local CANDIDATE_XCODEBUILD_PATH="${CANDIDATE_XCODE_APP_PATH}Contents/Developer/usr/bin/xcodebuild"
		if [ -e "$CANDIDATE_XCODEBUILD_PATH" ]; then
			echo "   xcodebuild exists ($CANDIDATE_XCODEBUILD_PATH)"
			local XCODE_VERSION=$( "$CANDIDATE_XCODEBUILD_PATH" -version | head -n 1 )
			echo "   VERSION: $XCODE_VERSION"
			
			if [ "$XCODE_VERSION" == "$DESIRED_XCODE_VERSION" ]; then
				echo "***** FOUND '$DESIRED_XCODE_VERSION' at $CANDIDATE_XCODE_APP_PATH *****"
				XCODE_APP_PATH="$CANDIDATE_XCODE_APP_PATH"
				echo "------ END: $FUNCNAME $@ ------"
				return 0 # Return with zero code to indicate success
			fi
		else
			echo "   xcodebuild missing ($XCODEBUILD_PATH)"
		fi
	done
	
	# If we got here the DESIRED_XCODE_VERSION was not found
	echo "ERROR: No Xcode (xcodebuild) found for version '$DESIRED_XCODE_VERSION' as defined in '$DESIRED_XCODE_VERSION_FILENAME'" >&2
	echo "------ END: $FUNCNAME $@ ------"
	say "Failure. Unable to find ex code application for version $DESIRED_XCODE_VERSION"
	exit 1 # Exit with a non-zero code to indicate failure and kill the script
}