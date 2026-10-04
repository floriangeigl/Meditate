using Toybox.Application as App;
using Toybox.Lang;
using Toybox.Test;
using Toybox.Time;

// the analytics queue and payload as pure functions; nothing is sent, storage is restored
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
		var body = UsageStats.payload([ts1, 600, ts2, 1200], "203.0.113.0");
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
			body["ip_override"].equals("203.0.113.0") &&
			!body.hasKey("user_location") &&
			body["timestamp_micros"] == null
		);
	}

	// a queue of events too old to send is dropped at launch instead of looked up on every launch
	(:test)
	static function launchDropsAQueueGaWouldNotTake(logger) {
		var savedQueue = App.Storage.getValue(UsageStats.QueueKey);
		var savedOld = App.Storage.getValue(UsageStats.OldQueueKey);
		try {
			var stale = Time.now().value() - UsageStats.MaxAgeSec - 60;
			App.Storage.setValue(UsageStats.QueueKey, [stale, 600, stale + 1, 300]);
			UsageStats.flushOnStartup();
			var dropped = App.Storage.getValue(UsageStats.QueueKey) == null;
			App.Storage.setValue(UsageStats.QueueKey, { "corrupt" => true });
			UsageStats.flushOnStartup();
			var corruptDropped = App.Storage.getValue(UsageStats.QueueKey) == null;
			StorageSnapshot.put(UsageStats.QueueKey, savedQueue);
			StorageSnapshot.put(UsageStats.OldQueueKey, savedOld);
			return dropped && corruptDropped;
		} catch (ex) {
			StorageSnapshot.put(UsageStats.QueueKey, savedQueue);
			StorageSnapshot.put(UsageStats.OldQueueKey, savedOld);
			throw ex;
		}
	}

	(:test)
	static function payloadWithoutIpHasNone(logger) {
		return !UsageStats.payload([1790000000, 60], null).hasKey("ip_override");
	}

	(:test)
	static function ipIsAnonymisedBeforeItLeaves(logger) {
		return (
			UsageStats.anonymize("203.0.113.42").equals("203.0.113.0") &&
			UsageStats.anonymize("2001:db8:1234:5678:9abc:def0:1:2").equals("2001:db8:1234::") &&
			UsageStats.anonymize("2001:db8:1234::1").equals("2001:db8:1234::") &&
			UsageStats.anonymize("2001:db8::1").equals("2001:db8::") &&
			UsageStats.anonymize("fe80::").equals("fe80::") &&
			UsageStats.anonymize("::1").equals("::") &&
			UsageStats.anonymize("1.2.3") == null &&
			UsageStats.anonymize("not an ip") == null &&
			UsageStats.anonymize("") == null &&
			UsageStats.ipFrom({ "ip" => "203.0.113.42" }).equals("203.0.113.0") &&
			UsageStats.ipFrom({ "ip" => 42 }) == null &&
			UsageStats.ipFrom({ "error" => true }) == null &&
			UsageStats.ipFrom("<html>challenge</html>") == null &&
			UsageStats.ipFrom(null) == null
		);
	}
}