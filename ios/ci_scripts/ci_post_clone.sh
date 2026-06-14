#!/bin/sh
set -e

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

echo "Installing CocoaPods"
cd ios
pod install