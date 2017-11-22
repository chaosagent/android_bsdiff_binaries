#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

apk_path="$1"
prev_apk_path="$2"

# TODO check md5 of previous apk
echo "Checking if previous APK on device..."
apk_exists=$(adb shell '[ -e /data/local/prev_version.apk ] && echo -n 1 || echo -n 0')

if [ "$apk_exists" -eq "0" ] || [ ! -f "$prev_apk_path" ]; then
    echo "Previous apk not found on host or target; installing from scratch..."
    echo "Pushing APK..."
    adb push "$apk_path" /data/local/prev_version.apk
    echo "Installing..."
    adb shell 'pm install /data/local/prev_version.apk'

    cp "$apk_path" "$prev_apk_path"
    exit
fi

echo "Generating patch..."
LD_LIBRARY_PATH=$DIR ./bsdiff_host "$apk_path" "$prev_apk_path" /tmp/patch

echo "Pushing patch..."
adb push /tmp/patch /data/local/patch

echo "Applying patch..."
adb shell '/data/local/bspatch /data/local/prev_version.apk /data/local/prev_version.apk /data/local/patch'

cp "$apk_path" "$prev_apk_path"

echo "Installing..."
adb shell 'pm install -r /data/local/prev_version.apk'

