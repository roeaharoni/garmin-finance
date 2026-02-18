using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

class DataCache {

    function initialize() {
    }

    function store(symbolName as Lang.String, data as Lang.Dictionary) as Void {
        var key = "symbol_" + symbolName;
        var cacheData = {
            "value" => data.get("value"),
            "change" => data.get("change"),
            "changePercent" => data.get("changePercent"),
            "timestamp" => System.getTimer()
        } as Lang.Dictionary;

        // Store OHLC if available
        if (data.get("open") != null) { cacheData.put("open", data.get("open")); }
        if (data.get("high") != null) { cacheData.put("high", data.get("high")); }
        if (data.get("low") != null) { cacheData.put("low", data.get("low")); }
        if (data.get("previousClose") != null) { cacheData.put("previousClose", data.get("previousClose")); }

        // Store 52-week if available
        if (data.get("fiftyTwoWeekHigh") != null) { cacheData.put("fiftyTwoWeekHigh", data.get("fiftyTwoWeekHigh")); }
        if (data.get("fiftyTwoWeekLow") != null) { cacheData.put("fiftyTwoWeekLow", data.get("fiftyTwoWeekLow")); }

        Storage.setValue(key, cacheData);
    }

    function get(symbolName as Lang.String) as Lang.Dictionary? {
        var key = "symbol_" + symbolName;
        return Storage.getValue(key) as Lang.Dictionary?;
    }

    function storeHistory(symbolName as Lang.String, dataPoints as Lang.Array) as Void {
        var key = "history_" + symbolName;
        var points = [] as Lang.Array;

        for (var i = 0; i < dataPoints.size(); i++) {
            var point = dataPoints[i] as DataPoint;
            points.add({
                "timestamp" => point.getTimestamp(),
                "value" => point.getValue()
            });
        }

        Storage.setValue(key, points);
    }

    function getHistory(symbolName as Lang.String) as Lang.Array? {
        var key = "history_" + symbolName;
        var stored = Storage.getValue(key);

        if (stored == null) {
            return null;
        }

        var storedArr = stored as Lang.Array;
        var result = [] as Lang.Array;
        for (var i = 0; i < storedArr.size(); i++) {
            var item = storedArr[i] as Lang.Dictionary;
            result.add(new DataPoint(item.get("timestamp") as Lang.Number, item.get("value") as Lang.Float));
        }

        return result;
    }

    function clearAll() as Void {
        Storage.clearValues();
    }
}
