using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class FinanceTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new FinanceTrackerView(), new FinanceTrackerDelegate()];
    }

}
