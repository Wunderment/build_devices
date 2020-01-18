<?php
// Pull the current stats from OnePlus.com and decode the json response.
$string = file_get_contents( 'https://www.oneplus.com/xman/send-in-repair/find-system-maintenance-info?storeCode=ca_en' );
$json = json_decode( $string, true );

// Loop thorugh the data.
foreach( $json['data']['elements'] as $field ) {
	// We're looking for machineType 7, which is the 5T and versionType 1, which is the current stable release.
	if( intval( $field['machineType'] ) === 7 && intval( $field['versionType'] ) === 1 ) {
		$current_release = $field;
	}
}

// Pull in the date value from the last time we checked.
$last_filename = '/home/WundermentOS/devices/dumpling/stock_os/last.stock.os.release.txt';
$last_release = intval( file_get_contents( $last_filename ) );

// Check if it's different from the value that OnePlus.com just returned to us.
if( $current_release[ 'versionModifyTime' ] !== $last_release ) {
	// If so, download the new release.
	echo 'New release found:' . PHP_EOL;

	$cmd = 'wget -O ~/devices/dumpling/stock_os/current-stock-os.zip ' . escapeshellarg( $current_release[ 'link' ] );

	exec( $cmd );

	// Update the last version file with the new date.
	file_put_contents( $last_filename, $current_release[ 'versionModifyTime' ] );

	// Extract the blobs.
	exec( '../blobs/extract-stock-os-blobs.sh' );

	// Extract the firmware.
	exec( '../firmware/extract-stock-os-firmware.sh' );
} else {
	echo 'No new release found.' . PHP_EOL;
}


