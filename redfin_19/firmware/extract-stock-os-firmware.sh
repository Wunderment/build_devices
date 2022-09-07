#!/bin/bash

# Get the device list and build types.
source ~/.WundermentOS/devices.sh

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))
VENDOR=google

# A device name may have a special case where we're building multiple versions, like for LOS 16
# and 17.  In these cases an extra modifier on the device name is added that starts with a '_'
# so for example dumpling_17 to indicate to build LOS 17 for dumpling.  In these cases we need
# to leave the modifier on $DEVICE so logs and other commands are executed in the right directory
# but for the actual LOS build, we need to strip it off.  So do so now.
LOS_DEVICE=`echo $DEVICE | sed 's/_.*//'`

# Find out which version of LinageOS we're going to build for this device.
WOS_BUILD_VAR=WOS_BUILD_VER_${DEVICE^^}
LOS_BUILD_VERSION=${!WOS_BUILD_VAR}

# Check to see if we have the stock os file, if not throw an error.
if [ ! -f ~/devices/$DEVICE/stock_os/current-stock-os.zip ]; then
    echo "Stock OS not found for $DEVICE!"
	echo ""
	echo "Run \"../stock_os/get-stock-os.sh\" to retrieve it."
else
	cd ~/devices/$DEVICE/firmware

	# Create the image folder in the device tree if required.  Stores the final img files to be added to the OTA.
	if [ ! -d "~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/images" ]; then
		mkdir ~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/images
	fi

	# Create the image_raw folder if required.  Stores the raw img files extracted from OOS.
	if [ ! -d "images_raw" ]; then
		mkdir images_raw
	fi

	# Delete any previous extraction files.
	rm -rf ~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/images/*
	rm -rf ~/devices/$DEVICE/firmware/images_raw/*

	# Make sure we're in the images_raw directory to start.
	cd ~/devices/$DEVICE/firmware/images_raw

	# Now unzip the radio and bootloader images.
	unzip -j -o ~/devices/$DEVICE/stock_os/current-stock-os.zip *.img

	# We only need radio though...
	rm bootloader*.img

	# And extract the img files.
	imjtool radio*.img extract

	# Add ".img" to the extracted files and move them up a directory.
	cd extracted
	for f in *; do mv "$f" "../$f.img"; done

	# Remove the extracted directory.
	cd ..
	rm -rf extracted

	# Get rid of the images we don't need.
	rm radio*.img

	# Change to the images directory.
	cd ~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/images

	# Copy over the raw images.
	cp ~/devices/$DEVICE/firmware/images_raw/*.img .

	# Return to the firmware directory.
	cd ~/devices/$DEVICE/firmware/

	# Cleanup!
	rm -rf images_raw
fi
