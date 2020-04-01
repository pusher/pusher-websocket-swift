#! /bin/sh

set -e # Ensure Script Exits immediately if any command exits with a non-zero status

WORKING_DIRECTORY="$(dirname $0)"
sh "$WORKING_DIRECTORY/../Shared/carthage-checkout.sh" -w "$WORKING_DIRECTORY" -x "LATEST_SUPPORTED_XCODE_VERSION"