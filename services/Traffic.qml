pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real rxBps
    property real txBps
    property bool valid
    property var previous: null

    function parse(text: string): var {
        const counters = {};
        for (const line of text.split("\n")) {
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const name = line.slice(0, colon).trim();
            if (/^(?:lo$|meta$|veth|tun|tap|docker|br-)/i.test(name))
                continue;
            const fields = line.slice(colon + 1).trim().split(/\s+/);
            if (fields.length < 16)
                continue;
            const rx = Number(fields[0]);
            const tx = Number(fields[8]);
            if (!Number.isFinite(rx) || !Number.isFinite(tx) || rx < 0 || tx < 0)
                continue;
            counters[name] = { rx, tx };
        }
        return counters;
    }

    function invalidate() {
        valid = false;
        rxBps = 0;
        txBps = 0;
    }

    function sample(text: string) {
        const current = parse(text);
        if (Object.keys(current).length === 0) {
            previous = null;
            invalidate();
            return;
        }
        const before = previous;
        previous = current;
        const seconds = sampleTimer.restart();
        if (before === null || seconds <= 0) {
            invalidate();
            return;
        }
        let rxBytes = 0;
        let txBytes = 0;
        let matched = 0;
        for (const name of Object.keys(current)) {
            const old = before[name];
            const after = current[name];
            if (old === undefined || after.rx < old.rx || after.tx < old.tx)
                continue;
            rxBytes += after.rx - old.rx;
            txBytes += after.tx - old.tx;
            matched++;
        }
        valid = matched > 0;
        rxBps = valid ? rxBytes / seconds : 0;
        txBps = valid ? txBytes / seconds : 0;
    }

    ElapsedTimer {
        id: sampleTimer
    }

    FileView {
        id: netDev
        path: "/proc/net/dev"
        onLoaded: root.sample(netDev.text())
        onLoadFailed: {
            root.previous = null;
            root.invalidate();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: netDev.reload()
    }
}
