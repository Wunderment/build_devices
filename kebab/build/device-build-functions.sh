#!/bin/bash

VENDOR=oneplus

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/BoardConfig.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep WundermentOS $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8250-common/BoardConfigCommon.mk
	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/' $BCCFILE
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/' $BCCFILE
		sed -i 's/^BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external\/avb\/test\/data\/testkey_rsa2048.pem/BOARD_AVB_KEY_PATH := \/home\/WundermentOS\/.android-certs\/releasekey.key/' $BCCFILE
	fi

	CFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8250-common/common.mk
	# We need to add the OEM lock/unlock feature to developers options if it's not there already.
	if ! grep "ro.oem_unlock_supported=1" $CFILE > /dev/null; then
		sed -i 's/^# OMX/# OEM Unlock reporting\nPRODUCT_DEFAULT_PROPERTY_OVERRIDES += \\\n    ro.oem_unlock_supported=1\n\n# OMX/' $CFILE
	fi

	DFSFILE=~/android/lineage-$LOS_BUILD_VERSION/kernel/$VENDOR/sm8250/arch/arm64/configs/vendor/kona-perf_defconfig
	# For this device we need to remove a the debugging file system for our user build.
	# First check to see if we've already done it.
	if ! grep "CONFIG_DEBUG_FS=y" $DFSFILE > /dev/null; then
		sed -i 's/^CONFIG_DEBUG_FS=y/CONFIG_DEBUG_FS=n/' $DFSFILE
	fi

	ABFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/AndroidBoard.mk
	# Add the RADIO files to the build system.
	if [ ! -f $ABFILE ]; then
		cp  ~/devices/$DEVICE/build/AndroidBoard.mk $ABFILE
	fi

	IRQRCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8250-common/rootdir/etc/init.recovery.qcom.rc
	# For this device we need to remove add a couple of symlinks so we can update all the partitions through recovery.
	# First check to see if we've already done it.
	if ! grep "spunvm_a" $IRQRCFILE > /dev/null; then
		patch $IRQRCFILE ~/devices/$DEVICE/build/init.recovery.qcom.rc.patch
	fi

	IQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8250-common/rootdir/etc/init.qcom.rc
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

	# Use the signing script that includes other prebuilt partition support.
	sign_wos_target_apks

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

