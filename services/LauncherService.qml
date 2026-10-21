pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    function toggle() {
        rofi.running = !rofi.running;
    }

    Process {
        id: rofi
        command: ["rofi", "-show"]
    }
}
