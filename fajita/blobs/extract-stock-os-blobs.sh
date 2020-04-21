#!/bin/bash

# For the time being, don't update the blobs as there is no single source for them.
exit

# Get the device list and build types.
source ~/.WundermentOS/devices.sh

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))
VENDOR=oneplus

# Find out which version of LineageOS we're building for this device.
WOS_BUILD_VAR=WOS_BUILD_VER_${DEVICE^^}
LOS_BUILD_VERSION=${!WOS_BUILD_VAR}

if [ ! -f ~/devices/$DEVICE/stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
	echo "Run \"../stock_os/get-stock-os.sh\" to retreive it."
else
	# Change to the system_dump directory.
	cd ~/devices/$DEVICE/blobs/system_dump/

	# Delete any previous extraction files.
	rm -rf ~/devices/$DEVICE/blobs/system_dump/*

	# Extract the system and vendor data from the LinageOS archive.
	unzip -o ~/devices/$DEVICE/stock_os/current-stock-os.zip payload.bin

	# Extract img files so that they can be mounted.
	python ~/android/lineage-$LOS_BUILD_VERSION/lineage/scripts/update-payload-extractor/extract.py payload.bin --partitions system vendor --output_dir ./

	# Make some temporary directories to use.
	mkdir system
	mkdir vendor
	mkdir combined

	# Mount the system, vendor and product data.
	#
	# Note, these must appear in /etc/fstab otherwise we'd have to be root to moount them.  Use the following entires
	# in fstab to allow a user to mount them:
	#
	# /home/WundermentOS/devices/fajita/blobs/system_dump/system.img /home/WundermentOS/devices/fajita/blobs/system_dump/system auto defaults,noauto,user 0 1
	# /home/WundermentOS/devices/fajita/blobs/system_dump/vendor.img /home/WundermentOS/devices/fajita/blobs/system_dump/vendor auto defaults,noauto,user 0 1
	#
	# You must also add the following line to your /etc/group file so the user has the right permissions to read the files:
	#
	# oneplus:x:2000:WundermentOS
	#
	mount system
	mount vendor

	# Since the extraction script expects everything to be in a single directory and img files are
	# read only, copy everything over to a combined directory.  Do it as root to make sure we get everything.
	cp -R /home/WundermentOS/devices/$DEVICE/blobs/system_dump/system/* /home/WundermentOS/devices/$DEVICE/blobs/system_dump/combined

	# Now go in to the new combined folder and remove the pointer to the non-existant vendor directory and
	# then create a new real directory to copy from our mounted vendor img.
	cd combined
	rm -rf vendor
	mkdir vendor/

	# Copy the vendor files in to place, there will be some errors here as we're not doing it as root, but they don't matter.
	cp -R /home/WundermentOS/devices/$DEVICE/blobs/system_dump/vendor/* /home/WundermentOS/devices/$DEVICE/blobs/system_dump/combined/vendor

	# Now go and extract the blobs.
	#
	# Note: extract-files is going to complain about two missing .so files, libaptXHD_encoder.so/libaptX_encoder.so.
	#       These files can be found:
	#
	#	https://github.com/TheMuppets/proprietary_vendor_oneplus/tree/lineage-17.1/sdm845-common/proprietary/product/lib64
	#
	#	And added manually to the vendor/oneplus/sdm845-common/proprietary/product/lib64 directory.
	#
	#	These files come from the offcial Google Pixel Android images for the Pixel 3 XL (crosshatch)
	#	and can be found here:
	#
	#	https://developers.google.com/android/ota#crosshatch
	#
	cd ~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$DEVICE
	./extract-files.sh ~/devices/$DEVICE/blobs/system_dump/

	# Finally, let's do some cleanup.
	umount ~/devices/$DEVICE/blobs/system_dump/system
	umount ~/devices/$DEVICE/blobs/system_dump/vendor
        rm -rf ~/devices/$DEVICE/blobs/system_dump/*
fi
