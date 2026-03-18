#!/bin/sh
set -e

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify
flutter doctor

# Get dependencies
flutter pub get

# Generate iOS files
flutter build ios --no-codesign