using Toybox.FitContributor;
using Toybox.Math;
using Toybox.Application as App;

class StressMonitor {
	function initialize(activitySession) {	
		me.mHrvTracking = GlobalSettings.loadHrvTracking();
		if (me.mHrvTracking == HrvTracking.OnDetailed) {		
			me.mHrPeaksWindow10DataField = StressMonitor.createHrPeaksWindow10DataField(activitySession);
			
			//TODO - delete			
			me.mMaxMinHrvWindowDataField = StressMonitor.createMaxMinHrvWindowDataField(activitySession);
			me.mStressMedianDataField = createStressMedianDataField(activitySession);
			me.mNoStressDataField = StressMonitor.createNoStressDataField(activitySession);
			me.mLowStressDataField = StressMonitor.createLowStressDataField(activitySession);
			me.mHighStressDataField = StressMonitor.createHighStressDataField(activitySession);
		}
		if (me.mHrvTracking != HrvTracking.Off) {		
			me.mHrPeaksAverageDataField = StressMonitor.createHrPeaksAverageDataField(activitySession);
		}		
		
		me.mHrPeaksWindow10 = new HrPeaksWindow(10);
		me.mMaxMinHrvWindow10 = new MaxMinHrvWindow(10);
		me.mMaxMinHrvWindowStats = new MaxMinHrvWindowStats();				
	}
					
	private var mHrvTracking;
	
	private var mHrPeaksWindow10;	
	private var mMaxMinHrvWindow10;
	private var mMaxMinHrvWindowStats;
	
	private var mHrPeaksWindow10DataField;
	private var mMaxMinHrvWindowDataField;		
	private var mStressMedianDataField;
	private var mNoStressDataField;
	private var mLowStressDataField;
	private var mHighStressDataField;
	private var mHrPeaksAverageDataField;
	
	private static const MaxMinHrvWindowDataFieldId = 5;		
	private static const StressMedianDataFieldId = 1;
	private static const NoStressDataFieldId = 2;
	private static const LowStressDataFieldId = 3;
	private static const HighStressDataFieldId = 4;
	private static const HrPeaksWindow10DataFieldId = 15;
	private static const HrPeaksAverageDataFieldId = 17;
	
	private static function createStressMedianDataField(activitySession) {
		return activitySession.createField(
            "stress_m",
            StressMedianDataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms x10"}
        );
	}
	
	private static function createHrPeaksAverageDataField(activitySession) {
		return activitySession.createField(
            "stress_hrpa",
            HrPeaksAverageDataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%"}
        );
	}
	
	private static function createNoStressDataField(activitySession) {
		return activitySession.createField(
            "stress_no",
            NoStressDataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%"}
        );
	}
	
	private static function createLowStressDataField(activitySession) {
		return activitySession.createField(
            "stress_low",
            LowStressDataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%"}
        );
	}
	
	private static function createHighStressDataField(activitySession) {
		return activitySession.createField(
            "stress_high",
            HighStressDataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%"}
        );
	}
	
	private static function createMaxMinHrvWindowDataField(activitySession) {
		return activitySession.createField(
            "hrv_mmhrv",
            MaxMinHrvWindowDataFieldId,
            FitContributor.DATA_TYPE_UINT16,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms"}
        );
	}	

	private static function createHrPeaksWindow10DataField(activitySession) {
		return activitySession.createField(
            "stress_hrp",
            HrPeaksWindow10DataFieldId,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"bpm"}
        );
	}
	
	function addOneSecBeatToBeatIntervals(beatToBeatIntervals) {
		me.mMaxMinHrvWindow10.addOneSecBeatToBeatIntervals(beatToBeatIntervals);		
		me.calculateMaxMinHrvWindow10();
		
		me.mHrPeaksWindow10.addOneSecBeatToBeatIntervals(beatToBeatIntervals);
		me.calculateHrPeaksWindow10();
	}
		
	private function calculateMaxMinHrvWindow10() {
		var result = me.mMaxMinHrvWindow10.calculate();
		if (result != null) {
			if (me.mMaxMinHrvWindowDataField != null) {
				me.mMaxMinHrvWindowDataField.setData(result);
			}
			me.mMaxMinHrvWindowStats.addMaxMinHrvWindow(result);
		}
	}
	
	private function calculateHrPeaksWindow10() {
		var result = me.mHrPeaksWindow10.calculateCurrentPeak();
		if (result != null) {
			if (me.mHrPeaksWindow10DataField != null) {
				me.mHrPeaksWindow10DataField.setData(result);
			}
		}
	}
		
	public function calculateStressStats() {
		if (me.mHrvTracking == HrvTracking.Off) {
			return null;
		}
		var stressStats = me.mMaxMinHrvWindowStats.calculate();		
		if (stressStats.median != null) {
			if (me.mHrvTracking == HrvTracking.OnDetailed) {
				me.mStressMedianDataField.setData(stressStats.median);
			}
			me.mNoStressDataField.setData(stressStats.noStress);
			me.mLowStressDataField.setData(stressStats.lowStress);
			me.mHighStressDataField.setData(stressStats.highStress);
		}

		return stressStats;
	}	
	
	public function calculateStress(minHr) {
		if (me.mHrvTracking == HrvTracking.OnDetailed) {
			var averageStress = me.mHrPeaksWindow10.calculateAverageStress(minHr);
			me.mHrPeaksAverageDataField.setData(averageStress);
			return averageStress;
		}
		else {
			return null;
		}
	}
}