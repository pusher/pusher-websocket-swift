#! /bin/sh

###############################################################################
# Ensure Script Exits immediately if any command exits with a non-zero status #
###############################################################################
# http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs#1379904 
set -e


WORKING_DIRECTORY=.

XCODE_VERSION=$( head -n 1 ../LATEST_SUPPORTED_XCODE_VERSION ) 
echo "XCODE_VERSION=$XCODE_VERSION"

sh ../Shared/carthage-checkout.sh -w "$WORKING_DIRECTORY" -x "$XCODE_VERSION"
