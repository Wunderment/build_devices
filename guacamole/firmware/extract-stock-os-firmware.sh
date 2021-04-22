#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

if [ ! -f ../stock_os/current-stock-os.zip ]; then
    	echo "Stock OS not found!"
	echo ""
        echo "Run \"../stock_os/get-stock-os.sh\" to retreive it."
else
	echo "Firmware is extracted as part of the ../blobs/extract-stock-os-blobs.sh script for $DEVICE."
fi
