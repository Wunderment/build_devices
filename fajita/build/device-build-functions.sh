#!/bin/bash

VENDOR=oneplus

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$DEVICE/BoardConfig.mk
	# For $DEVICE we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep vendor.img $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt > $BCFILE
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

	# Create the md5 checksum file for the release
	echo "Create the md5 checksum..."
	md5sum ~/releases/ota/$PKGNAME.zip > ~/releases/ota/$PKGNAME.zip.md5sum

	# Grab a copy of the build.prop file
	echo "Store the build.prop file..."
	cp $OUT/system/build.prop ~/releases/ota/$PKGNAME.zip.prop

	# Cleanup
	echo "Store signed target files for future incremental updates..."
	cp signed-target_files.zip ~/releases/signed_files/signed-target_files-$DEVICE-$TODAY.zip

	echo "Signing process complete for $DEVICE!"
}

