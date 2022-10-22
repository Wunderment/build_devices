#!/bin/bash

### Global variables ###

# Tell the build system which img file to use as the recovery img.
export LOS_RECOVERY_IMG=vendor_boot

### Local variables ###

# Set the vendor for this device.
VENDOR=google

# This device use a common/shared device tree.
COMMONDEVICE=redbull

function build_wos {
	# For this device we need to add the factory partitions to the build system, do that now.
	# It will also disable strict path enforcement so we can add F-Droid etc to the system partition.
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$COMMONDEVICE/BoardConfigLineage.mk
	if ! grep WundermentOS $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	# We need to remove the flag that disables AVB during boot.
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$COMMONDEVICE/BoardConfigLineage.mk
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/' $BCFILE
	fi

	# We need to set the correct key for signing the system vbmeta.img.
	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$COMMONDEVICE/BoardConfig-common.mk
	if grep "testkey_rsa2048.pem" $BCCFILE > /dev/null; then
		sed -i 's/external\/avb\/test\/data\/testkey_rsa2048.pem/\/home\/WundermentOS\/.android-certs\/releasekey.key/' $BCCFILE
		sed -i 's/SHA256_RSA2048/SHA256_RSA4096/' $BCCFILE
	fi

	# Add the RADIO files to the build system.
	AFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/Android.mk
	if ! grep "# Radio image" $AFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/Android-mk-additions.txt >> $AFILE
	fi

	# Make sure we're using the 4096 bit signing keys.
	~/tasks/build/switch-keys.sh 4096

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

	~/tasks/build/switch-keys.sh 2048

	echo "Signing process complete for $DEVICE!"
}

