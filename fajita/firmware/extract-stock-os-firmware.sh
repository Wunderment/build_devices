#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

if [ ! -f ../stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
        echo "Run \"../stock_os/get-stock-os.sh\" to retreive it."
else
	# Cleanup any old updates that exist.
	rm -rf ~/devices/$DEVICE/firmware/update/*

	# Delete any previous extraction files, needs to be done as root.
	rm -rf ~/devices/$DEVICE/firmware/output/*
	rm ~/devices/$DEVICE/firmware/payload.bin

	# Extract the payload.bin file
	unzip ~/devices/$DEVICE/stock_os/current-stock-os.zip -d ~/devices/$DEVICE/firmware -x payload.bin 

	# Dump the payload.bin in to the output directory
	python ~/android/lineage/lineage/scripts/update-payload-extractor/extract.py payload.bin --partitions LOGO abl boot dtbo fw_4j1ed fw_fu1ea vbmeta aop bluetooth cmnlib64 cmnlib devcfg dsp hyp keybaster modem qupfw storsec tz xbl_config xbl oem_stanvbk reserve india --output_dir ./

	# Cleanup.
	rm ~/devices/$DEVICE/firmware/payload.bin

fi
