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

        var maxSymbols = symbolNames.size() < 3 ? symbolNames.size() : 3;
        var itemHeight = height / maxSymbols;

        for (var i = 0; i < maxSymbols; i++) {
            var symbolName = symbolNames[i] as Lang.String;
            var cached = cache.get(symbolName);
            var centerY = (i * itemHeight) + (itemHeight / 2);

            if (cached != null) {
                drawSymbol(dc, symbolName, cached.get("value") as Lang.Float?, cached.get("changePercent") as Lang.Float?, centerY, width);
            } else {
                drawSymbol(dc, symbolName, null, null, centerY, width);
            }
        }
    }

    // Each symbol is drawn on a single vertically-centered line: name on the
    // left, price + colored % change on the right. No stacking, so rows don't
    // overlap even when the glance band is short.
    private function drawSymbol(dc as Graphics.Dc, name as Lang.String, value as Lang.Float?, changePercent as Lang.Float?, centerY as Lang.Number, width as Lang.Number) as Void {
        var leftMargin = 8;
        var rightMargin = width - 8;
        var vcenter = Graphics.TEXT_JUSTIFY_VCENTER;
        var display = SymbolFormatter.prettify(name);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftMargin, centerY, Graphics.FONT_XTINY, display, Graphics.TEXT_JUSTIFY_LEFT | vcenter);

        if (value == null) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightMargin, centerY, Graphics.FONT_XTINY, "--", Graphics.TEXT_JUSTIFY_RIGHT | vcenter);
            return;
        }

        var valueStr = (value as Lang.Float).format("%.2f");

        if (changePercent != null) {
            var pct = changePercent as Lang.Float;
            var pctStr = (pct >= 0 ? "+" : "") + pct.format("%.1f") + "%";
            var color = pct >= 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;

            // % on the far right (colored), price to its left (white)
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightMargin, centerY, Graphics.FONT_XTINY, pctStr, Graphics.TEXT_JUSTIFY_RIGHT | vcenter);

            var pctWidth = dc.getTextWidthInPixels(pctStr, Graphics.FONT_XTINY);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightMargin - pctWidth - 6, centerY, Graphics.FONT_XTINY, valueStr, Graphics.TEXT_JUSTIFY_RIGHT | vcenter);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightMargin, centerY, Graphics.FONT_XTINY, valueStr, Graphics.TEXT_JUSTIFY_RIGHT | vcenter);
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
