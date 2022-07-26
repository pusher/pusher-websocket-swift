#! /bin/sh

# Carthage cannot work with files in your local copy. It can only work with files committed 
# to a git repository (since it checkouts the files into its own Carthage/Checkouts directory).
# This is a little annoying during development when you want to test that your local changes
# haven't broken anything.  
# To work around this, this script...
#  - (if necessary) commits your local changes (don't worry this will be undone later) 
#  - tags the commit (giving it a name incorporating the current date/time)
#  - (if necessary) resets the commit (putting your working copy back as it was before)
#  - create/updates the Cartfile so it points to the tag that was just created
#  - performs a `carthage update` 
#  - removes the tag 


###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904 
set -e


###############################################
# Extract Command Line Arguments to Variables #
###############################################

while getopts ":w:x:" opt; do
    case $opt in
        w)
            echo "-w (Working Directory) was triggered, Parameter: $OPTARG"
            WORKING_DIRECTORY_UNEXPANDED=$OPTARG
            WORKING_DIRECTORY="$(cd "$(dirname "$WORKING_DIRECTORY_UNEXPANDED")"; pwd)/$(basename "$WORKING_DIRECTORY_UNEXPANDED")"
            echo "WORKING_DIRECTORY_UNEXPANDED=${WORKING_DIRECTORY_UNEXPANDED}"
            echo "WORKING_DIRECTORY=${WORKING_DIRECTORY}"
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1 # exit with non-zero code to indicate failure
        ;;
    esac
done


#############################
# Check Mandatory Arguments #
#############################

if [ -z "${WORKING_DIRECTORY}" ]; then
    echo "ERROR: Mandatory -w (Working Directory) argument was NOT specified" >&2
    exit 1 # exit with non-zero code to indicate failure
fi


####################
# Import Functions #
####################

source "$WORKING_DIRECTORY/../Shared/getXcodeVersionFor.sh"


######################
# Check Xcode-Select #
######################

getXcodeVersionFor "$WORKING_DIRECTORY" # should set XCODE_VERSION
echo "XCODE_VERSION=$XCODE_VERSION"

ACTUAL_XCODE_VERSION=$( xcodebuild -version | head -n 1)
echo "ACTUAL_XCODE_VERSION=${ACTUAL_XCODE_VERSION}"

if [ "$XCODE_VERSION" != "$ACTUAL_XCODE_VERSION" ]; then
    echo "ERROR: The Xcode Version specified ($XCODE_VERSION) does not match the current Xcode version ($ACTUAL_XCODE_VERSION)" >&2
    echo "Install the appropriate version of Xcode and use \`xcode-select -s\` to select the appropriate version."
    echo "Note: the format of the desired Xcode Version should exactly match what is output with \`xcodebuild -version\`."
    say "Failure. The wrong version of ex-code is selected"
    exit 1 # exit with non-zero code to indicate failure
fi


########################
# Setup some variables #
########################

# Temporarily change directory into the $WORKING_DIRECTORY
pushd "${WORKING_DIRECTORY}"

REPO_ROOT_DIR_PATH=$( git rev-parse --show-toplevel )
REPO_ROOT_ABS_DIR_PATH="$( cd "$REPO_ROOT_DIR_PATH" >/dev/null 2>&1 ; pwd -P )"
echo "REPO_ROOT_DIR_PATH=$REPO_ROOT_DIR_PATH"
echo "REPO_ROOT_ABS_DIR_PATH=$REPO_ROOT_ABS_DIR_PATH"

# For a temporary tag name we'll use the current date/time
TEMP_TAG_NAME="$(date '+%Y-%m-%d-%H-%M-%S')"
echo "TEMP_TAG_NAME=$TEMP_TAG_NAME"


#################################################
# Validation Successfully, perform the checkout #
#################################################

# Check the status of the working copy to determine if we need to commit the code temporarily
if [ -z "$(git status --porcelain)" ]; then 
	TEMP_COMMIT_REQUIRED=0
else  # Uncommitted changes
	TEMP_COMMIT_REQUIRED=1
fi

if (( $TEMP_COMMIT_REQUIRED )); then
	# Temporarily commit all changes in the working copy
	git add -A 
	git commit -m "Temporary commit"
fi

# Immediately tag the commit 
git tag "$TEMP_TAG_NAME"

if (( $TEMP_COMMIT_REQUIRED )); then
	# Rollback the temporary commit, reverting the working copy back where it started
	git reset HEAD~
fi

# Create/update the Cartfile (in the specified WORKING_DIRECTORY).  This might output for example:
# git "file:///Users/me/Code/pusher-websocket-swift" "2020-03-30-12-57-46"
echo "git \"file://$REPO_ROOT_ABS_DIR_PATH\" \"$TEMP_TAG_NAME\"" > "$WORKING_DIRECTORY/Cartfile"

# Before we perform the `carthage update` tell bash to continue if an error is encountered 
# This ensures that the tag gets removed even if the carthage command fails
set +e

# Perform the `carthage update` (using the Cartfile we just created/updated)
# (`./carthage.sh update` instead of `carthage update` as a workaround for Carthage Xcode 12 issue: https://github.com/Carthage/Carthage/issues/3019#issuecomment-665136323)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${DIR}/carthage.sh update
CARTHAGE_UPDATE_STATUS_CODE=$?
echo "CARTHAGE_UPDATE_STATUS_CODE=$CARTHAGE_UPDATE_STATUS_CODE"

set -e

# Delete the temporarily created git tag
git tag -d "$TEMP_TAG_NAME"

# Return to original directory
popd

exit $CARTHAGE_UPDATE_STATUS_CODE
