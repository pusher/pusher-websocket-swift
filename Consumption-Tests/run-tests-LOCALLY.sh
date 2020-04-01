#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904
set -e


####################
# Define Variables #
####################

SHOULD_CHECKOUT=1
echo "SHOULD_CHECKOUT=$SHOULD_CHECKOUT"

SCRIPT_DIRECTORY="$(dirname $0)"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

SUMMARY_LOG_OUTPUT=""

####################
# Define Functions #
####################

# Usage: `runXcodeBuild "WORKSPACE" "SCHEME"`
runXcodeBuild() {
	
	local WORKSPACE_FILEPATH="$1"
	local SCHEME="$2"
	
	set +e
	xcodebuild -workspace "$WORKSPACE_FILEPATH" -scheme "$SCHEME"
	local XCODEBUILD_STATUS_CODE=$?
	set -e
	
	if (( XCODEBUILD_STATUS_CODE )); then
		# Build errored
		SUMMARY_LOG_OUTPUT+="\n ❌ $SCHEME"
		echo "$SUMMARY_LOG_OUTPUT"
		say "Build failed for scheme, $SCHEME"
		exit $XCODEBUILD_STATUS_CODE
	else
		# Built succeeded
		SUMMARY_LOG_OUTPUT+="\n ✅ $SCHEME"
	fi
}

# Usage: `runCarthageBuilds "MINIMUM_SUPPORTED_XCODE_VERSION" "Carthage-Minimum"`
performCarthageTests() {
	echo "------ BEGIN performCarthageTests ------"

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

	SUMMARY_LOG_OUTPUT+="\n\n+++++ $NAME +++++"

	runXcodeBuild "$WORKSPACE_FILEPATH" "Swift-iOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "Swift-macOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "ObjectiveC-iOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "ObjectiveC-macOS"
	
	echo "------ END performCarthageTests ------"
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

performCarthageTests "MINIMUM_SUPPORTED_XCODE_VERSION" "Carthage-Minimum"


###################
# Carthage-Latest #
###################

performCarthageTests "LATEST_SUPPORTED_XCODE_VERSION" "Carthage-Latest"


############
# Conclude #
############

echo "$SUMMARY_LOG_OUTPUT"
say "All targets built successfully"

