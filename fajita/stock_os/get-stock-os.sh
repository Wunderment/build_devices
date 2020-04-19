#!/bin/bash

# Don't do anything as OOS 10 has been release and we don't want to upgrade to it yet.
exit

cd ~/devices/fajita/stock_os
curl 'https://www.oneplus.com/xman/send-in-repair/find-phone-systems' -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundaryx6kJsIUK0M2Dzl5d' --data-binary $'------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="storeCode"\r\n\r\nus\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d\r\nContent-Disposition: form-data; name="phoneCode"\r\n\r\nPM1574156215016\r\n------WebKitFormBoundaryx6kJsIUK0M2Dzl5d--\r\n' > oneplus-6t.json
php ~/devices/dumpling/stock_os/get-oos.php
