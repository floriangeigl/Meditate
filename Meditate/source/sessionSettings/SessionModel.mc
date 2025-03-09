using Toybox.Graphics as Gfx;
using HrvAlgorithms.HrvTracking;

module VibePattern {
	enum {
		NoNotification = 0,
		Blip = 1,
		ShorterAscending = 2,
		ShorterContinuous = 3,
		ShortAscending = 4,
		ShortDescending = 5,
		ShortContinuous = 6,	
		ShortPulsating = 7,
		ShortSound = 8,
		MediumAscending = 9,
		MediumDescending = 10,
		MediumContinuous = 11,
		MediumPulsating = 12,
		LongAscending = 13,
		LongDescending = 14,
		LongContinuous = 15,
		LongPulsating = 16,	
		LongSound = 17
	}
}

module ActivityType {
	enum {
		Meditating = 0,
		Yoga = 1,
		Breathing = 2
	}
}

class SessionModel {
	var time;
	var color;
	var name;
	var vibePattern;
	var intervalAlerts;
	var key;
	private var activityType;
	private var hrvTracking;
	
	function initialize() {
		me.key = null;
		me.name = null;
		me.time = null;
		me.color = null;
		me.vibePattern = null;
		me.intervalAlerts = null;
		me.activityType = null;
		me.hrvTracking = null;
	}
		
	function fromDictionary(loadedSessionDictionary) {	
		me.time = loadedSessionDictionary["time"];
		me.color = loadedSessionDictionary["color"];
		me.name = loadedSessionDictionary["name"];
		me.vibePattern = loadedSessionDictionary["vibePattern"];
		me.activityType = loadedSessionDictionary["activityType"];
		me.key = loadedSessionDictionary["key"];
		me.hrvTracking = loadedSessionDictionary["hrvTracking"];
		var serializedAlerts = loadedSessionDictionary["intervalAlerts"];
		me.intervalAlerts = new IntervalAlerts();
		me.intervalAlerts.fromArray(serializedAlerts);
	}

	function getActivityType() {
		return me.activityType == null ? GlobalSettings.loadActivityType() : me.activityType;
	}
	function getHrvTracking() {
		return me.hrvTracking == null ? GlobalSettings.loadHrvTracking() : me.hrvTracking;
	}
	
	function toDictionary() {	
		var serializedAlerts = me.intervalAlerts.toArray();
		return {
			"time" => me.time,
			"color" => me.color,
			"name" => me.name,
			"key" => me.key,
			"vibePattern" => me.vibePattern,
			"intervalAlerts" => serializedAlerts,
			"activityType" => me.activityType,
			"hrvTracking" => me.hrvTracking,
		};
	}
	
	function copyNonNullFieldsFromSession(otherSession) {
    	if (otherSession.time != null) {
    		me.time = otherSession.time;
    	}
    	if (otherSession.color != null) {
    		me.color = otherSession.color;
    	}
		if (otherSession.name != null) {
    		me.name = otherSession.name;
    	}
		if (otherSession.key != null) {
    		me.key = otherSession.key;
    	}
    	if (otherSession.vibePattern != null) {
    		me.vibePattern = otherSession.vibePattern;
    	}
    	if (otherSession.intervalAlerts != null) {
    		me.intervalAlerts = otherSession.intervalAlerts;
    	}
    	if (otherSession.getActivityType() != null) {
    		me.activityType = otherSession.getActivityType();
    	}
    	if (otherSession.getHrvTracking() != null) {
    		me.hrvTracking = otherSession.getHrvTracking();
    	}
	}
}