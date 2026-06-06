#!/bin/bash
set -e

echo "======================================="
echo "Starting iOS Build Fix Script"
echo "======================================="

echo "Flutter Version:"
flutter --version

echo "---------------------------------------"
echo "Flutter Clean"
echo "---------------------------------------"
flutter clean

echo "---------------------------------------"
echo "Removing Build Folder"
echo "---------------------------------------"
rm -rf build

echo "---------------------------------------"
echo "Removing Pods Cache"
echo "---------------------------------------"
rm -rf ios/Pods
rm -f ios/Podfile.lock

echo "---------------------------------------"
echo "Fetching Packages"
echo "---------------------------------------"
flutter pub get

echo "---------------------------------------"
echo "Updating Pods"
echo "---------------------------------------"

cd ios

pod repo update
pod install --verbose

cd ..

echo "---------------------------------------"
echo "Regenerating iOS Build"
echo "---------------------------------------"
flutter build ios --release --no-codesign

echo "======================================="
echo "iOS Build Fix Completed Successfully"
echo "======================================="