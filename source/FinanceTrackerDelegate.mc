using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

class FinanceTrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as FinanceTrackerView;

    function initialize(view as FinanceTrackerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Lang.Boolean {
        _view.moveSelectionDown();
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.moveSelectionUp();
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Lang.Boolean {
        var symbol = _view.getSelectedSymbol();
        var fetcher = _view.getFetcher();
        if (symbol != null && fetcher != null) {
            var detailView = new DetailView(symbol as FinanceSymbol, fetcher as DataFetcher);
            var detailDelegate = new DetailDelegate(detailView);
            WatchUi.pushView(detailView, detailDelegate, WatchUi.SLIDE_LEFT);
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        return false;
    }
}
