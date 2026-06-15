#!/bin/bash
# Xcode Cloud Pre-Xcodebuild Script
# This runs BEFORE the Xcode build starts

set -e

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
