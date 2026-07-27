#!/bin/bash
# Xcode Cloud Pre-Xcodebuild Script
# This runs BEFORE the Xcode build starts

set -e

# Force git to use HTTPS for all github.com URLs (crucial for CocoaPods dependencies like purchases-hybrid-common)
git config --global url."https://github.com/".insteadOf "http://github.com/"
git config --global url."https://github.com/".insteadOf "git://github.com/"


# Force Git subprocesses to use HTTPS for github.com via environment variables
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="http://github.com/"
export GIT_CONFIG_KEY_1="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_1="git://github.com/"


echo "=========================================="
echo "🏗️  Xcode Cloud: Pre-Xcodebuild Phase"
echo "=========================================="

# Set Flutter path
export PATH="$HOME/flutter/bin:$PATH"

# Navigate to Flutter project
cd "$CI_WORKSPACE"

echo "📊 Flutter doctor:"
flutter doctor

echo ""
echo "=========================================="
echo "✅ Pre-Xcodebuild Phase Complete"
echo "=========================================="
