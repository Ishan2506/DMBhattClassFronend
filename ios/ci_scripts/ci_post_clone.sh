#!/bin/bash
set -e

echo "🔧 Starting CI post-clone setup..."

# Navigate to the root directory of the project
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "📍 Working directory: $(pwd)"

# Clone the Flutter SDK (stable branch)
echo "📥 Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"
echo "🚀 Flutter PATH: $PATH"

# Verify Flutter installation
flutter --version

# Pre-download iOS artifacts
echo "⬇️ Precaching iOS artifacts..."
flutter precache --ios

# Fetch dependencies and regenerate Flutter config
echo "📦 Getting Flutter dependencies..."
flutter pub get

# CRITICAL: Regenerate Generated.xcconfig with correct paths for CI
echo "🔧 Regenerating Flutter build config..."
cd ios
rm -f Flutter/Generated.xcconfig
cd ..
flutter pub get  # This regenerates the config file
flutter clean
flutter pub get

# Install CocoaPods if needed
echo "🍫 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || echo "CocoaPods may already be installed"

# Install project pods
echo "📚 Installing project pods..."
cd ios
pod repo update
pod install --repo-update

echo "✅ CI post-clone setup completed!"