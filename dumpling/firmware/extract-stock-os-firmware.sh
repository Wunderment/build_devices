#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

if [ ! -f ../stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
        echo "Run \"../stock_os/get-stock-os.sh\" to retrieve it."
else
	# Cleanup any old updates that exist.
	rm -rf ~/devices/$DEVICE/firmware/update
	rm -rf ~/devices/$DEVICE/firmware/ota
	cd ~/devices/$DEVICE/firmware
	mkdir update
	mkdir ota

	# Change to the system_dump directory.
	cd ~/devices/$DEVICE/firmware/ota

	# Extract the system and vendor data from the LinageOS archive.
	unzip ~/devices/$DEVICE/stock_os/current-stock-os.zip -d ~/devices/$DEVICE/firmware/ota -x *.dat

	# Copy the firmware files out of the ota update directory.
	cp -R ~/devices/$DEVICE/firmware/ota/firmware-update ~/devices/$DEVICE/firmware/update
	cp -R ~/devices/$DEVICE/firmware/ota/RADIO ~/devices/$DEVICE/firmware/update
	cp -R ~/devices/$DEVICE/firmware/ota/META-INF ~/devices/$DEVICE/firmware/update

	# Create a new update script.
	echo "ui_print(\"Updating RADIO and firmware...\");" > ~/devices/$DEVICE/firmware/update/new-updater-script

	# Extract the update lines from the updater-script.
	grep RADIO ~/devices/$DEVICE/firmware/update/META-INF/com/google/android/updater-script >> ~/devices/$DEVICE/firmware/update/new-updater-script
	grep firmware-update ~/devices/$DEVICE/firmware/update/META-INF/com/google/android/updater-script >> ~/devices/$DEVICE/firmware/update/new-updater-script

	# Cleanup.
	rm -rf ~/devices/$DEVICE/firmware/ota
	rm -rf ~/devices/$DEVICE/firmware/update

fi
