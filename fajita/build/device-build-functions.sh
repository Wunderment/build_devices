#!/bin/bash

function build_wos {
	# For Fajita we need to add the prebuilt vendor.img to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep vendor.img ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk > /dev/null; then
		echo "" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		
		# We're using the sparse image here otherwise LOS will try and use the SEPolicy files from the ext
		# version and throw policy errors as they are from OOS.
		echo "# Add vendor image to the OTA and vbmeta hashtree." > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_PREBUILT_VENDORIMAGE := /home/WundermentOS/devices/fajita/blobs/images_raw/vendor.img" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		
		echo "AB_OTA_PARTITIONS += vendor" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		
		echo "" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "# Set the AVB key and hash algorithm." > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_AVB_KEY_PATH := /home/WundermentOS/.android-certs/releasekey.x509.pem" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_AVB_ALGORITHM := SHA256_RSA2048" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk

		echo "" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "# Include the rest of the prebuilt partitions." > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_PREBUILT_IMAGES := abl aop bluetooth cmnlib cmnlib64 devcfg dsp fw_4j1ed fw_4u1ea hyp india keymaster LOGO modem oem_stanvbk qupfw reserve storsec tz xbl xbl_config" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_PREBUILT_IMAGES_PATH := /home/WundermentOS/devices/fajita/blobs/images" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "AB_OTA_PARTITIONS += abl aop bluetooth cmnlib cmnlib64 devcfg dsp fw_4j1ed fw_4u1ea hyp india keymaster LOGO modem oem_stanvbk qupfw reserve storsec tz xbl xbl_config" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
	fi

	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/sdm845-common/BoardConfigCommon.mk > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/' ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/sdm845-common/BoardConfigCommon.mk
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

