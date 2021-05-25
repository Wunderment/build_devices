#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

# A device name may have a special case where we're building multiple versions, like for LOS 16
# and 17.  In these cases an extra modifier on the device name is added that starts with a '_'
# so for example dumpling_17 to indicate to build LOS 17 for dumpling.  In these cases we need
# to leave the modifier on $DEVICE so logs and other commands are executed in the right directory
# but for the actual LOS build, we need to strip it off.  So do so now.
LOS_DEVICE=`echo $DEVICE | sed 's/_.*//'`

# Make sure we're in the stock os directory.
cd ~/devices/$DEVICE/stock_os

# Set the phone code and other settings to use in get-oneplus.sh.
PHONECODE=PM1574156235282

# Call the common script to download the stock OS from OnePlus.
source /home/WundermentOS/tasks/stock_os/get-oneplus.sh
