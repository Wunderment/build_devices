#!/bin/bash

### Global variables ###

# Tell the build system which img file to use as the recovery img.
export LOS_RECOVERY_IMG=boot

### Local variables ###

# Set the vendor for this device.
VENDOR=oneplus

# This device use a common/shared device tree.
COMMONDEVICE=sm8150-common

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/BoardConfig.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep ADD_RADIO_FILES $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/BoardConfigCommon.mk
	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/' $BCCFILE
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/' $BCCFILE
	fi

	CFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/common.mk
	# We need to add the OEM lock/unlock feature to developers options if it's not there already.
	if ! grep "ro.oem_unlock_supported=1" $CFILE > /dev/null; then
		sed -i 's/^# OMX/# OEM Unlock reporting\nPRODUCT_DEFAULT_PROPERTY_OVERRIDES += \\\n    ro.oem_unlock_supported=1\n\n# OMX/' $CFILE
	fi

	ABFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/AndroidBoard.mk
	# Add the RADIO files to the build system.
	if [ ! -f $ABFILE ]; then
		cp  ~/devices/$DEVICE/build/AndroidBoard.mk $ABFILE
	fi

	IRQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/rootdir/etc/init.recovery.qcom.rc
	# We need to add a couple of symlinks to the recovery init script so we can flash partitions.
	if ! grep "oem_stanvbk_a" $IRQFILE > /dev/null; then
		patch $IRQFILE ~/devices/$DEVICE/build/init.recovery.qcom.rc.patch
	fi

	IQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/rootdir/etc/init.qcom.rc
	# We need to add a couple of symlinks to the init script so we can flash partitions.
	if ! grep "oem_stanvbk_a" $IQFILE > /dev/null; then
		patch $IQFILE ~/devices/$DEVICE/build/init.qcom.rc.patch
	fi

	TEFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/sepolicy/vendor/update_engine.te
	# Add in the extra permissions for the update engine to access the extra oem partitions for OTAs.
	if [ ! -f $TEFILE ]; then
		cp ~/devices/$DEVICE/build/update_engine.te $TEFILE
	fi

	FCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8150-common/sepolicy/vendor/file_contexts
	# Add the storsec partitions to the block list.
	if ! grep "storesec_[ab]" $FCFILE > /dev/null; then
		patch $FCFILE ~/devices/$DEVICE/build/file_contexts.patch
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
	sign_wos_target_apks

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

