using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class FinanceSymbolListItem extends WatchUi.Drawable {
    private var _symbol as FinanceSymbol?;

    function initialize(params as Lang.Dictionary) {
        Drawable.initialize(params);
    }

    function setFinanceSymbol(symbol as FinanceSymbol?) as Void {
        _symbol = symbol;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_symbol == null) {
            return;
        }
    }
}
