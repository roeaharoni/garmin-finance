using Toybox.Lang;

class DataPoint {
    private var _timestamp as Lang.Number;
    private var _value as Lang.Float;

    function initialize(timestamp as Lang.Number, value as Lang.Float) {
        _timestamp = timestamp;
        _value = value;
    }

    function getTimestamp() as Lang.Number {
        return _timestamp;
    }

    function getValue() as Lang.Float {
        return _value;
    }
}
