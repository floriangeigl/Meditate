using Toybox.Graphics as Gfx;
using HrvAlgorithms.HrvTracking;

module VibePattern {
	enum {
		LongPulsating = 1,
		LongContinuous = 2,
		LongAscending = 3,		
		ShortPulsating = 4,
		ShortContinuous = 5,
		ShortAscending = 6,
		MediumPulsating = 7,
		MediumContinuous = 8,
		MediumAscending = 9,
		ShorterAscending = 10,
		ShorterContinuous = 11,
		Blip = 12
	}
}

module ActivityType {
	enum {
		Meditating = 0,
		Yoga = 1
	}
}

class SessionModel {
	function initialize() {	
	}
		
	function fromDictionary(loadedSessionDictionary) {	
		me.time = loadedSessionDictionary["time"];
		me.color = loadedSessionDictionary["color"];
		me.vibePattern = loadedSessionDictionary["vibePattern"];
		me.activityType = loadedSessionDictionary["activityType"];		
		me.ensureActivityTypeExists();
		me.hrvTracking = loadedSessionDictionary["hrvTracking"];
		me.ensureHrvTrackingExists();	
		var serializedAlerts = loadedSessionDictionary["intervalAlerts"];		
		me.intervalAlerts = new IntervalAlerts();
		me.intervalAlerts.fromDictionary(serializedAlerts);
	}
	
	private function ensureHrvTrackingExists() {
		if (me.hrvTracking == null) {
			me.hrvTracking = GlobalSettings.loadHrvTracking();
		}	
	}
	
	private function ensureActivityTypeExists() {
		if (me.activityType == null) {
			me.activityType = GlobalSettings.loadActivityType();
		}	
	}
	
	function toDictionary() {	
		var serializedAlerts = me.intervalAlerts.toDictionary();
		me.ensureActivityTypeExists();
		return {
			"time" => me.time,
			"color" => me.color,
			"vibePattern" => me.vibePattern,
			"intervalAlerts" => serializedAlerts,
			"activityType" => me.activityType,
			"hrvTracking" => me.hrvTracking
		};
	}
		
	function reset(index, addingNew) {
		
		// Set 5,10,15,20,25 and 30min default session

		// 5min
		if (index == 0) {
			me.time = 5 * 60;
			me.color = Gfx.COLOR_GREEN;
		}

		// 10min
		if (index == 1) {
			me.time = 10 * 60;
			me.color = Gfx.COLOR_YELLOW;
		}

		// 15min
		if (index == 2) {
			me.time = 15 * 60;
			me.color = Gfx.COLOR_BLUE;
		}

		// 20min
		if (index == 3) {
			me.time = 20 * 60;
			me.color = Gfx.COLOR_GREEN;
		}

		// 25min
		if (index == 4) {
			me.time = 25 * 60;
			me.color = Gfx.COLOR_YELLOW;
		}

		// 30min
		if (index == 5) {
			me.time = 30 * 60;
			me.color = Gfx.COLOR_BLUE;
		}

		me.vibePattern = VibePattern.LongContinuous;		
		me.activityType = GlobalSettings.loadActivityType();
		me.hrvTracking = GlobalSettings.loadHrvTracking();
		me.intervalAlerts = new IntervalAlerts();
		me.intervalAlerts.reset();

		// Only add each 5min blip for sessions longer than 5min
		if (index>0 && !addingNew) {
			me.intervalAlerts.addNew();
		}
	}
	
	function copyNonNullFieldsFromSession(otherSession) {
    	if (otherSession.time != null) {
    		me.time = otherSession.time;
    	}
    	if (otherSession.color != null) {
    		me.color = otherSession.color;
    	}
    	if (otherSession.vibePattern != null) {
    		me.vibePattern = otherSession.vibePattern;
    	}
    	if (otherSession.intervalAlerts != null) {
    		me.intervalAlerts = otherSession.intervalAlerts;
    	}
    	if (otherSession.activityType != null) {
    		me.activityType = otherSession.activityType;
    	}
    	if (otherSession.hrvTracking != null) {
    		me.hrvTracking = otherSession.hrvTracking;
    	}
	}
		
	var time;
	var color;
	var vibePattern;
	var intervalAlerts;
	var activityType;
	var hrvTracking;
}