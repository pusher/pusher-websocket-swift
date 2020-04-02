#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904
set -e


####################
# Define Variables #
####################

SCRIPT_DIRECTORY="$(dirname $0)"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

SUMMARY_LOG_OUTPUT=""


####################
# Import Functions #
####################

source "$SCRIPT_DIRECTORY/Shared/assignXcodeAppPathFor.sh"
source "$SCRIPT_DIRECTORY/Shared/getXcodeVersionFor.sh"


#####################
# Extract Arguments #
#####################

SHOULD_CARTHAGE_CHECKOUT=1
SHOULD_COCOAPODS_CHECKOUT=1
SHOULD_SKIP_CARTHAGE=0
SHOULD_SKIP_COCOAPODS=0

while test $# -gt 0; do
	case "$1" in
		-skip-carthage)
			SHOULD_SKIP_CARTHAGE=1
			shift
			;;
		-skip-cocoapods)
			SHOULD_SKIP_COCOAPODS=1
			shift
			;;
		-skip-carthage-checkouts)
			SHOULD_CARTHAGE_CHECKOUT=0
			shift
			;;
		-skip-cocoapods-checkouts)
			SHOULD_COCOAPODS_CHECKOUT=0
			shift
			;;
		*)
			echo "$1 is not a recognized flag!"
			echo "Possible options are:"
			echo "   -skip-carthage"
			echo "   -skip-cocoapods"
			echo "   -skip-carthage-checkouts"
			echo "   -skip-cocoapods-checkouts"
			exit 1;
			;;
	esac
done  

echo "SHOULD_CARTHAGE_CHECKOUT=$SHOULD_CARTHAGE_CHECKOUT"
echo "SHOULD_COCOAPODS_CHECKOUT=$SHOULD_COCOAPODS_CHECKOUT"
echo "SHOULD_SKIP_CARTHAGE=$SHOULD_SKIP_CARTHAGE"
echo "SHOULD_SKIP_COCOAPODS=$SHOULD_SKIP_COCOAPODS"


####################
# Define Functions #
####################

# Usage: `runXcodeBuild "WORKSPACE_FILEPATH" "SCHEME"`
function runXcodeBuild {
	
	local WORKSPACE_FILEPATH="$1"
	local SCHEME="$2"
	
	set +e
	xcodebuild clean build -workspace "$WORKSPACE_FILEPATH" -scheme "$SCHEME" -allowProvisioningUpdates
	local XCODEBUILD_STATUS_CODE=$?
	set -e
	
	if (( XCODEBUILD_STATUS_CODE )); then
		# Build errored
		SUMMARY_LOG_OUTPUT+="\n 🔴 $SCHEME"
		echo "$SUMMARY_LOG_OUTPUT"
		say "Build failed for scheme, $SCHEME"
		exit $XCODEBUILD_STATUS_CODE
	else
		# Built succeeded
		SUMMARY_LOG_OUTPUT+="\n 🟢 $SCHEME"
	fi
}

# Usage: `performTests "Carthage-Minimum"`
function performTests {
	echo "------ BEGIN: $FUNCNAME $@ ------"

	local NAME="$1"
	echo "NAME=$NAME"
	
	SUMMARY_LOG_OUTPUT+="\n\n+++++ $NAME +++++"
	
	if ( [[ "$NAME" == "Carthage-"* ]] && (( $SHOULD_SKIP_CARTHAGE )) ) || \
	   ( [[ "$NAME" == "Cocoapods-"* ]] && (( $SHOULD_SKIP_COCOAPODS )) )
	then 
		echo "**** SKIPPING '$NAME' ****"	
		echo "------ END: $FUNCNAME $@ ------"
		SUMMARY_LOG_OUTPUT+="\n 🟡 SKIPPING"
		return 0
	fi

	local WORKING_DIRECTORY="$SCRIPT_DIRECTORY/$NAME"
	echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
	
	getXcodeVersionFor "$NAME" # should set XCODE_VERSION
	echo "XCODE_VERSION=$XCODE_VERSION"
	
	assignXcodeAppPathFor "$XCODE_VERSION" # should set XCODE_APP_PATH
	echo "XCODE_APP_PATH=$XCODE_APP_PATH"	
	
	local DESIRED_XCODE_SELECT="$XCODE_APP_PATH/Contents/Developer"
	local WORKSPACE_FILEPATH="$WORKING_DIRECTORY/$NAME.xcworkspace"
	echo "DESIRED_XCODE_SELECT=$DESIRED_XCODE_SELECT"
	echo "WORKSPACE_FILEPATH=$WORKSPACE_FILEPATH"

	CURRENT_XCODE_SELECT=$( xcode-select -p )
	echo "CURRENT_XCODE_SELECT=$CURRENT_XCODE_SELECT"
	
	if [ "$CURRENT_XCODE_SELECT" != "$DESIRED_XCODE_SELECT" ]; then
		echo "***** Will perform xcode-select to '$DESIRED_XCODE_SELECT'"
		say "ex code selecting, your password may be required, please check"
		sudo xcode-select -s "$DESIRED_XCODE_SELECT"
	fi
	
	if [[ "$NAME" == "Carthage-"* ]] && (( $SHOULD_CARTHAGE_CHECKOUT )); then
		sh "$SCRIPT_DIRECTORY/Shared/carthage-checkout.sh" -w "$WORKING_DIRECTORY"
	elif [[ "$NAME" == "Cocoapods-"* ]] && (( $SHOULD_COCOAPODS_CHECKOUT )); then
		sh "$SCRIPT_DIRECTORY/Shared/cocoapods-checkout.sh" -w "$WORKING_DIRECTORY"
	else
		echo "**** SKIPPING CHECKOUT ****"
		SUMMARY_LOG_OUTPUT+=" (checkout was skipped) +++++"
	fi

	runXcodeBuild "$WORKSPACE_FILEPATH" "Swift-iOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "Swift-macOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "ObjectiveC-iOS"
	runXcodeBuild "$WORKSPACE_FILEPATH" "ObjectiveC-macOS"
	
	echo "------ END: $FUNCNAME $@ ------"
}


#################
# Perform Tests #
#################

performTests "Carthage-Minimum"
performTests "Cocoapods-Minimum"
performTests "Carthage-Latest"
performTests "Cocoapods-Latest"


############
# Conclude #
############

echo "$SUMMARY_LOG_OUTPUT"
say "All targets built successfully"

