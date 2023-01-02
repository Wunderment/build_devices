#!/bin/bash

### Global variables ###

# Tell the build system which img file to use as the recovery img.
export LOS_RECOVERY_IMG=recovery

### Local variables ###

# Set the vendor for this device.
VENDOR=samsung

# This device use a common/shared device tree.
COMMONDEVICE=gts4lv-common

function build_wos {
	RTFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$COMMONDEVICE/releasetools.py
	# For this device we need to add the recovery.img to the flashing script.
	# First check to see if we've already one it.
	if ! grep recovery.img $RTFILE > /dev/null; then
		sed -i 's/^def OTA_InstallEnd(info):/def OTA_InstallEnd(info):\n  AddImage(info, "recovery.img", "\/dev\/block\/bootdevice\/by-name\/recovery")/' $RTFILE
	fi

	common_build_wos
}

function sign_wos {
	echo "Start signing process for $DEVICE..."

	# Move in to the build directory
	cd ~/android/lineage-$LOS_BUILD_VERSION

	# Setup the build environment
	source build/envsetup.sh
	croot

	# Call the common tasks of creating the target files package from the global build functions.
	sign_wos_target_package

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

