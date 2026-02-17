using Toybox.Lang;

class JsonParser {

    static function get(dict as Lang.Dictionary?, key as Lang.String) as Lang.Object? {
        if (dict == null) {
            return null;
        }
        return (dict as Lang.Dictionary).get(key);
    }

    static function getPath(dict as Lang.Dictionary?, path as Lang.String) as Lang.Object? {
        if (dict == null) {
            return null;
        }

        var current = dict;
        // Manual split on "."
        var parts = [] as Lang.Array;
        var segment = "";
        for (var i = 0; i < path.length(); i++) {
            var ch = path.substring(i, i + 1);
            if (ch.equals(".")) {
                if (segment.length() > 0) {
                    parts.add(segment);
                }
                segment = "";
            } else {
                segment += ch;
            }
        }
        if (segment.length() > 0) {
            parts.add(segment);
        }

        for (var i = 0; i < parts.size(); i++) {
            var part = parts[i] as Lang.String;
            current = (current as Lang.Dictionary).get(part);

            if (current == null) {
                return null;
            }
        }

        return current;
    }

    static function parseFloat(value) as Lang.Float? {
        if (value instanceof Lang.Float) {
            return value as Lang.Float;
        } else if (value instanceof Lang.Number) {
            return (value as Lang.Number).toFloat();
        } else if (value instanceof Lang.String) {
            return (value as Lang.String).toFloat();
        }
        return null;
    }
}
