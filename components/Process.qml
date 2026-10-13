import QtQuick
import Quickshell.Io

Process {
    id: root
    property int delay
    property bool autoRestart
    property int restartDelay: 3000
    property bool skipIfRunning

    function run(after = root.delay) {
        if (running && skipIfRunning)
            return;
        reconnect.stop();
        if (after > 0) {
            trigger.pending = true;
            trigger.interval = after;
            trigger.restart();
        } else {
            cancelDelay();
            running = true;
        }
    }

    function cancelDelay() {
        trigger.pending = false;
        trigger.stop();
    }

    function execute() {
        if (running || trigger.running)
            return;
        trigger.pending = false;
        running = true;
    }

    readonly property list<QtObject> helpers: [
        Connections {
            target: root

            function onRunningChanged() {
                if (root.running)
                    reconnect.stop();
                else if (trigger.pending)
                    root.execute();
                else if (root.autoRestart)
                    reconnect.restart();
            }
        },
        Timer {
            id: trigger
            property bool pending
            onTriggered: root.execute()
        },
        Timer {
            id: reconnect
            interval: root.restartDelay
            onTriggered: root.running = true
        }
    ]
}
