#!/usr/bin/env bash

# debug-carthage-build.sh
# Script to debug and troubleshoot Carthage build issues

set -euo pipefail

echo "🔍 Carthage Build Troubleshooter"
echo "=================================="

# Function to print section headers
print_section() {
    echo ""
    echo "📋 $1"
    echo "$(printf '%.0s-' {1..50})"
}

# Check Xcode version
print_section "Xcode Information"
xcodebuild -version
xcrun --show-sdk-path
echo "Xcode path: $(xcode-select -p)"

# Check Carthage version
print_section "Carthage Information"
carthage version

# Check current dependencies
print_section "Current Dependencies"
echo "Cartfile contents:"
cat Cartfile || echo "No Cartfile found"
echo ""
echo "Cartfile.resolved contents:"
cat Cartfile.resolved || echo "No Cartfile.resolved found"

# Check for tweetnacl-swiftwrap specific issues
print_section "TweetNacl-SwiftWrap Analysis"
if [ -d "Carthage/Checkouts/tweetnacl-swiftwrap" ]; then
    echo "✅ tweetnacl-swiftwrap checkout exists"
    echo "Directory contents:"
    ls -la Carthage/Checkouts/tweetnacl-swiftwrap/
    
    echo ""
    echo "Xcode project info:"
    if [ -f "Carthage/Checkouts/tweetnacl-swiftwrap/TweetNacl.xcodeproj/project.pbxproj" ]; then
        echo "✅ Xcode project exists"
        # Check deployment targets
        grep -A 1 -B 1 "MACOSX_DEPLOYMENT_TARGET\|IPHONEOS_DEPLOYMENT_TARGET\|TVOS_DEPLOYMENT_TARGET" \
            Carthage/Checkouts/tweetnacl-swiftwrap/TweetNacl.xcodeproj/project.pbxproj | head -20
    else
        echo "❌ Xcode project not found"
    fi
else
    echo "❌ tweetnacl-swiftwrap checkout not found"
fi

# Test specific build command
print_section "Testing Build Command"
echo "Attempting to build tweetnacl-swiftwrap directly..."
if [ -d "Carthage/Checkouts/tweetnacl-swiftwrap" ]; then
    cd Carthage/Checkouts/tweetnacl-swiftwrap
    echo "Testing xcodebuild command..."
    set +e  # Don't exit on error for this test
    
    xcodebuild -project TweetNacl.xcodeproj \
        -scheme TweetNacl-macOS \
        -configuration Release \
        -sdk macosx \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY= \
        SUPPORTS_MACCATALYST=NO \
        clean build 2>&1 | head -50
    
    build_result=$?
    cd - > /dev/null
    
    if [ $build_result -eq 0 ]; then
        echo "✅ Direct build succeeded"
    else
        echo "❌ Direct build failed with exit code $build_result"
    fi
    set -e
else
    echo "⚠️  Cannot test build - checkout directory not found"
fi

# Suggestions
print_section "Troubleshooting Suggestions"
echo "1. 🧹 Clear all caches:"
echo "   rm -rf ~/Library/Caches/org.carthage.CarthageKit"
echo "   rm -rf Carthage"
echo ""
echo "2. 🔄 Update dependencies:"
echo "   carthage update --platform iOS,macOS,tvOS"
echo ""
echo "3. 🚫 Try without binaries:"
echo "   carthage update --no-use-binaries"
echo ""
echo "4. 📱 Try platform-specific build:"
echo "   carthage update --platform iOS"
echo ""
echo "5. 🔀 Consider switching to Swift Package Manager:"
echo "   Your project already supports SPM - check Package.swift"
echo ""
echo "6. 🔧 Manual workaround if needed:"
echo "   - Fork tweetnacl-swiftwrap"
echo "   - Update for Xcode 16 compatibility"
echo "   - Point Cartfile to your fork"

echo ""
echo "🎯 Quick Fix Commands:"
echo "======================"
echo "# Clean and retry:"
echo "rm -rf ~/Library/Caches/org.carthage.CarthageKit && rm -rf Carthage && carthage bootstrap --use-xcframeworks"
echo ""
echo "# Force rebuild without binaries:"
echo "carthage update --no-use-binaries --use-xcframeworks" 