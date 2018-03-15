#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

git submodule update --remote
cd BluetoothLinux
swift package generate-xcodeproj
cp .jazzy.yaml ../
cd ../
jazzy --source-directory BluetoothLinux/
