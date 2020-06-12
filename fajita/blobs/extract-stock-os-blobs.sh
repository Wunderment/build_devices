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
	cd ~/devices/$DEVICE/blobs

	# Create the image folder if required.  Stores the final img files to be added to the OTA.
	if [ ! -d "images" ]; then
		cd images
	fi

	# Create the image_raw folder if required.  Stores the raw img files extracted from OOS.
	if [ ! -d "images_raw" ]; then
		cd images_raw
	fi

	# Create the image_sparse folder if required.  Stores the converted raw to sparse foramt img files.
	if [ ! -d "images_sparse" ]; then
		cd images_sparse
	fi

	# Delete any previous extraction files.
	rm -rf ~/devices/$DEVICE/blobs/images/*

	# Overall for proprietary blobs we're using TheMuppets, but we still need some of the stock partitions, so get them now.
	# Make sure we're in the blobs directory to start.
	cd ~/devices/$DEVICE/blobs/

	# Extract the payload.bin file from stock.
	unzip -o ~/devices/$DEVICE/stock_os/current-stock-os.zip payload.bin

	# Extract img files so that they can be mounted.
	python ~/android/lineage-$LOS_BUILD_VERSION/lineage/scripts/update-payload-extractor/extract.py --output_dir ./images_raw payload.bin

	# Change in to the output directory.
	cd images_raw

	# Get rid of the images we don't need.
	rm system.img
	rm vbmeta.img
	rm boot.img
	rm dtbo.img

	# Change to the images directory.
	cd ~/devices/$DEVICE/blobs/images

	# Copy over the raw images from OOS.
	cp ~/devices/$DEVICE/blobs/images_raw/*.img .

	# Remove vendor.img as we'll pull a version with the proper hashtree after the build is run.
	rm vendor.img

	# Return to the blobs directory.
	cd ~/devices/$DEVICE/blobs/

	# We don't need payload.bin anymore.
	rm payload.bin
fi
