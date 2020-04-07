#! /bin/sh


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
source "$WORKING_DIRECTORY/../Shared/readAllXcconfigVersionValuesFor.sh"


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


#################
# Read Versions #
#################

readAllXcconfigVersionValuesFor "$WORKING_DIRECTORY"
# should set SWIFT_VERSION, IPHONEOS_DEPLOYMENT_TARGET, MACOSX_DEPLOYMENT_TARGET & TVOS_DEPLOYMENT_TARGET
echo "SWIFT_VERSION=$SWIFT_VERSION"
echo "IPHONEOS_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET"
echo "MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET"
echo "TVOS_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET"


#################################################
# Validation Successfully, perform the checkout #
#################################################

# Temporarily change directory into the $WORKING_DIRECTORY
pushd "${WORKING_DIRECTORY}"

# Remove any existing Cocoapods related files/directories
rm -f "Podfile"
rm -f "Podfile.lock"
rm -rf "Pods"

# Create the Podfile from the template (in the specified WORKING_DIRECTORY)
# replacing all the appropriate placeholders.
sed <Podfile.template \
    -e "s#{IOS_VERSION}#${IPHONEOS_DEPLOYMENT_TARGET}#" \
    -e "s#{MAC_VERSION}#${MACOSX_DEPLOYMENT_TARGET}#" \
    -e "s#{TVOS_VERSION}#${TVOS_DEPLOYMENT_TARGET}#" \
    >Podfile

# Perform the `pod install` (using the Podfile we just created)
pod install

# Return to original directory
popd
