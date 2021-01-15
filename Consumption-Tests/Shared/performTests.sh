#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904
set -e


####################
# Define Variables #
####################

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

SUMMARY_LOG_OUTPUT=""


####################
# Import Functions #
####################

source "$SCRIPT_DIRECTORY/assignXcodeAppPathFor.sh"
source "$SCRIPT_DIRECTORY/getXcodeVersionFor.sh"


####################
# Define Functions #
####################


# Usage: `extractArgs $@
function extractArgs {
	echo "------ BEGIN: $extractArgs $@ ------"
	
	SHOULD_CARTHAGE_CHECKOUT=1
	SHOULD_COCOAPODS_CHECKOUT=1
	SHOULD_SKIP_CARTHAGE=0
	SHOULD_SKIP_COCOAPODS=0
	SHOULD_SKIP_SPM=0

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
			-skip-spm)
				SHOULD_SKIP_SPM=1
				shift
				;;
			-skip-checkouts)
				SHOULD_CARTHAGE_CHECKOUT=0
				SHOULD_COCOAPODS_CHECKOUT=0
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
				echo "   -skip-spm"
				echo "   -skip-checkouts"
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
	echo "SHOULD_SKIP_SPM=$SHOULD_SKIP_SPM"

	echo "------ BEGIN: $extractArgs $@ ------"
}

# Usage: `runXcodeBuild "NAME" "SCHEME"`
function runXcodeBuild {

	echo "------ BEGIN: $FUNCNAME $@ ------"
	
	local NAME="$1"
	echo "NAME=$NAME"
	local SCHEME="$2"
	echo "SCHEME=$SCHEME"

	if [[ "$NAME" == "SwiftPackageManager-Minimum" ]] && [[ "$SCHEME" == "ObjectiveC"* ]]; then
		SUMMARY_LOG_OUTPUT+="\n 🔘 $SCHEME (SPM integration not supported with Obj-C in Xcode versions < v11.4)"
		echo "**** SKIPPING '$NAME - $SCHEME' ****"	
		echo "------ END: $FUNCNAME $@ ------"
		return 0
	fi
	
	local SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"
	
	local WORKSPACE_FILEPATH="$SCRIPT_DIRECTORY/../$NAME/$NAME.xcworkspace"
	echo "WORKSPACE_FILEPATH=$WORKSPACE_FILEPATH"
	
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
	
	echo "------ END: $FUNCNAME $@ ------"
}

# Usage: `performTests "Carthage-Minimum"`
function performTests {
	echo "------ BEGIN: $FUNCNAME $@ ------"

	local NAME="$1"
	echo "NAME=$NAME"
	
	local SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"
	
	SUMMARY_LOG_OUTPUT+="\n\n+++++ $NAME +++++"
	
	if ( [[ "$NAME" == "Carthage-"* ]] && (( $SHOULD_SKIP_CARTHAGE )) ) || \
	   ( [[ "$NAME" == "Cocoapods-"* ]] && (( $SHOULD_SKIP_COCOAPODS )) ) || \
	   ( [[ "$NAME" == "SwiftPackageManager-"* ]] && (( $SHOULD_SKIP_SPM )) )
	then 
		echo "**** SKIPPING '$NAME' ****"	
		echo "------ END: $FUNCNAME $@ ------"
		SUMMARY_LOG_OUTPUT+="\n 🟡 SKIPPING"
		return 0
	fi

	local WORKING_DIRECTORY="$SCRIPT_DIRECTORY/../$NAME"
	echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
	
	getXcodeVersionFor "$WORKING_DIRECTORY" # should set XCODE_VERSION
	echo "XCODE_VERSION=$XCODE_VERSION"
	
	assignXcodeAppPathFor "$XCODE_VERSION" # should set XCODE_APP_PATH
	echo "XCODE_APP_PATH=$XCODE_APP_PATH"	
	
	local DESIRED_XCODE_SELECT="$XCODE_APP_PATH/Contents/Developer"
	echo "DESIRED_XCODE_SELECT=$DESIRED_XCODE_SELECT"

	CURRENT_XCODE_SELECT=$( xcode-select -p )
	echo "CURRENT_XCODE_SELECT=$CURRENT_XCODE_SELECT"
	
	if [ "$CURRENT_XCODE_SELECT" != "$DESIRED_XCODE_SELECT" ]; then
		echo "***** Will perform xcode-select to '$DESIRED_XCODE_SELECT'"
		if sudo -n true 2>/dev/null; then 
			echo "sudo already granted"
		else
			say "ex code select requires your password"
		fi
		sudo xcode-select -s "$DESIRED_XCODE_SELECT"
	fi
	
	if [[ "$NAME" == "SwiftPackageManager-"* ]]; then
		true # Do nothing. No checkout to perform
	elif [[ "$NAME" == "Carthage-"* ]] && (( $SHOULD_CARTHAGE_CHECKOUT )); then
		sh "$SCRIPT_DIRECTORY/carthage-checkout.sh" -w "$WORKING_DIRECTORY"
	elif [[ "$NAME" == "Cocoapods-"* ]] && (( $SHOULD_COCOAPODS_CHECKOUT )); then
		sh "$SCRIPT_DIRECTORY/cocoapods-checkout.sh" -w "$WORKING_DIRECTORY"
	else
		echo "**** SKIPPING CHECKOUT ****"
		SUMMARY_LOG_OUTPUT+=" (checkout was skipped) +++++"
	fi

	runXcodeBuild "$NAME" "Swift-iOS-WithEncryption"
	runXcodeBuild "$NAME" "Swift-macOS-WithEncryption"
	runXcodeBuild "$NAME" "Swift-tvOS-WithEncryption"
	runXcodeBuild "$NAME" "ObjectiveC-iOS-WithEncryption"
	runXcodeBuild "$NAME" "ObjectiveC-macOS-WithEncryption"
	runXcodeBuild "$NAME" "ObjectiveC-tvOS-WithEncryption"
	
	echo "------ END: $FUNCNAME $@ ------"
}
