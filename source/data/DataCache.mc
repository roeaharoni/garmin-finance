using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

class DataCache {

    function initialize() {
    }

    function store(symbolName as Lang.String, value as Lang.Float, change as Lang.Float) as Void {
        var key = "symbol_" + symbolName;
        var data = {
            "value" => value,
            "change" => change,
            "timestamp" => System.getTimer()
        };
        Storage.setValue(key, data);
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
