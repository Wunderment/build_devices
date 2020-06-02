#!/bin/bash

# Get the device list and build types.
source ~/.WundermentOS/devices.sh

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))
VENDOR=oneplus

# A device name may have a special case where we're building multiple versios, like for LOS 16
# and 17.  In these cases an extra modifier on the device name is added that starts with a '_'
# so for example dumpling_17 to indicate to build LOS 17 for dumpling.  In these cases we need
# to leave the modifier on $DEVICE so logs and other commands are executed in the right directory
# but for the acutal LOS build, we need to strip it off.  So do so now.
LOS_DEVICE=`echo $DEVICE | sed 's/_.*//'`

# Find out which version of LinageOS we're going to build for this device.
WOS_BUILD_VAR=WOS_BUILD_VER_${DEVICE^^}
LOS_BUILD_VERSION=${!WOS_BUILD_VAR}

if [ ! -f ~/devices/$DEVICE/stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
	echo "Run \"../stock_os/get-stock-os.sh\" to retreive it."
else
	# Overall for proprietary blobs we're using TheMuppets, but we still need some of the stock partitions, so get them now.
	# Make sure we're in the blobs directory to start.
	cd ~/devices/$DEVICE/blobs/

	# Extract the payload.bin file from stock.
	unzip -o ~/devices/$DEVICE/stock_os/current-stock-os.zip payload.bin

	# We don't need payload.bin anymore.
	rm payload.bin

	# Extract img files so that they can be mounted.
	python ~/android/lineage-$LOS_BUILD_VERSION/lineage/scripts/update-payload-extractor/extract.py payload.bin --partitions vendor --output_dir ./

	# The vendor image nees to be in sparse format so convert it.
	img2simg vendor.img vendor.simg

	# Delete the old one and rename the new one.
	rm vendor.img
	mv vendor.simg vendor.img

	# All done... for now.
