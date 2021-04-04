#!/bin/bash

# A simple wrapper to the main build script to automatically get the device type from the parent directory.

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

# Get the build action from the first command line parameter.
WOS_BUILD_TYPE=$1

# Export a proper script title so when we call the real build script, if there is an error, it will give the correct information.
export SCRIPT_TITLE="Usage: ./build.sh <action>"

~/tasks/build/build.sh $WOS_BUILD_TYPE $DEVICE

