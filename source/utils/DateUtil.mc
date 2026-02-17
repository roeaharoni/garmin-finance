using Toybox.Lang;
using Toybox.Time;
using Toybox.System;

class DateUtil {

    static function getRelativeTime(timestamp as Lang.Number) as Lang.String {
        var now = System.getTimer();
        var diff = now - timestamp;

        var seconds = diff / 1000;

        if (seconds < 60) {
            return "Just now";
        } else if (seconds < 3600) {
            var minutes = seconds / 60;
            return minutes + "m ago";
        } else if (seconds < 86400) {
            var hours = seconds / 3600;
            return hours + "h ago";
        } else {
            var days = seconds / 86400;
            return days + "d ago";
        }
    }

    static function formatTime(timestamp as Lang.Number) as Lang.String {
        var moment = new Time.Moment(timestamp);
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);

        return info.hour + ":" + (info.min as Lang.Number).format("%02d");
    }
}
