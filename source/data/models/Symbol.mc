using Toybox.Lang;

class FinanceSymbol {
    private var _name as Lang.String;
    private var _value as Lang.Float?;
    private var _change as Lang.Float?;
    private var _changePercent as Lang.Float?;
    private var _lastUpdated as Lang.Number?;
    private var _error as Lang.Boolean = false;

    function initialize(name as Lang.String) {
        _name = name;
        _value = null;
        _change = null;
        _changePercent = null;
        _lastUpdated = null;
        _error = false;
    }

    function getName() as Lang.String {
        return _name;
    }

    function getValue() as Lang.Float? {
        return _value;
    }

    function setValue(value as Lang.Float?) as Void {
        _value = value;
    }

    function getChange() as Lang.Float? {
        return _change;
    }

    function setChange(change as Lang.Float?) as Void {
        _change = change;
    }

    function getChangePercent() as Lang.Float? {
        return _changePercent;
    }

    function setChangePercent(percent as Lang.Float?) as Void {
        _changePercent = percent;
    }

    function getLastUpdated() as Lang.Number? {
        return _lastUpdated;
    }

    function setLastUpdated(timestamp as Lang.Number?) as Void {
        _lastUpdated = timestamp;
    }

    function isPositive() as Lang.Boolean {
        return _change != null && (_change as Lang.Float) > 0;
    }

    function isNegative() as Lang.Boolean {
        return _change != null && (_change as Lang.Float) < 0;
    }

    function hasError() as Lang.Boolean {
        return _error;
    }

    function setError(err as Lang.Boolean) as Void {
        _error = err;
    }
}
