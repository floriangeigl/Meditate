using Toybox.Lang;
using Toybox.Test;

// the analytics queue and payload as pure functions; nothing is sent or stored
(:test)
class UsageStatsTests {
	(:test)
	static function queueKeepsTheNewestTen(logger) {
		var now = 1000000;
		var queue = null;
		for (var i = 0; i < 12; i++) {
			queue = UsageStats.add(queue, now + i, 60 + i);
		}
		// the two oldest dropped, oldest first
		return queue.size() == 20 && queue[0] == now + 2 && queue[1] == 62 && queue[18] == now + 11 && queue[19] == 71;
	}

	(:test)
	static function queueDropsOldAndCorruptEntries(logger) {
		var now = 1000000;
		var old = now - UsageStats.MaxAgeSec - 1;
		var edge = now - UsageStats.MaxAgeSec;
		var kept = UsageStats.prune([old, 60, edge, 61, "x", 62, now, null, now, 63, now], now);
		return (
			StorageSnapshot.deepEquals(kept, [edge, 61, now, 63]) &&
			UsageStats.prune(null, now).size() == 0 &&
			UsageStats.prune({ "id" => 1 }, now).size() == 0 &&
			StorageSnapshot.deepEquals(UsageStats.add({ "params" => {} }, now, 60), [now, 60])
		);
	}

	(:test)
	static function failedEventsGoBackBeforeNewerOnes(logger) {
		var now = 1000000;
		var merged = UsageStats.requeue([now - 20, 60, now - 10, 61], [now, 62], now);
		var full = [];
		for (var i = 0; i < 10; i++) {
			full.add(now + i);
			full.add(100 + i);
		}
		// a full queue keeps the newest, so the failed ones are what drops
		var capped = UsageStats.requeue([now - 20, 60], full, now + 9);
		return StorageSnapshot.deepEquals(merged, [now - 20, 60, now - 10, 61, now, 62]) && StorageSnapshot.deepEquals(capped, full);
	}

	(:test)
	static function payloadCarriesEachEventsOwnTime(logger) {
		var ts1 = 1790000000;
		var ts2 = 1790003600;
		var body = UsageStats.payload([ts1, 600, ts2, 1200], { "country_id" => "AT" });
		var events = body["events"];
		var first = events[0];
		var second = events[1];
		return (
			events.size() == 2 &&
			first["timestamp_micros"] instanceof Lang.Long &&
			first["timestamp_micros"].equals(1790000000000000l) &&
			second["timestamp_micros"].equals(1790003600000000l) &&
			first["params"]["timestamp_micros"] == null &&
			first["params"]["engagement_time_msec"] == 600000 &&
			second["params"]["engagement_time_msec"] == 1200000 &&
			first["params"]["session_id"] == ts1 &&
			body["user_location"]["country_id"].equals("AT") &&
			body["timestamp_micros"] == null
		);
	}

	(:test)
	static function payloadWithoutLocationHasNone(logger) {
		return !UsageStats.payload([1790000000, 60], null).hasKey("user_location");
	}

	(:test)
	static function locationFromIpapi(logger) {
		var full = UsageStats.locationFrom({ "ip" => "1.2.3.4", "country_code" => "AT", "region_code" => "9", "city" => "Vienna" });
		var countryOnly = UsageStats.locationFrom({ "country_code" => "AT" });
		return (
			full["country_id"].equals("AT") &&
			full["region_id"].equals("AT-9") &&
			full["city"].equals("Vienna") &&
			countryOnly.size() == 1 &&
			UsageStats.locationFrom({ "ip" => "1.2.3.4" }) == null &&
			UsageStats.locationFrom("rate limited") == null &&
			UsageStats.locationFrom(null) == null
		);
	}
}
