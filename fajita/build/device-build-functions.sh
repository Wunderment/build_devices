#!/bin/bash

function build_wos {
	# For Fajita we need to add the prebuilt vendor.img to the build system, do that now.
	# First check to see if we've already one it.
	if ! grep vendor.img ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk; then
		echo "" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		
		# We're using the sparse image here otherwise LOS will try and use the SEPolicy files from the ext
		# version and throw policy errors as they are from OOS.
		echo "BOARD_PREBUILT_VENDORIMAGE := /home/WundermentOS/devices/fajita/blobs/images_sparse/vendor.img" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		
		echo "AB_OTA_PARTITIONS += vendor" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_AVB_ALGORITHM := SHA256_RSA2048" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
		echo "BOARD_AVB_KEY_PATH := /home/WundermentOS/.android-certs/releasekey.x509.pem" > ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/fajita/BoardConfig.mk
	fi

	# We need to remove the flag that disables the partition verification during boot if it hasn't been already
	# in the sdm845 common code.
	if ! grep "#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS" ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/sdm845/BoardConfigCommon.mk; then
		sed -i 's/^BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/#BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flag 2/' ~/android/lineage-$LOS_BUILD_VERSION/device/oneplus/sdm845-common/BoardConfigCommon.mk
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
	sign_wos_target_apks_vendor_prebuilt

	# Then generate the OTA as usual.
	sign_wos_target_files

	# Create the md5 checksum file for the release
	echo "Create the md5 checksum..."
	md5sum ~/releases/ota/$PKGNAME.zip > ~/releases/ota/$PKGNAME.zip.md5sum

	# Grab a copy of the build.prop file
	echo "Store the build.prop file..."
	cp $OUT/system/build.prop ~/releases/ota/$PKGNAME.zip.prop

	# Cleanup
	echo "Store signed target files for future incremental updates..."
	cp signed-target_files.zip ~/releases/signed_files/signed-target_files-$DEVICE-$TODAY.zip

	return

	# !!!!!!!! EVERYTHING FROM HERE DOWN NEEDS TO BE REPLACED FOR THE PAYLOAD.BIN IN FAJITA !!!!!!!!

	# Add RADIO and firmware to the update package.
	echo "Add RADIO and FIRMWARE to the update package..."
	cd ~/devices/$DEVICE/firmware/update
	zip -ur ~/releases/ota/$PKGNAME.zip RADIO
	zip -ur ~/releases/ota/$PKGNAME.zip firmware-update

	# Unzip the stock updater script.
	unzip -o ~/releases/ota/$PKGNAME.zip META-INF/com/google/android/updater-script

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
	zip -ur ~/releases/ota/$PKGNAME.zip META-INF/com/google/android/updater-script
	rm ~/devices/$DEVICE/firmware/update/META-INF/com/google/android/updater-script

	echo "Add recovery to the release package..."

	# Get the recovery image from the signed target files so we have the right signing keys in it.
	# Use -j to drop the path as we don't need it.
	cd ~/android/lineage
	rm -f ~/android/lineage/recovery.img
	unzip -j signed-target_files.zip IMAGES/recovery.img

	# Add in Lineage recovery.  Use -j to drop the path as the img should be in the root of the zip.
	zip -urj ~/releases/ota/$PKGNAME.zip ~/android/lineage/recovery.img

	# Clean up.
	rm -f ~/android/lineage/recovery.img

	# Re-sign the release zip after we've updated it.
	echo "Resign the release package..."
	cd ~/releases/ota
	signapk -w --min-sdk-version 28 ~/.android-certs/releasekey.x509.pem ~/.android-certs/releasekey.pk8 $PKGNAME.zip $PKGNAME-resigned.zip
	rm $PKGNAME.zip
	mv $PKGNAME-resigned.zip $PKGNAME.zip

	# Take us back to the root.
	cd ~/android/lineage

	# Create the md5 checksum file for the release
	echo "Create the md5 checksum..."
	md5sum ~/releases/ota/$PKGNAME.zip > ~/releases/ota/$PKGNAME.zip.md5sum

	# Grab a copy of the build.prop file
	echo "Store the build.prop file..."
	cp $OUT/system/build.prop ~/releases/ota/$PKGNAME.zip.prop

	# Cleanup
	echo "Store signed target files for future incremental updates..."
	cp signed-target_files.zip ~/releases/signed_files/signed-target_files-$DEVICE-$TODAY.zip

	echo "Signing process complete for $DEVICE!"
}

