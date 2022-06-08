#!/bin/bash

# Configuration variables for this device.
VENDOR=oneplus
DELETE_IMAGES="system.img system_ext.img vbmeta.img vbmeta_system.img boot.img dtbo.img product.img vendor.img my_bigball.img my_carrier.img my_company.img my_engineering.img my_heytap.img my_manifest.img my_preload.img my_product.img my_region.img my_stock.img"
PREBUILT_VENDOR=false

source ~/tasks/firmware/extract-stock-os-firmware-common.sh
