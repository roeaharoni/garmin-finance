using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class GraphView extends WatchUi.Drawable {
    private var _dataPoints as Lang.Array?;

    function initialize(params as Lang.Dictionary) {
        Drawable.initialize(params);
        _dataPoints = null;
    }

    function setData(dataPoints as Lang.Array?) as Void {
        _dataPoints = dataPoints;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_dataPoints == null || (_dataPoints as Lang.Array).size() == 0) {
            return;
        }

        var drawX = 0;
        var drawY = 0;
        var drawWidth = dc.getWidth();
        var drawHeight = 100;

        UIHelpers.drawLineChart(dc, _dataPoints as Lang.Array, drawX, drawY, drawWidth, drawHeight);
    }
}
