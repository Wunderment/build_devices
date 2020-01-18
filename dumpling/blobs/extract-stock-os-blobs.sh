#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))
VENDOR=oneplus

if [ ! -f ~/devices/$DEVICE/stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
	echo "Run \"../stock_os/get-stock-os.sh\" to retreive it."
else
	# Make the system_dump directory.
	cd ~/devices/$DEVICE/blobs
	rm -rf ~/devices/$DEVICE/blobs/system_dump
	mkdir system_dump
	cd ~/devices/$DEVICE/blobs/system_dump/

	# Extract the system and vendor data from the LinageOS archive.
	unzip -o ~/devices/$DEVICE/stock_os/current-stock-os.zip system.transfer.list system.new.dat vendor.transfer.list vendor.new.dat

	# Convert dat files to img files that can be mounted.
	python ~/bin/sdat2img.py system.transfer.list system.new.dat system.img
	python ~/bin/sdat2img.py vendor.transfer.list vendor.new.dat vendor.img

	# Make some temporary directories to use.
	mkdir system/
	mkdir vendor/
	mkdir combined/

	# Mount the system and vendor data.
	#
	# Note, these must appear in /etc/fstab otherwise we'd have to be root to moount them.  Use the following entires
	# in fstab to allow a user to mount them:
	#
	mount system.img system/
	mount vendor.img vendor/

	# Since the extraction script expects everything to be in a single directory and img files are
	# read only, copy everything over to a combined directory.  Do it as root to make sure we get everything.
	cp -R /home/WundermentOS/devices/$DEVICE/blobs/system_dump/system/* /home/WundermentOS/devices/$DEVICE/blobs/system_dump/combined

	# Now go in to the new combined folder and remove the pointer to the non-existant vendor directory and
	# then create a new real directory to copy from our mounted vendor img.
	cd combined
	rm -rf vendor
	mkdir vendor/

	# Copy the vendor files in to place, again as root to be sure.
	cp -R /home/WundermentOS/devices/$DEVICE/blobs/system_dump/vendor/* /home/WundermentOS/devices/$DEVICE/blobs/system_dump/combined/vendor

	# Now go and extract the blobs.
	cd ~/android/lineage/device/$VENDOR/$DEVICE
	./extract-files.sh ~/devices/$DEVICE/blobs/system_dump/

	# Finally, let's do some cleanup.
	umount ~/devices/$DEVICE/blobs/system_dump/system
	umount ~/devices/$DEVICE/blobs/system_dump/vendor
	rm -rf ~/devices/$DEVICE/blobs/system_dump

fi