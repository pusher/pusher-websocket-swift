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

source "$SCRIPT_DIRECTORY/Shared/performTests.sh"


#####################
# Extract Arguments #
#####################

extractArgs $@


#################
# Perform Tests #
#################

performTests "Carthage-Latest"
performTests "Cocoapods-Latest"
performTests "SwiftPackageManager-Latest"


############
# Conclude #
############

echo "$SUMMARY_LOG_OUTPUT"
say "All targets built successfully"
