#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904
set -e


SHOULD_CHECKOUT=1
echo "SHOULD_CHECKOUT=$SHOULD_CHECKOUT"

SCRIPT_DIRECTORY="$(dirname $0)"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"


####################
# Define Functions #
####################

# Usage: `runCarthageBuilds "MINIMUM_SUPPORTED_XCODE_VERSION" "Carthage-Minimum"`
runCarthageBuilds() {
	echo "------ BEGIN runCarthageBuilds ------"

	local XCODE_VERSION_FILE="$1"
	local NAME="$2"
	echo "XCODE_VERSION_FILE=$XCODE_VERSION_FILE"
	echo "NAME=$NAME"
	
	assignXcodeAppPathFor "$XCODE_VERSION_FILE"
	echo "XCODE_APP_PATH=$XCODE_APP_PATH"	
	
	local DESIRED_XCODE_SELECT="$XCODE_APP_PATH/Contents/Developer"
	local WORKING_DIRECTORY="$SCRIPT_DIRECTORY/$NAME"
	local WORKSPACE_FILEPATH="$WORKING_DIRECTORY/$NAME.xcworkspace"
	echo "DESIRED_XCODE_SELECT=$DESIRED_XCODE_SELECT"
	echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
	echo "WORKSPACE_FILEPATH=$WORKSPACE_FILEPATH"

	CURRENT_XCODE_SELECT=$( xcode-select -p )
	echo "CURRENT_XCODE_SELECT=$CURRENT_XCODE_SELECT"
	
	if [ "$CURRENT_XCODE_SELECT" != "$DESIRED_XCODE_SELECT" ]; then
		echo "***** Will perform xcode-select to '$DESIRED_XCODE_SELECT'"
		say "ex code selecting, your password may be required, please check"
		sudo xcode-select -s "$DESIRED_XCODE_SELECT"
	fi

	if [ "$SHOULD_CHECKOUT" -gt 0 ]; then
		sh "$WORKING_DIRECTORY/checkout.sh"
	fi

	xcodebuild -workspace "$WORKSPACE_FILEPATH" -scheme "Swift-iOS"
	xcodebuild -workspace "$WORKSPACE_FILEPATH" -scheme "Swift-macOS"
	xcodebuild -workspace "$WORKSPACE_FILEPATH" -scheme "ObjectiveC-iOS"
	xcodebuild -workspace "$WORKSPACE_FILEPATH" -scheme "ObjectiveC-macOS"
	
	echo "------ END runCarthageBuilds ------"
}

# Usage `assignXcodeAppPathFor FILENAME_CONTAINING_DESIRED_VERSION`
function assignXcodeAppPathFor { # outputs path to $XCODE_APP_PATH var
	
	local DESIRED_XCODE_VERSION_FILENAME="$1"
	echo "DESIRED_XCODE_VERSION_FILENAME=$DESIRED_XCODE_VERSION_FILENAME"
	
	local DESIRED_XCODE_VERSION_FILEPATH="$SCRIPT_DIRECTORY/$DESIRED_XCODE_VERSION_FILENAME"
	echo "DESIRED_XCODE_VERSION_FILEPATH=$DESIRED_XCODE_VERSION_FILEPATH"
	
	local DESIRED_XCODE_VERSION=$( head -n 1 "$DESIRED_XCODE_VERSION_FILEPATH" )
	echo "DESIRED_XCODE_VERSION=$DESIRED_XCODE_VERSION"
	
	echo "***** Attempting to identify Xcode (xcodebuild) with version '$DESIRED_XCODE_VERSION' *****"
	
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
				return 0 # Return with zero code to indicate success
			fi
		else
			echo "   xcodebuild missing ($XCODEBUILD_PATH)"
		fi
	done
	
	# If we got here the DESIRED_XCODE_VERSION was not found
	echo "ERROR: No Xcode (xcodebuild) found for version '$DESIRED_XCODE_VERSION' as defined in '$DESIRED_XCODE_VERSION_FILENAME'" >&2
	say "Failure. Unable to find ex code application for version $DESIRED_XCODE_VERSION"
	exit 1 # Exit with a non-zero code to indicate failure and kill the script

}


####################
# Carthage-Minimum #
####################

runCarthageBuilds "MINIMUM_SUPPORTED_XCODE_VERSION" "Carthage-Minimum"


###################
# Carthage-Latest #
###################

runCarthageBuilds "LATEST_SUPPORTED_XCODE_VERSION" "Carthage-Latest"




say "All targets built successfully"




