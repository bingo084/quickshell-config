pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var data
    property string error

    function refresh(force = false) {
        if (query.running || (!force && cooldown.running))
            return;
        cooldown.restart();
        root.error = "";
        query.running = true;
    }

    function send(message) {
        query.write(JSON.stringify(message) + "\n");
    }

    function receive(message) {
        if (message.error) {
            root.error = message.error.message;
            console.warn("CodexQuota:", root.error);
            query.running = false;
            return;
        }
        if (message.id === 1) {
            root.send({
                method: "initialized"
            });
            root.send({
                id: 2,
                method: "account/rateLimits/read"
            });
        } else if (message.id === 2) {
            root.data = message.result;
            query.running = false;
        }
    }

    Process {
        id: query
        command: ["codex", "app-server", "--stdio"]
        stdinEnabled: true
        onStarted: root.send({
            id: 1,
            method: "initialize",
            params: {
                clientInfo: {
                    name: "quickshell",
                    title: "Quickshell",
                    version: "0.1.0"
                },
                capabilities: null
            }
        })
        stdout: SplitParser {
            onRead: line => root.receive(JSON.parse(line))
        }
    }

    Timer {
        id: cooldown
        interval: 5000
    }

    Timer {
        id: refreshTimer
        interval: 300000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
