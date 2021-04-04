#!/bin/bash

# Get the device list and build types.
source ~/.WundermentOS/devices.sh

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))
VENDOR=google

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
		mkdir images
	fi

	# Create the image_raw folder if required.  Stores the raw img files extracted from OOS.
	if [ ! -d "images_raw" ]; then
		mkdir images_raw
	fi

	# Delete any previous extraction files.
	rm -rf ~/devices/$DEVICE/blobs/images/*

	# Overall for proprietary blobs we're using TheMuppets, but we still need some of the stock partitions, so get them now.
	# Make sure we're in the blobs directory to start.
	cd ~/devices/$DEVICE/blobs/

	# Extract the stock OS zip file.
	unzip -j -o ~/devices/$DEVICE/stock_os/current-stock-os.zip *.zip

	# Change in to the output directory.
	cd images_raw

	# Extract the payload.bin file from stock.
	unzip -o ../*.zip 

	# Now unzp the boot and radio images.
	unzip -j -o ~/devices/$DEVICE/stock_os/current-stock-os.zip *.img

	# And extract the img files.
	imjtool radio*.img extract
	imjtool bootloader*.img extract

	# Add ".img" to the extracted files and move them up a directory.
	cd extracted
	for f in *; do mv "$f" "../$f.img"; done

	# Remove the extracted directory.
	cd ..
	rm -rf extracted

	# Get rid of the images we don't need.
	# 	system/vbmeta/boot/dtbo will be generated during build
	#	india/reserve/oem_stanvbk can't be written by lineage recovery
	rm android-info.txt
	rm radio*.img
	rm bootloader*.img
	#rm system.img
	#rm vbmeta.img
	#rm boot.img
	#rm dtbo.img
	#rm india.img
	#rm reserve.img
	#rm oem_stanvbk.img

	# Change to the images directory.
	cd ~/devices/$DEVICE/blobs/images

	# Copy over the raw images from OOS.
	cp ~/devices/$DEVICE/blobs/images_raw/*.img .

	# Remove vendor.img as we'll pull a version with the proper hashtree after the build is run.
	rm vendor.img

	# Return to the blobs directory.
	cd ~/devices/$DEVICE/blobs/

	# We don't need zip anymore.
	rm *.zip
fi
