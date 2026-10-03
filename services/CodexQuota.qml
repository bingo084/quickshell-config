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

    function request(method, params) {
        root.send({id: method, method, params});
    }

    function receive(message) {
        if (message.error) {
            root.error = message.error.message;
            console.warn("CodexQuota:", root.error);
            query.running = false;
            return;
        }
        switch (message.id) {
        case "initialize":
            root.send({method: "initialized"});
            root.request("config/read", {includeLayers: false});
            break;
        case "config/read":
            root.readProvider(message.result.config);
            root.request("account/read", {refreshToken: false});
            break;
        case "account/read":
            root.account = message.result.account;
            if (root.account?.type === "chatgpt") {
                root.request("account/rateLimits/read");
            } else {
                root.rateLimits = null;
                root.resetCredits = null;
                query.running = false;
            }
            break;
        case "account/rateLimits/read":
            root.rateLimits = message.result.rateLimits;
            root.resetCredits = message.result.rateLimitResetCredits;
            query.running = false;
            break;
        }
    }

    function readProvider(config) {
        const id = config.model_provider ?? "openai";
        const definition = id === "openai"
            ? {name: "OpenAI", base_url: config.openai_base_url}
            : config.model_providers?.[id];
        if (!definition || (id === "openai" && !definition.base_url)) {
            root.provider = null;
            return;
        }
        root.provider = {
            name: definition.name,
            address: (definition.base_url ?? "").replace(/^(https?:\/\/)[^/]*@/i, "$1").split(/[?#]/)[0]
        };
    }

    Process {
        id: query
        command: ["codex", "app-server", "--stdio"]
        stdinEnabled: true
        onStarted: root.request("initialize", {
                clientInfo: {
                    name: "quickshell",
                    title: "Quickshell",
                    version: "0.1.0"
                },
                capabilities: null
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
