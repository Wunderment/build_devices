#!/bin/bash

### Global variables ###

# Tell the build system which img file to use as the recovery img.
export LOS_RECOVERY_IMG=recovery

### Local variables ###

# Set the vendor for this device.
VENDOR=oneplus

function build_wos {
	# This change has been removed from Lineage, so let's comment it out and delete it latter when we're sure
	# it won't come back.
	# IT'S BAAAAACCKKKK!
	SEFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/msm8998-common/sepolicy/vendor/hal_camera_default.te
	# For this device we need to remove a debugging permission for our user build.
	# First check to see if we've already done it.
	if ! grep "#get_prop(hal_camera_default, vendor_sensors_dbg_prop)" $SEFILE > /dev/null; then
		sed -i 's/^get_prop(hal_camera_default, vendor_sensors_dbg_prop)/#get_prop(hal_camera_default, vendor_sensors_dbg_prop)/' $SEFILE
	fi

	BCCFILE=~/android/lineage-$LOS_BUILD_VERSION/device/$VENDOR/msm8998-common/BoardConfigCommon.mk
	# For this device we need to disable AVB in the makefile so when we sign it doesn't throw an error.
	# First check to see if we've already done it.
	if ! grep "BOARD_AVB_ENABLE := false" $BCCFILE > /dev/null; then
		sed -i 's/^# SELinux/# Verified Boot\nBOARD_AVB_ENABLE := false\n\n# SELinux/' $BCCFILE
	fi

	# For this device we need to set the BOARD_BUILDS_VENDORIMAGE flag so the signing works correctly.
	# First check to see if we've already done it.
	if ! grep "BOARD_BUILDS_VENDORIMAGE := true" $BCCFILE > /dev/null; then
		sed -i 's/^# SELinux/# Vendor Image\BOARD_BUILDS_VENDORIMAGE := true\n\n# SELinux/' $BCCFILE
	fi

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

	# Add RADIO and firmware to the update package.
	echo "Add RADIO and FIRMWARE to the update package..."
	cd ~/devices/$DEVICE/firmware/update
	zip -ur ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip RADIO
	zip -ur ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip firmware-update

	# Unzip the stock updater script.
	unzip -o ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip META-INF/com/google/android/updater-script

	# Cut the orginal upate script in two at the firmware check.
	cd ~/devices/$DEVICE/firmware/update/META-INF/com/google/android
	csplit updater-script /oneplus.verify_modem/
	mv xx00 updater-script-top
	mv xx01 updater-temp

	# Get rid of the firmware check from the second file.
	tail -n +2 updater-temp > updater-script-bottom

	# Clean up some of our temporary files.
	rm updater-temp
	rm updater-script

	# Combine the old and new scripts together.
	cat updater-script-top ~/devices/$DEVICE/firmware/update/new-updater-script ~/tasks/build/los-recovery-updater-script updater-script-bottom > updater-script

	# Finish cleaning up the temporary files.
	rm updater-script-top
	rm updater-script-bottom

	# Now add the new updater script to the release pacakage and get rid of the temporary copy.
	cd ~/devices/$DEVICE/firmware/update
	zip -ur ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip META-INF/com/google/android/updater-script
	rm ~/devices/$DEVICE/firmware/update/META-INF/com/google/android/updater-script

	echo "Add recovery to the release package..."

	# Get the recovery image from the signed target files so we have the right signing keys in it.
	# Use -j to drop the path as we don't need it.
	cd ~/android/lineage-$LOS_BUILD_VERSION
	rm -f ~/android/lineage-$LOS_BUILD_VERSION/recovery.img
	unzip -j signed-target_files.zip IMAGES/recovery.img

	# Add in Lineage recovery.  Use -j to drop the path as the img should be in the root of the zip.
	zip -urj ~/releases/ota/$LOS_DEVICE/$PKGNAME.zip ~/android/lineage-$LOS_BUILD_VERSION/recovery.img

	# Clean up.
	rm -f ~/android/lineage-$LOS_BUILD_VERSION/recovery.img

	# Re-sign the release zip after we've updated it.
	echo "Resign the release package..."
	cd ~/releases/ota/$LOS_DEVICE
	signapk -w --min-sdk-version 28 ~/.android-certs/releasekey.x509.pem ~/.android-certs/releasekey.pk8 $PKGNAME.zip $PKGNAME-resigned.zip
	rm $PKGNAME.zip
	mv $PKGNAME-resigned.zip $PKGNAME.zip

	# Take us back to the root.
	cd ~/android/lineage-$LOS_BUILD_VERSION

	# Create the MD5 checksum file, copy the build prop file and cleanup the target_files zip.
	checksum_buildprop_cleanup

	echo "Signing process complete for $DEVICE!"
}

