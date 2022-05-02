#!/bin/bash

function build_wos {
	common_build_wos
}

function sign_wos {
	echo "Start signing process for $DEVICE..."

	# Move in to the build directory
	cd ~/android/lineage-$LOS_BUILD_VERSION

	# Setup the build environment
	source build/envsetup.sh
	croot

	# Call the common tasks of creating the target files package from the global build functions.
	sign_wos_target_package

	# Create the md5 checksum file for the release
	echo "Create the md5 checksum..."
	md5sum ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip > ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip.md5sum

	# Grab a copy of the build.prop file
	echo "Store the build.prop file..."
	cp $OUT/system/build.prop ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip.prop

	# Cleanup
	echo "Store signed target files for future incremental updates..."
	cp signed-target_files.zip ~/releases/signed_files/$LOS_DEVICE/signed-target_files-$LOS_DEVICE-$TODAY.zip

	echo "Signing process complete for $DEVICE!"
}

