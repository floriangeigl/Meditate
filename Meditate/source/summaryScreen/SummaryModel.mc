using Toybox.Time;
using Toybox.System;
using HrvAlgorithms.HrvTracking;
using Toybox.ActivityMonitor;
using Toybox.Time.Gregorian;

class SummaryModel {
    function initialize(activitySummary, rrActivity, hrvTracking) {
        me.elapsedTime = activitySummary.hrSummary.elapsedTimeSeconds; 
        me.maxHr = me.initializeHeartRate(activitySummary.hrSummary.maxHr);
        me.avgHr = me.initializeHeartRate(activitySummary.hrSummary.averageHr);
        me.minHr = me.initializeHeartRate(activitySummary.hrSummary.minHr);
        me.hrHistory = activitySummary.hrSummary.hrHistory;

        var rrSummary = rrActivity.getSummary();
        if (rrSummary != null) {
            me.maxRr = me.initializeHeartRate(rrSummary.maxRr);
            me.avgRr = me.initializeHeartRate(rrSummary.averageRr);
            me.minRr = me.initializeHeartRate(rrSummary.minRr);
            me.rrHistory = rrSummary.rrHistory;

            if (me.minRr == 9999999) {
                me.minRr = me.initializeHeartRate(0);
            }
        }

        // Initialize stress-related fields
        me.stressHistory = [];
        me.stressStart = null;
        me.stressEnd = null;
        me.stress = me.InvalidHeartRate;

        // Check if we have HRV-calculated stress summary
        if (activitySummary.stressSummary != null) {
            // Use HRV-calculated stress data
            me.stressHistory = activitySummary.stressSummary.stressHistory;
            me.stressStart = activitySummary.stressSummary.startStress;
            me.stressEnd = activitySummary.stressSummary.endStress;
            
            // Calculate average stress from history
            if (me.stressHistory != null && me.stressHistory.size() > 0) {
                me.stress = me.initializePercentageValue(Math.mean(me.stressHistory));
            }
        } else {
            // Fall back to device stress data
            initializeStressHistory(me.elapsedTime);
            me.stress = me.initializePercentageValue(me.stress);
        }

        if (activitySummary.hrvSummary != null) {
            me.hrvRmssd = me.initializeHeartRateVariability(activitySummary.hrvSummary.rmssd);
            me.hrvRmssdHistory = activitySummary.hrvSummary.rmssdHistory;
            me.hrvFirst5Min = me.initializeHeartRateVariability(activitySummary.hrvSummary.first5MinSdrr);
            me.hrvLast5Min = me.initializeHeartRateVariability(activitySummary.hrvSummary.last5MinSdrr);
            me.hrvPnn50 = me.initializePercentageValue(activitySummary.hrvSummary.pnn50);
            me.hrvPnn20 = me.initializePercentageValue(activitySummary.hrvSummary.pnn20);
        }
        
        me.hrvTracking = hrvTracking;
    }

    // Keep the existing initializeStressHistory method as a fallback
    function initializeStressHistory(elapsedTimeSeconds) {
        me.stressEnd = null;
        me.stressStart = null;
        me.stressHistory = [];
        var momentStartMediatation = null;

        // Get stress history iterator object
        var stressIterator = getStressHistoryIterator();
        if (stressIterator != null) {
            // Loop through all data
            var sample = stressIterator.next();

            // Get the stress data for the end of the session
            if (sample != null) {
                // Calculate the moment of the start of meditation session
                momentStartMediatation = Time.now().subtract(new Time.Duration(elapsedTimeSeconds));

                if (momentStartMediatation.greaterThan(sample.when)) {
                    return;
                }
                me.stressEnd = sample.data;
                me.stressHistory.add(sample.data);
            }

            // Go until the end of the iterator
            while (sample != null) {
                sample = stressIterator.next();

                // Get the stress score for the start of the session
                if (sample != null) {
                    // If the stress sample is within the meditation timeframe use it for the stress start metric
                    if (sample.when.greaterThan(momentStartMediatation)) {
                        me.stressStart = sample.data;
                        me.stressHistory.add(sample.data);
                    }
                }
            }
            me.stressHistory = stressHistory.reverse();
            me.stress = Math.mean(me.stressHistory);
        }
    }

    // Keep the rest of the methods unchanged
    function getStressHistoryIterator() {
        // Check device for SensorHistory compatibility
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            // Retrieve the stress history
            var stressHistory = Toybox.SensorHistory.getStressHistory(null);
            return stressHistory;
        }
        return null;
    }

    private function initializeHeartRate(heartRate) {
        if (heartRate == null || heartRate == 0) {
            return me.InvalidHeartRate;
        } else {
            return heartRate;
        }
    }
        
    private function initializePercentageValue(stressScore) {
        if (stressScore == null) {
            return me.InvalidHeartRate;
        } else {
            return Math.round(stressScore).format("%3.0f");
        }
    }
    
    private function initializeHeartRateVariability(hrv) {
        if (hrv == null) {
            return me.InvalidHeartRate;
        } else {
            return Math.round(hrv).format("%3.0f");
        }
    }
        
    private const InvalidHeartRate = "   --";
    
    var elapsedTime;
    var maxHr;
    var avgHr;
    var minHr;    
    var maxRr;
    var avgRr;
    var minRr;    
    var rrHistory;
    var stress;
    var stressStart;
    var stressEnd;
    var stressHistory;
    var hrvRmssd;
    var hrvRmssdHistory;
    var hrvFirst5Min;
    var hrvLast5Min;
    var hrvPnn50;
    var hrvPnn20;
    var hrvTracking;
    var hrHistory;
}