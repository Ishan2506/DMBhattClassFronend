#!/bin/sh
set -e

# Navigate to the root directory of the project
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Clone the Flutter SDK (stable branch)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Pre-download iOS artifacts
flutter precache --ios

# Fetch dependencies
flutter pub get

# Generate iOS build configuration files
flutter build ios --config-only

# Install CocoaPods and project pods
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
cd ios
pod install