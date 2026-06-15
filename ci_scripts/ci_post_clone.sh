#!/bin/bash
# Xcode Cloud Post Clone Script
# This runs AFTER the repo is cloned on Xcode Cloud infrastructure

set -e  # Exit on error

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

echo ""
echo "=========================================="
echo "✅ Post Clone Phase Complete"
echo "=========================================="
