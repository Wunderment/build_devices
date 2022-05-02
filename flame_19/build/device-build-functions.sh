#!/bin/bash

VENDOR=google

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/coral/BoardConfigLineage.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep WundermentOS $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	# We need to remove the flag that disables the partition verification during boot.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/' $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/coral/BoardConfig-common.mk
	# We need to set the correct key for signing the system vbmeta.img.
	if ! grep "testkey_rsa2048.pem" $BCCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external\/avb\/test\/data\/testkey_rsa2048.pem/BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := \/home\/WundermentOS\/.android-certs\/releasekey.key/' $BCCFILE
	fi

	AFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/coral/Android.mk
	# Add the RADIO files to the build system.
	if ! grep "modem.img" $AFILE > /dev/null; then
		sed -i 's/^IMS_LIBS := libimscamera_jni.so libimsmedia_jni.so/$(call add-radio-file,images\/modem.img)\n\nIMS_LIBS := libimscamera_jni.so libimsmedia_jni.so/' $AFILE
	fi

	ASOPFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/coral/aosp_flame.mk
	# Disable strict path enforcement otherwise the build will fail when we add f-droid etc.
	sed -i 's/^PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := strict/#PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := strict/' $ASOPFILE

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

	# Use the signing script that includes other prebuilt partition support.
	sign_wos_target_apks

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

