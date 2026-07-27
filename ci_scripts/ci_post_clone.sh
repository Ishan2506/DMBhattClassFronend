#!/bin/bash
# Xcode Cloud Post Clone Script
# This runs AFTER the repo is cloned on Xcode Cloud infrastructure

set -e  # Exit on error

# Force git to use HTTPS for all github.com URLs (crucial for CocoaPods dependencies like purchases-hybrid-common)
git config --global url."https://github.com/".insteadOf "http://github.com/"
git config --global url."https://github.com/".insteadOf "git://github.com/"


# Force Git subprocesses to use HTTPS for github.com via environment variables
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="http://github.com/"
export GIT_CONFIG_KEY_1="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_1="git://github.com/"


echo "=========================================="
echo "🔄 Xcode Cloud: Post Clone Phase"
echo "=========================================="

# Install Flutter if not present
echo "📦 Installing Flutter..."
export PATH="$HOME/flutter/bin:$PATH"

if ! command -v flutter &> /dev/null; then
    echo "Cloning Flutter repository..."
    git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
else
    echo "✓ Flutter already installed"
fi

flutter --version

# Install/update CocoaPods
echo "📦 Ensuring CocoaPods is installed..."
if ! command -v pod &> /dev/null; then
    sudo gem install cocoapods
fi
pod repo update

# Navigate to Flutter project root
cd "$CI_WORKSPACE"

# Clean Flutter build artifacts
echo "🧹 Cleaning Flutter project..."
flutter clean

# Get Dart/Flutter dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Navigate to iOS directory
cd ios

# Remove old CocoaPods cache
echo "🧹 Removing old CocoaPods cache..."
rm -rf Pods
rm -f Podfile.lock

# Install pods with repo update
echo "📦 Installing iOS pods with fresh repository..."
pod install --repo-update

# Resolve Swift Package Dependencies for Xcode Cloud
echo "📦 Resolving Swift Package dependencies..."
xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner || true

echo ""
echo "=========================================="
echo "✅ Post Clone Phase Complete"
echo "=========================================="
