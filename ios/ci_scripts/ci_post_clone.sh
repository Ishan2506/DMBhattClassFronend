#!/bin/sh
set -e

echo "Flutter version:"
flutter --version

echo "Getting dependencies"
flutter pub get

echo "Installing CocoaPods"
cd ios
pod install