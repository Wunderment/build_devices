#!/bin/bash

# Just exit as for LOS 18 we use the muppets instead of the extraction script.
exit

# Source the device list.
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
	# Change to the system_dump directory.
	cd ~/devices/$DEVICE/blobs/system_dump/

	# Delete any previous extraction files.
	rm -rf ~/devices/$DEVICE/blobs/system_dump/*

	# Extract the system and vendor data from the LinageOS archive.
	unzip -o ~/devices/$DEVICE/stock_os/current-stock-os.zip system.transfer.list system.new.dat vendor.transfer.list vendor.new.dat

	# Convert dat files to img files that can be mounted.
	python ~/bin/sdat2img.py system.transfer.list system.new.dat system.img
	python ~/bin/sdat2img.py vendor.transfer.list vendor.new.dat vendor.img

	# Make some temporary directories to use.
	mkdir system
	mkdir vendor
	mkdir combined

	# Mount the system and vendor data.
	#
	# Note, these must appear in /etc/fstab otherwise we'd have to be root to moount them.  Use the following entires
	# in fstab to allow a user to mount them:
	#
	# /home/WundermentOS/devices/dumpling/blobs/system_dump/system.img /home/WundermentOS/devices/dumpling/blobs/system_dump/system auto defaults,noauto,user 0 1
	# /home/WundermentOS/devices/dumpling/blobs/system_dump/vendor.img /home/WundermentOS/devices/dumpling/blobs/system_dump/vendor auto defaults,noauto,user 0 1
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
	cd ~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE
	./extract-files.sh ~/devices/$DEVICE/blobs/system_dump/

	# Finally, let's do some cleanup.
	umount ~/devices/$DEVICE/blobs/system_dump/system
	umount ~/devices/$DEVICE/blobs/system_dump/vendor
	rm -rf ~/devices/$DEVICE/blobs/system_dump/*

fi
