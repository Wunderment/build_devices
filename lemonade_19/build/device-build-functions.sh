#!/bin/bash

VENDOR=oneplus

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/$LOS_DEVICE/BoardConfig.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep WundermentOS $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8350-common/BoardConfigCommon.mk
	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2/' $BCCFILE
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag/' $BCCFILE
		sed -i 's/external\/avb\/test\/data\/testkey_rsa4096.pem/\/home\/WundermentOS\/.android-certs\/releasekey.key/' $BCCFILE
	fi

	CFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8350-common/common.mk
	# We need to add the OEM lock/unlock feature to developers options if it's not there already.
	if ! grep "ro.oem_unlock_supported=1" $CFILE > /dev/null; then
		sed -i 's/^# OMX/# OEM Unlock reporting\nPRODUCT_DEFAULT_PROPERTY_OVERRIDES += \\\n    ro.oem_unlock_supported=1\n\n# OMX/' $CFILE
	fi

	DFSFILE=~/android/lineage-$LOS_BUILD_VERSION/kernel/$VENDOR/sm8350/arch/arm64/configs/vendor/genericarmv8-64_defconfig
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

	IRQRCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8350-common/init/init.qcom.recovery.rc
	# For this device we need to remove add a couple of symlinks so we can update all the partitions through recovery.
	# First check to see if we've already done it.
	if ! grep "oem_stanvbk_a" $IRQRCFILE > /dev/null; then
		patch $IRQRCFILE ~/devices/$DEVICE/build/init.qcom.recovery.rc.patch
	fi

	IQFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/sm8350-common/init/init.qcom.rc
	# We need to add a couple of symlinks to the init script so we can flash partitions.
	if ! grep "oem_stanvbk_a" $IQFILE > /dev/null; then
		patch $IQFILE ~/devices/$DEVICE/build/init.qcom.rc.patch
	fi

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

	if [ -f ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip ]; then
		echo "Adding vendor_boot and dtbo images to recovery zip..."
		RECOVERYNAME="$HOME/releases/ota/$LOS_DEVICE/WundermentOS-$LOS_BUILD_VERSION-$TODAY-recovery-$LOS_DEVICE"

		unzip -j $HOME/releases/signed_files/$LOS_DEVICE/signed-target_files-$LOS_DEVICE-$TODAY.zip IMAGES/dtbo.img -d $HOME/releases/ota/$LOS_DEVICE > /dev/null 2>&1
		unzip -j $HOME/releases/signed_files/$LOS_DEVICE/signed-target_files-$LOS_DEVICE-$TODAY.zip IMAGES/vendor_boot.img -d $HOME/releases/ota/$LOS_DEVICE > /dev/null 2>&1

		zip -j $RECOVERYNAME.zip $HOME/releases/ota/$LOS_DEVICE/dtbo.img
		zip -j $RECOVERYNAME.zip $HOME/releases/ota/$LOS_DEVICE/vendor_boot.img

		rm $HOME/releases/ota/$LOS_DEVICE/dtbo.img
		rm $HOME/releases/ota/$LOS_DEVICE/vendor_boot.img
	fi

	~/tasks/build/switch-keys.sh 2048

	echo "Signing process complete for $DEVICE!"
}

