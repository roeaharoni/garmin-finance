using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class DetailView extends WatchUi.View {
    private var _symbol as FinanceSymbol?;

    function initialize(symbol as FinanceSymbol) {
        View.initialize();
        _symbol = symbol;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();

        if (_symbol != null) {
            dc.drawText(width / 2, 20, Graphics.FONT_MEDIUM, _symbol.getName(), Graphics.TEXT_JUSTIFY_CENTER);

            if (_symbol.getValue() != null) {
                var valueStr = (_symbol.getValue() as Lang.Float).format("%.2f");
                dc.drawText(width / 2, 50, Graphics.FONT_LARGE, valueStr, Graphics.TEXT_JUSTIFY_CENTER);

                var change = _symbol.getChange();
                if (change != null) {
                    var chg = change as Lang.Float;
                    var changeStr = (chg > 0 ? "+" : "") + chg.format("%.2f");
                    var color = chg > 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
                    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 2, 90, Graphics.FONT_SMALL, changeStr, Graphics.TEXT_JUSTIFY_CENTER);
                }
            }

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 40, Graphics.FONT_TINY, "Graph coming soon", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
