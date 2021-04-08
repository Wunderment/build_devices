#!/bin/bash

VENDOR=oneplus

function build_wos {
	DFSFILE=~/android/lineage-$LOS_BUILD_VERSION/kernel/$VENDOR/sm8250/arch/arm64/configs/vendor/kona-perf_defconfig
	# For this device we need to remove a the debugging file system for our user build.
	# First check to see if we've already done it.
	if ! grep "CONFIG_DEBUG_FS=y" $DFSFILE > /dev/null; then
		sed -i 's/^CONFIG_DEBUG_FS=y/CONFIG_DEBUG_FS=n/' $DFSFILE
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

