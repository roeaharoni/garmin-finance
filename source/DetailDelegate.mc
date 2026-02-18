using Toybox.WatchUi;
using Toybox.Lang;

class DetailDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DetailView;

    function initialize(view as DetailView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Lang.Boolean {
        _view.toggleMode();
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.toggleMode();
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
