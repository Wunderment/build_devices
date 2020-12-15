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

