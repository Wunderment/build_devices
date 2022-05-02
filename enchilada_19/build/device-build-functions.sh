#!/bin/bash

VENDOR=oneplus

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/BoardConfig.mk
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

	ABFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/AndroidBoard.mk
	# Add the RADIO files to the build system.
	if [ ! -f $ABFILE ]; then
		cp  ~/devices/$DEVICE/build/AndroidBoard.mk $ABFILE
	fi

	IRQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sdm845-common/rootdir/etc/init.recovery.qcom.rc
	# We need to add a couple of symlinks to the recovery init script so we can flash partitions.
	if ! grep "oem_stanvbk_a" $IRQFILE > /dev/null; then
		patch $IRQFILE ~/devices/$DEVICE/build/init.recovery.qcom.rc.patch
	fi

	IQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sdm845-common/rootdir/etc/init.qcom.rc
	# We need to add a couple of symlinks to the init script so we can flash partitions.
	if ! grep "oem_stanvbk_a" $IQFILE > /dev/null; then
		patch $IQFILE ~/devices/$DEVICE/build/init.qcom.rc.patch
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

	# Use the pre-built version of the vendor IMG during signing.
	sign_wos_target_apks_vendor_prebuilt

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

