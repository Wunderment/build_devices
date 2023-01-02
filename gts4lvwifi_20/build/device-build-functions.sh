#!/bin/bash

### Global variables ###

# Tell the build system which img file to use as the recovery img.
export LOS_RECOVERY_IMG=recovery

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

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

