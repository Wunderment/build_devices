#!/bin/bash

VENDOR=oneplus

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$DEVICE/BoardConfig.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep vendor.img $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sdm845-common/BoardConfigCommon.mk
	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/' $BCCFILE
	fi

	# Build WOS.
	common_build_wos
}

function sign_wos {
	echo "Start signing process for $DEVICE..."

	# Move in to the build directory
	cd ~/android/lineage-$LOS_BUILD_VERSION

	# Setup the build environment
	source build/envsetup.sh
	croot

	# Use the pre-built version of the vendor img during signing.
	sign_wos_target_apks_vendor_prebuilt

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

