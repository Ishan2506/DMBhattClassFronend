#!/bin/sh
set -e

# Ensure we're in the repository root
if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
  cd "$CI_PRIMARY_REPOSITORY_PATH"
fi

# Install Flutter
rm -rf "$HOME/flutter"
echo "Cloning Flutter repository..."
if git clone https://github.com/flutter/flutter.git --depth 1 --branch stable --single-branch "$HOME/flutter"; then
  echo "Flutter cloned successfully"
else
  echo "Clone failed, retrying..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable --single-branch "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
export FLUTTER_HOME="$HOME/flutter"
which flutter || (echo "Flutter not found in PATH" && exit 1)

echo "Flutter version:"
flutter --version

echo "Getting dependencies"
flutter pub get

echo "Precaching Flutter iOS artifacts..."
flutter precache --ios

echo "Installing CocoaPods"
if [ -d "ios" ]; then
  cd ios
  pod install || {
    echo "Pod install failed, trying with repo update..."
    pod install --repo-update
  }
  cd ..
else
  echo "Error: ios directory not found"
  exit 1
fi