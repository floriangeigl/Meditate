using Toybox.Lang;
using Toybox.System;

class Utils {
	static function MonkeyVersionAtLeast(version) {
		var device_version = System.getDeviceSettings().monkeyVersion;
		device_version = device_version[0] * 10000 + device_version[1] * 100 + device_version[2];
		var compare_version = version[0] * 10000 + version[1] * 100 + version[2];
		return device_version >= compare_version ? true : false;
	}
}
