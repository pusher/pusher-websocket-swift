#!/usr/bin/env bash

# carthage.sh
# Usage example: ./carthage.sh build --platform iOS

set -euo pipefail

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

# For Xcode 12+ make sure EXCLUDED_ARCHS is set to arm architectures otherwise
# the build will fail on lipo due to duplicate architectures.
# Enhanced for Xcode 16 compatibility

CURRENT_XCODE_VERSION=$(xcodebuild -version | grep "Build version" | cut -d' ' -f3)
echo "EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$CURRENT_XCODE_VERSION = arm64 arm64e armv7 armv7s armv6 armv8" >> $xcconfig

echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$(XCODE_PRODUCT_BUILD_VERSION))' >> $xcconfig
echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> $xcconfig

# Add Xcode 16 specific build settings to avoid common build issues
echo 'ENABLE_USER_SCRIPT_SANDBOXING = NO' >> $xcconfig
echo 'DEAD_CODE_STRIPPING = NO' >> $xcconfig
echo 'COMPILER_INDEX_STORE_ENABLE = NO' >> $xcconfig
echo 'ENABLE_PREVIEWS = NO' >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"

# Function to attempt building with fallback strategies
attempt_carthage_build() {
    local attempt=$1
    local extra_flags=""
    
    case $attempt in
        1)
            echo "📦 Attempt 1: Standard Carthage build"
            ;;
        2)
            echo "📦 Attempt 2: Building with --no-use-binaries flag"
            extra_flags="--no-use-binaries"
            ;;
        3)
            echo "📦 Attempt 3: Building with platform-specific flags"
            extra_flags="--no-use-binaries --platform iOS,macOS,tvOS"
            ;;
    esac
    
    if carthage "$@" $extra_flags; then
        echo "✅ Carthage build succeeded on attempt $attempt"
        return 0
    else
        echo "❌ Carthage build failed on attempt $attempt"
        return 1
    fi
}

# Retry logic with different strategies
max_attempts=3
for attempt in $(seq 1 $max_attempts); do
    if attempt_carthage_build $attempt "$@"; then
        exit 0
    fi
    
    if [ $attempt -lt $max_attempts ]; then
        echo "⏳ Waiting 30 seconds before next attempt..."
        sleep 30
        
        # Clean up any partial builds
        echo "🧹 Cleaning up partial builds..."
        rm -rf Carthage/Build
    fi
done

echo "💥 All Carthage build attempts failed. Check the build log for details."
echo "🔍 Common solutions:"
echo "  1. Try running: rm -rf ~/Library/Caches/org.carthage.CarthageKit"
echo "  2. Try running: rm -rf Carthage && carthage update"
echo "  3. Check if dependencies are compatible with Xcode 16"
exit 1