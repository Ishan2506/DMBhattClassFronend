#!/bin/bash
set -e

echo "======================================="
echo "Starting Xcode Cloud Post Clone Script"
echo "======================================="

# Navigate to repository root
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "📍 Working directory: $(pwd)"

echo "Repository Path:"
pwd

echo "---------------------------------------"
echo "Installing Flutter SDK"
echo "---------------------------------------"

# Remove old Flutter SDK if exists
rm -rf "$HOME/flutter"

# Install Flutter Stable
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"

# Add Flutter to PATH
export PATH="$HOME/flutter/bin:$PATH"

echo "Flutter Version:"
flutter --version

echo "---------------------------------------"
echo "Flutter Doctor"
echo "---------------------------------------"
flutter doctor -v

echo "---------------------------------------"
echo "Downloading iOS Artifacts"
echo "---------------------------------------"
flutter precache --ios

echo "---------------------------------------"
echo "Fetching Flutter Packages"
echo "---------------------------------------"
flutter pub get

echo "---------------------------------------"
echo "Cleaning Flutter"
echo "---------------------------------------"
flutter clean

echo "---------------------------------------"
echo "Generating iOS Configuration"
echo "---------------------------------------"
flutter build ios --release --no-codesign

echo "---------------------------------------"
echo "Installing CocoaPods"
echo "---------------------------------------"

cd ios

# Update pod repository
pod repo update

# Install pods
pod install --verbose

cd ..

echo "======================================="
echo "Post Clone Script Completed Successfully"
echo "======================================="