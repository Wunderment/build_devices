<?php
// Pull the current stats from OnePlus.com and decode the json response.
$string = file_get_contents( 'oneplus.json' );
$json = json_decode( $string, true );

// Loop thorugh the data.
foreach( $json['data'] as $field ) {
	// We're looking for versionType 1, which is the current stable release.
	if( intval( $field['versionType'] ) === 1 ) {
		$current_release = $field;
	}
}

// Pull in the date value from the last time we checked.
$last_filename = '/home/WundermentOS/devices/fajita/stock_os/last.stock.os.release.txt';
$last_release = intval( file_get_contents( $last_filename ) );

// Check if it's different from the value that OnePlus.com just returned to us.
if( $current_release[ 'versionReleaseTime' ] !== $last_release ) {
	// If so, download the new release.
	echo 'New release found: ' . $current_release[ 'versionNo' ] . PHP_EOL;

	$cmd = 'wget -O ~/devices/fajita/stock_os/current-stock-os.zip ' . escapeshellarg( $current_release[ 'versionLink' ] );

	exec( $cmd );

	// Update the last version file with the new date.
	file_put_contents( $last_filename, $current_release[ 'versionReleaseTime' ] );

	// Extract the blobs.
	exec( '../blobs/extract-stock-os-blobs.sh' );

	// Extract the firmware.
	exec( '../firmware/extract-stock-os-firmware.sh' );
} else {
	echo 'No new release found.' . PHP_EOL;
}


