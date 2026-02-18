using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class DetailView extends WatchUi.View {
    private var _symbol as FinanceSymbol;
    private var _fetcher as DataFetcher;
    private var _mode as Lang.Number = 0; // 0 = daily, 1 = yearly
    private var _historyPoints as Lang.Array?;
    private var _historyLoading as Lang.Boolean = false;

    function initialize(symbol as FinanceSymbol, fetcher as DataFetcher) {
        View.initialize();
        _symbol = symbol;
        _fetcher = fetcher;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        fetchHistoryData();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();

        // Symbol name
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 8, Graphics.FONT_MEDIUM, _symbol.getName(), Graphics.TEXT_JUSTIFY_CENTER);

        // Current price
        if (_symbol.getValue() != null) {
            var val = _symbol.getValue() as Lang.Float;
            dc.drawText(width / 2, 38, Graphics.FONT_LARGE, val.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER);

            // Change + percentage
            var change = _symbol.getChange();
            if (change != null) {
                var chg = change as Lang.Float;
                var changeStr = (chg > 0 ? "+" : "") + chg.format("%.2f");
                var pct = _symbol.getChangePercent();
                if (pct != null) {
                    var pctVal = pct as Lang.Float;
                    changeStr += " (" + (pctVal > 0 ? "+" : "") + pctVal.format("%.1f") + "%)";
                }
                var color = chg > 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, 72, Graphics.FONT_TINY, changeStr, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Mode-specific data section
        if (_mode == 0) {
            drawDailyData(dc, width);
        } else {
            drawYearlyData(dc, width);
        }

        // Chart area
        var chartX = 15;
        var chartY = 132;
        var chartW = width - 30;
        var chartH = 65;

        if (_historyLoading) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, chartY + chartH / 2 - 8, Graphics.FONT_XTINY, "Loading chart...", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_historyPoints != null && (_historyPoints as Lang.Array).size() >= 2) {
            UIHelpers.drawLineChart(dc, _historyPoints as Lang.Array, chartX, chartY, chartW, chartH);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, chartY + chartH / 2 - 8, Graphics.FONT_XTINY, "No chart data", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Bottom info: source + time + mode indicator
        drawBottomInfo(dc, width, height);
    }

    private function drawDailyData(dc as Graphics.Dc, width as Lang.Number) as Void {
        var leftCol = 15;
        var rightCol = width / 2 + 10;
        var y1 = 95;
        var y2 = 111;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        var openVal = _symbol.getOpen();
        var highVal = _symbol.getHigh();
        var lowVal = _symbol.getLow();
        var closeVal = _symbol.getValue();

        dc.drawText(leftCol, y1, Graphics.FONT_XTINY,
            "O: " + formatVal(openVal), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(rightCol, y1, Graphics.FONT_XTINY,
            "H: " + formatVal(highVal), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(leftCol, y2, Graphics.FONT_XTINY,
            "L: " + formatVal(lowVal), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(rightCol, y2, Graphics.FONT_XTINY,
            "C: " + formatVal(closeVal), Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawYearlyData(dc as Graphics.Dc, width as Lang.Number) as Void {
        var leftMargin = 15;
        var y1 = 95;
        var y2 = 111;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        var ftwHigh = _symbol.getFiftyTwoWeekHigh();
        var ftwLow = _symbol.getFiftyTwoWeekLow();

        dc.drawText(leftMargin, y1, Graphics.FONT_XTINY,
            "52W High: " + formatVal(ftwHigh), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(leftMargin, y2, Graphics.FONT_XTINY,
            "52W Low:  " + formatVal(ftwLow), Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawBottomInfo(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var bottomY = height - 20;

        // Provider + time on left
        var infoStr = _fetcher.getProviderName();
        var lastUpdated = _symbol.getLastUpdated();
        if (lastUpdated != null) {
            var syncMoment = new Time.Moment(lastUpdated as Lang.Number);
            var info = Gregorian.info(syncMoment, Time.FORMAT_SHORT);
            var hourNum = info.hour as Lang.Number;
            var minNum = info.min as Lang.Number;
            infoStr += " " + hourNum.format("%02d") + ":" + minNum.format("%02d");
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(15, bottomY, Graphics.FONT_XTINY, infoStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Mode indicator on right
        var modeStr = _mode == 0 ? "Daily" : "Yearly";
        dc.drawText(width - 15, bottomY, Graphics.FONT_XTINY, modeStr, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    private function formatVal(val as Lang.Float?) as Lang.String {
        if (val != null) {
            return (val as Lang.Float).format("%.2f");
        }
        return "--";
    }

    function setMode(mode as Lang.Number) as Void {
        if (_mode != mode) {
            _mode = mode;
            _historyPoints = null;
            fetchHistoryData();
        }
    }

    function getMode() as Lang.Number {
        return _mode;
    }

    function toggleMode() as Void {
        setMode(_mode == 0 ? 1 : 0);
    }

    private function fetchHistoryData() as Void {
        _historyLoading = true;
        var range = _mode == 0 ? "daily" : "yearly";
        _fetcher.fetchHistory(_symbol.getName(), range, method(:onHistoryReceived));
    }

    function onHistoryReceived(data as Lang.Array?) as Void {
        _historyLoading = false;
        _historyPoints = data;
        WatchUi.requestUpdate();
    }
}
