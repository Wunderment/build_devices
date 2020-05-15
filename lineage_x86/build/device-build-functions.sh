#!/bin/bash

function build_wos {
	# Building the x86 image is a little different than a standard device, so don't call
	# the common build function and instead use the following custom build process.
	echo "Starting build process for $DEVICE..."

	# Move in to the build directory
	cd ~/android/lineage-$LOS_BUILD_VERSION

	# Setup the build environment
	source build/envsetup.sh
	croot

	lunch $DEVICE-user
	mka
}

function sign_wos {
	echo "Start signing process for $DEVICE..."

	# Don't bother signing the package as it's never going to be deployed to anything but
	# the emulator.

	echo "Signing process complete for $DEVICE!"
}

