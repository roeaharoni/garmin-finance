using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;

class FinanceTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        registerTemporalEvent();
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new FinanceTrackerView();
        return [view, new FinanceTrackerDelegate(view)];
    }

    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new FinanceWidget()];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

    function onBackgroundData(data as Application.PersistableType) as Void {
        // The glance reads cached prices straight from Storage, so the data
        // payload isn't load-bearing here. Just nudge a UI refresh.
        WatchUi.requestUpdate();
    }

    // Registers a repeating background fetch based on the refreshInterval
    // setting. Only (re)registers when nothing is scheduled or the interval
    // changed, so we don't reset the schedule on every launch.
    private function registerTemporalEvent() as Void {
        var minutes = mapIntervalToMinutes(readRefreshInterval());

        var registeredAt = Background.getTemporalEventRegisteredTime();
        var lastMinutes = null;
        try {
            lastMinutes = Storage.getValue("registeredInterval");
        } catch (ex) {
            lastMinutes = null;
        }

        var needsRegister = (registeredAt == null);
        if (!(lastMinutes != null && lastMinutes instanceof Lang.Number && (lastMinutes as Lang.Number) == minutes)) {
            needsRegister = true;
        }

        if (needsRegister) {
            // refreshInterval options map to 5/15/30/60 min, all >= the 5-minute
            // Connect IQ minimum, so this Duration is always valid.
            Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
            try {
                Storage.setValue("registeredInterval", minutes);
            } catch (ex) {
            }
        }
    }

    private function readRefreshInterval() as Lang.Number {
        try {
            var val = Application.Properties.getValue("refreshInterval");
            if (val != null && val instanceof Lang.Number) {
                return val as Lang.Number;
            }
        } catch (ex) {
        }
        return 1;
    }

    private function mapIntervalToMinutes(idx as Lang.Number) as Lang.Number {
        if (idx == 0) { return 5; }
        if (idx == 2) { return 30; }
        if (idx == 3) { return 60; }
        return 15; // idx == 1 (default)
    }

}
