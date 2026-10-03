pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var rateLimits
    property var resetCredits
    property var account
    property var provider
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
                method: "config/read",
                params: { includeLayers: false }
            });
        } else if (message.id === 2) {
            root.readProvider(message.result.config);
            root.send({
                id: 3,
                method: "account/read",
                params: { refreshToken: false }
            });
        } else if (message.id === 3) {
            root.account = message.result.account;
            if (root.account?.type === "chatgpt") {
                root.send({
                    id: 4,
                    method: "account/rateLimits/read"
                });
            } else {
                root.rateLimits = null;
                root.resetCredits = null;
                query.running = false;
            }
        } else if (message.id === 4) {
            root.rateLimits = message.result.rateLimits;
            root.resetCredits = message.result.rateLimitResetCredits;
            query.running = false;
        }
    }

    function readProvider(config) {
        const id = config.model_provider ?? "openai";
        const definition = config.model_providers?.[id];
        const address = id === "openai" ? config.openai_base_url : definition?.base_url;
        if (!address && (id === "openai" || !definition)) {
            root.provider = null;
            return;
        }
        root.provider = {
            name: definition?.name ?? (id === "openai" ? "OpenAI" : id),
            address: (address ?? "").replace(/^(https?:\/\/)[^/]*@/i, "$1").split(/[?#]/)[0]
        };
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
