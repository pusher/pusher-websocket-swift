#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904 
set -e

FILE="LATEST_SUPPORTED_XCODE_VERSION"
echo "FILE=$FILE"

SCRIPT_DIRECTORY="$(dirname $0)"
echo "SCRIPT_DIRECTORY=$SCRIPT_DIRECTORY"

WORKING_DIRECTORY="$SCRIPT_DIRECTORY"
echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"

XCODE_VERSION=$( head -n 1 "$WORKING_DIRECTORY/../$FILE" )
echo "XCODE_VERSION=$XCODE_VERSION"

sh "$WORKING_DIRECTORY/../Shared/carthage-checkout.sh" -w "$WORKING_DIRECTORY" -x "$XCODE_VERSION"
