using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

class FinanceTrackerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Lang.Boolean {
        return false;
    }

    function onSelect() as Lang.Boolean {
        return true;
    }

    function onBack() as Lang.Boolean {
        return false;
    }
}
