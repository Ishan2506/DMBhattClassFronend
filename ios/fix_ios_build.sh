#!/bin/bash

echo "Cleaning Flutter..."
flutter clean

echo "Removing Pods..."
rm -rf ios/Pods ios/Podfile.lock

echo "Removing build..."
rm -rf build

echo "Removing macOS metadata..."
xattr -rc .

echo "Installing packages..."
flutter pub get

echo "Installing pods..."
cd ios
pod install
cd ..

echo "Done ✅ Now build again"
