import QtQuick
import qs.components

Flickable {
    id: root
    property Item wheelOwner: null
    readonly property bool wheelLocked: wheelPause.running

    interactive: wheelOwner === null

    // Keep one wheel gesture on its initial target, even when the pointer moves.
    function beginWheel(control: Item) {
        if (!wheelPause.running)
            wheelOwner = control;
        wheelPause.restart();
    }

    onVisibleChanged: {
        if (!visible) {
            wheelPause.stop();
            wheelOwner = null;
        }
    }

    WheelHandler {
        target: null
        blocking: false
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.beginWheel(null);
            event.accepted = false;
        }
    }
    Timer {
        id: wheelPause
        interval: 300
        onTriggered: root.wheelOwner = null
    }
}
