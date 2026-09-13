using Toybox.FitContributor;
using Toybox.Math;

// the only place fit field ids, names and types live; ids are fit compatibility, never renumber.
// a null session makes every call a no-op
class FitFields {
	private static var Specs = {
		:minHr => ["min_hr", 0, FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_SESSION, "bpm"],
		:hrvSuccessive => ["hrv_successive", 6, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_RECORD, "ms"],
		:rmssd => ["hrv_rmssd", 7, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_SESSION, "ms"],
		:beat2beat => ["hrv_beat2beat_int", 8, FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_RECORD, "ms"],
		:sdrrFirst => ["hrv_sdrr_first5min", 9, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_SESSION, "ms"],
		:sdrrLast => ["hrv_sdrr_last5min", 10, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_SESSION, "ms"],
		:pnn50 => ["hrv_pnn50", 11, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_SESSION, "%"],
		:pnn20 => ["hrv_pnn20", 12, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_SESSION, "%"],
		:rmssdRolling => ["hrv_rmssd_rolling", 13, FitContributor.DATA_TYPE_FLOAT, FitContributor.MESG_TYPE_RECORD, "ms"],
		:hrFromBeat => ["hrv_hr", 16, FitContributor.DATA_TYPE_UINT16, FitContributor.MESG_TYPE_RECORD, "bpm"],
	};

	private var mSession;
	private var mFields;

	function initialize(session) {
		me.mSession = session;
		me.mFields = {};
	}

	function create(ids) {
		if (me.mSession == null) {
			return;
		}
		for (var i = 0; i < ids.size(); i++) {
			var spec = FitFields.Specs[ids[i]];
			me.mFields[ids[i]] = me.mSession.createField(spec[0], spec[1], spec[2], {
				:mesgType => spec[3],
				:units => spec[4],
			});
		}
	}

	// null values and ids that were not created are ignored; uint16 fields get a rounded number
	function set(id, value) {
		var field = me.mFields[id];
		if (field == null || value == null) {
			return;
		}
		if (FitFields.Specs[id][2] == FitContributor.DATA_TYPE_UINT16) {
			value = Math.round(value).toNumber();
		}
		field.setData(value);
	}
}
