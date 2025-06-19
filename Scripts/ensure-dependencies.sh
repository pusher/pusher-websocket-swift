#!/usr/bin/env bash

# ensure-dependencies.sh
# Ensures that dependencies are available for the main Xcode project

set -euo pipefail

echo "🔍 Ensuring dependencies are available..."

# Check if Carthage dependencies exist
if [ -f "Carthage/Build/NWWebSocket.xcframework" ] && [ -f "Carthage/Build/TweetNacl.xcframework" ]; then
    echo "✅ Carthage dependencies found"
    exit 0
fi

echo "❌ Carthage dependencies missing"
echo "🔄 Attempting to resolve via Swift Package Manager..."

# Ensure Carthage/Build directory exists
mkdir -p Carthage/Build

# Use SPM to resolve and prepare dependencies
echo "📦 Resolving Swift Package Manager dependencies..."
swift package resolve

# Check if we can use swift build to create the necessary artifacts
echo "🔨 Building with Swift Package Manager..."
if swift build -c release; then
    echo "✅ Swift Package Manager build succeeded"
    
    # Create placeholder files to indicate SPM is providing dependencies
    # The actual linking will be handled by SPM during xcodebuild
    echo "📝 Creating SPM dependency markers..."
    mkdir -p "Carthage/Build"
    
    # Create marker files
    echo "# SPM providing NWWebSocket" > "Carthage/Build/NWWebSocket.spm-marker"
    echo "# SPM providing TweetNacl" > "Carthage/Build/TweetNacl.spm-marker"
    
    echo "✅ Dependencies prepared via Swift Package Manager"
    exit 0
else
    echo "❌ Swift Package Manager build failed"
    exit 1
fi 