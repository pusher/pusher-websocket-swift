#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904 
set -e

XCODE_VERSION_FILENAME="MINIMUM_SUPPORTED_XCODE_VERSION"
echo "XCODE_VERSION_FILENAME=$XCODE_VERSION_FILENAME"

SCRIPT_DIRECTORY="$(dirname $0)"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

WORKING_DIRECTORY="$SCRIPT_DIRECTORY"
echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"

sh "$WORKING_DIRECTORY/../Shared/carthage-checkout.sh" -w "$WORKING_DIRECTORY" -x "$XCODE_VERSION_FILENAME"
