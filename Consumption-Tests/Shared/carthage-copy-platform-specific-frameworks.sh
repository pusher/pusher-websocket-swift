#! /bin/sh

case "$PLATFORM_NAME" in
macosx) plat=Mac;;
iphone*) plat=iOS;;
watch*) plat=watchOS;;
tv*) plat=tvOS;;
appletv*) plat=tvOS;;
*) echo "error: Unknown PLATFORM_NAME: $PLATFORM_NAME"; exit 1;;
esac
for (( n = 0; n < SCRIPT_INPUT_FILE_COUNT; n++ )); do
	VAR=SCRIPT_INPUT_FILE_$n
	framework=$(basename "${!VAR}")
	input_file_path="$SRCROOT/Carthage/Build/$plat/$framework.framework"
	echo "exporting SCRIPT_INPUT_FILE_$n=$input_file_path"
	export SCRIPT_INPUT_FILE_$n="$input_file_path"
done

/usr/local/bin/carthage copy-frameworks || exit

for (( n = 0; n < SCRIPT_INPUT_FILE_COUNT; n++ )); do
VAR=SCRIPT_INPUT_FILE_$n
source=${!VAR}.dSYM
dest=${BUILT_PRODUCTS_DIR}/$(basename "$source")
echo "$source"
echo "   -> $dest"
ditto "$source" "$dest" || exit
done
