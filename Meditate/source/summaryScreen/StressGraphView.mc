using Toybox.Math;
using Toybox.System;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity as Activity;
using Toybox.SensorHistory as SensorHistory;
using Toybox.ActivityMonitor as ActivityMonitor;

class StressGraphView extends GraphView {
	function initialize(summaryModel) {
		GraphView.initialize(summaryModel.stHistory, summaryModel.elapsedTime, Rez.Strings.SummaryStress, 0, 100);
	}
}
