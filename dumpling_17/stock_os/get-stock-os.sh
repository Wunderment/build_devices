#!/bin/bash

cd ~/devices/dumpling_17/stock_os
curl 'https://www.oneplus.com/xman/send-in-repair/find-phone-systems' -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundaryx6kJsIUK0M2Dzl5d' --data-binary $'------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="storeCode"\r\n\r\nus\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="phoneCode"\r\n\r\nPM1574156155944\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d--\r\n' > oneplus-5t.json
php ~/devices/dumpling_17/stock_os/get-oos.php
