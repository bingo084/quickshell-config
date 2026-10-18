pragma Singleton

import Quickshell

SystemClock {
    readonly property string dateFormat: "MMM d"
    readonly property string timeFormat: "hh:mm"
    readonly property string dateTimeFormat: dateFormat + "\u2002" + timeFormat
    readonly property string fullDateTimeFormat: "yyyy-MM-dd hh:mm:ss"
}
