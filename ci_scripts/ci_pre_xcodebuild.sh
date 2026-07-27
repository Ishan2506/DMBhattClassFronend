#!/bin/bash
# Xcode Cloud Pre-Xcodebuild Script
# This runs BEFORE the Xcode build starts

set -e

# Unset any proxy settings and URL rewrites to ensure direct git connections
git config --global --unset http.proxy || true
git config --global --unset https.proxy || true
git config --global --remove-section url."http://github.com" || true
git config --global --remove-section url."https://github.com" || true
git config --global --remove-section url."git@github.com:" || true
git config --local --unset http.proxy || true
git config --local --unset https.proxy || true

# Force git to use HTTPS for all github.com URLs (crucial for CocoaPods dependencies like purchases-hybrid-common)
git config --global url."https://github.com/".insteadOf "http://github.com/"
git config --global url."https://github.com/".insteadOf "git://github.com/"


export http_proxy=""
export https_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""
export no_proxy="*"
export NO_PROXY="*"

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
