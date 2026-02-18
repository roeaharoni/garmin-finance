using Toybox.Lang;
using Toybox.Time;

class FinanceSymbol {
    private var _name as Lang.String;
    private var _value as Lang.Float?;
    private var _change as Lang.Float?;
    private var _changePercent as Lang.Float?;
    private var _lastUpdated as Lang.Number?;
    private var _error as Lang.Boolean = false;

    // OHLC data
    private var _open as Lang.Float?;
    private var _high as Lang.Float?;
    private var _low as Lang.Float?;
    private var _previousClose as Lang.Float?;

    // 52-week data
    private var _fiftyTwoWeekHigh as Lang.Float?;
    private var _fiftyTwoWeekLow as Lang.Float?;

    function initialize(name as Lang.String) {
        _name = name;
        _value = null;
        _change = null;
        _changePercent = null;
        _lastUpdated = null;
        _error = false;
        _open = null;
        _high = null;
        _low = null;
        _previousClose = null;
        _fiftyTwoWeekHigh = null;
        _fiftyTwoWeekLow = null;
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

    function getOpen() as Lang.Float? {
        return _open;
    }

    function setOpen(val as Lang.Float?) as Void {
        _open = val;
    }

    function getHigh() as Lang.Float? {
        return _high;
    }

    function setHigh(val as Lang.Float?) as Void {
        _high = val;
    }

    function getLow() as Lang.Float? {
        return _low;
    }

    function setLow(val as Lang.Float?) as Void {
        _low = val;
    }

    function getPreviousClose() as Lang.Float? {
        return _previousClose;
    }

    function setPreviousClose(val as Lang.Float?) as Void {
        _previousClose = val;
    }

    function getFiftyTwoWeekHigh() as Lang.Float? {
        return _fiftyTwoWeekHigh;
    }

    function setFiftyTwoWeekHigh(val as Lang.Float?) as Void {
        _fiftyTwoWeekHigh = val;
    }

    function getFiftyTwoWeekLow() as Lang.Float? {
        return _fiftyTwoWeekLow;
    }

    function setFiftyTwoWeekLow(val as Lang.Float?) as Void {
        _fiftyTwoWeekLow = val;
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
