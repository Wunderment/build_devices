#!/bin/bash

VENDOR=google

function build_wos {
	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/redbull/BoardConfigLineage.mk
	# For this device we need to add the prebuilt vendor.img and other partitions to the build system, do that now.
	# It will also disable strict path enforcement so we can add F-Droid etc to the system partition.
	# First check to see if we've already one it.
	if ! grep WundermentOS $BCFILE > /dev/null; then
		cat ~/devices/$DEVICE/build/board-config-additions.txt >> $BCFILE
	fi

	BCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/redbull/BoardConfigLineage.mk
	# We need to remove the flag that disables the partition verification during boot.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" $BCFILE > /dev/null; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3/' $BCFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/redbull/BoardConfig-common.mk
	# We need to set the correct key for signing the system vbmeta.img.
	if grep "testkey_rsa2048.pem" $BCCFILE > /dev/null; then
		sed -i 's/external\/avb\/test\/data\/testkey_rsa2048.pem/\/home\/WundermentOS\/.android-certs\/releasekey.key/' $BCCFILE
		sed -i 's/SHA256_RSA2048/SHA256_RSA4096/' $BCCFILE
	fi

	ABFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/redbull/AndroidBoard.mk
	# Add the RADIO files to the build system.
	if [ ! -f $ABFILE ]; then
		cp ~/devices/$DEVICE/build/AndroidBoard.mk $ABFILE
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
		echo "Replacing default recovery with vendor_boot..."
		RECOVERYNAME="$HOME/releases/ota/$LOS_DEVICE/WundermentOS-$LOS_BUILD_VERSION-$TODAY-recovery-$LOS_DEVICE"

		# Remove the recovery image we added to the archive during the standard build process...
		zip -d  $RECOVERYNAME.zip $RECOVERYNAME.img

		# Now get the vendor_boot.img and rename it.
		unzip -j $HOME/releases/signed_files/$LOS_DEVICE/signed-target_files-$LOS_DEVICE-$TODAY.zip IMAGES/vendor_boot.img -d $HOME/releases/ota/$LOS_DEVICE > /dev/null 2>&1
		mv $HOME/releases/ota/$LOS_DEVICE/vendor_boot.img $HOME/releases/ota/$LOS_DEVICE/$RECOVERYNAME.img

		# Add the new recovery to the zip file.
		zip -j $RECOVERYNAME.zip $HOME/releases/ota/$LOS_DEVICE/$RECOVERYNAME.img

		# Cleanup!
		rm $HOME/releases/ota/$LOS_DEVICE/$RECOVERYNAME.img
	fi

	~/tasks/build/switch-keys.sh 2048

	echo "Signing process complete for $DEVICE!"
}

