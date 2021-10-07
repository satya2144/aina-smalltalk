#!/usr/bin/env bash
#Place this script in project/ios/

echo "Uninstalling all CocoaPods versions"
sudo gem uninstall cocoapods --all --executables

COCOAPODS_VER=`sed -n -e 's/^COCOAPODS: \([0-9.]*\)/\1/p' Podfile.lock`

echo "Installing CocoaPods version $COCOAPODS_VER"
sudo gem install cocoapods -v $COCOAPODS_VER

# fail if any command fails
set -e
# debug log
set -x

cd ..
git clone --depth 1 --branch 1.22.6 https://github.com/flutter/flutter.git
export PATH=`pwd`/flutter/bin:$PATH

flutter doctor -v
flutter clean
cd ./ios
pod deintegrate
cd ../
pod setup
flutter pub get

echo "Installed flutter to `pwd`/flutter"

flutter build ios --release --no-codesign