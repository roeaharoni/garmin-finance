using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;

class FinanceWidget extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var symbolsStr = Application.Properties.getValue("symbols");
        if (symbolsStr == null || (symbolsStr as Lang.String).equals("")) {
            drawNoData(dc);
            return;
        }

        var symbolNames = parseSymbols(symbolsStr as Lang.String);
        if (symbolNames.size() == 0) {
            drawNoData(dc);
            return;
        }

        var cache = new DataCache();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var y = 5;
        var itemHeight = height / 3;

        var maxSymbols = symbolNames.size() < 3 ? symbolNames.size() : 3;

        for (var i = 0; i < maxSymbols; i++) {
            var symbolName = symbolNames[i] as Lang.String;
            var cached = cache.get(symbolName);

            if (cached != null) {
                drawSymbol(dc, symbolName, cached.get("value") as Lang.Float?, cached.get("change") as Lang.Float?, y, width, itemHeight);
            } else {
                drawSymbol(dc, symbolName, null, null, y, width, itemHeight);
            }

            y += itemHeight;
        }
    }

    private function drawSymbol(dc as Graphics.Dc, name as Lang.String, value as Lang.Float?, change as Lang.Float?, y as Lang.Number, width as Lang.Number, height as Lang.Number) as Void {
        var leftMargin = 5;
        var rightMargin = width - 5;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftMargin, y, Graphics.FONT_XTINY, name, Graphics.TEXT_JUSTIFY_LEFT);

        if (value != null) {
            var val = value as Lang.Float;
            var valueStr = val.format("%.2f");
            dc.drawText(leftMargin, y + 12, Graphics.FONT_TINY, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

            if (change != null && (change as Lang.Float) != 0) {
                var chg = change as Lang.Float;
                var arrow = chg > 0 ? "+" : "-";
                var color = chg > 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(rightMargin, y + 12, Graphics.FONT_TINY, arrow, Graphics.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, y + 12, Graphics.FONT_XTINY, "--", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function drawNoData(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 - 10, Graphics.FONT_TINY, "Finance", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 2 + 5, Graphics.FONT_XTINY, "Configure", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function parseSymbols(str as Lang.String) as Lang.Array {
        var result = [] as Lang.Array;
        var current = "";

        for (var i = 0; i < str.length(); i++) {
            var ch = str.substring(i, i + 1);
            if (ch.equals(",")) {
                var trimmed = trimStr(current);
                if (trimmed.length() > 0) {
                    result.add(trimmed);
                }
                current = "";
            } else {
                current += ch;
            }
        }

        var trimmed = trimStr(current);
        if (trimmed.length() > 0) {
            result.add(trimmed);
        }

        return result;
    }

    private function trimStr(str as Lang.String) as Lang.String {
        var start = 0;
        var end = str.length();

        while (start < end && str.substring(start, start + 1).equals(" ")) {
            start++;
        }

        while (end > start && str.substring(end - 1, end).equals(" ")) {
            end--;
        }

        return start < end ? str.substring(start, end) as Lang.String : "";
    }
}
