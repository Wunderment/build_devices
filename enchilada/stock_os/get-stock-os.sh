#!/bin/bash

# Get the device name from the parent directory of this script's real path.
DEVICE=$(basename $(dirname $(dirname $(realpath $0))))

# Use curl to download the current info from OnePlus for this device.
curl 'https://www.oneplus.com/xman/send-in-repair/find-phone-systems' -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundaryx6kJsIUK0M2Dzl5d' --data-binary $'------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="storeCode"\r\n\r\nuk\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="phoneCode"\r\n\r\nPM1574156235282\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d--\r\n' > oneplus.json

# Parse the json file and download/process if neccessary.
php ~/devices/$DEVICE/stock_os/get-oos.php
