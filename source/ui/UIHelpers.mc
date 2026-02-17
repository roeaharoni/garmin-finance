using Toybox.Graphics;
using Toybox.Lang;

class UIHelpers {

    static function drawLineChart(dc as Graphics.Dc, dataPoints as Lang.Array, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number) as Void {
        if (dataPoints == null || dataPoints.size() < 2) {
            return;
        }

        var minValue = (dataPoints[0] as DataPoint).getValue();
        var maxValue = (dataPoints[0] as DataPoint).getValue();

        for (var i = 1; i < dataPoints.size(); i++) {
            var value = (dataPoints[i] as DataPoint).getValue();
            if (value < minValue) {
                minValue = value;
            }
            if (value > maxValue) {
                maxValue = value;
            }
        }

        var valueRange = maxValue - minValue;
        if (valueRange == 0) {
            valueRange = 1.0;
        }

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y + height, x + width, y + height);
        dc.drawLine(x, y, x, y + height);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < dataPoints.size() - 1; i++) {
            var point1 = dataPoints[i] as DataPoint;
            var point2 = dataPoints[i + 1] as DataPoint;

            var x1 = x + (i * width / (dataPoints.size() - 1));
            var y1 = y + height - ((point1.getValue() - minValue) / valueRange * height).toNumber();

            var x2 = x + ((i + 1) * width / (dataPoints.size() - 1));
            var y2 = y + height - ((point2.getValue() - minValue) / valueRange * height).toNumber();

            dc.drawLine(x1, y1, x2, y2);
        }
    }

    static function drawTrendArrow(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, isUp as Lang.Boolean, size as Lang.Number) as Void {
        var color = isUp ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        if (isUp) {
            dc.fillPolygon([
                [x, y - size],
                [x - size, y],
                [x + size, y]
            ] as Lang.Array);
        } else {
            dc.fillPolygon([
                [x, y + size],
                [x - size, y],
                [x + size, y]
            ] as Lang.Array);
        }
    }
}
