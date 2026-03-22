#!/bin/sh
set -e

flutter pub get
cd ios
pod install