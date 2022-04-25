#!/bin/bash
set -eu
mkdir -p "./docs"
echo "Build"
swift build
echo "Generate HTML"
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target BluetoothLinux \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path BluetoothLinux \
    --output-path ./docs