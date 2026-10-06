pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property var rateLimits
    property var resetCredits
    property var account
    property var provider
    property string error
    property bool connected: false
    property var threads: ({})
    readonly property var waiting: connected ? Object.values(threads).filter(thread => thread.status.type === "active" && thread.status.activeFlags.length > 0) : []
    readonly property bool busy: connected && Object.values(threads).some(thread => thread.status.type === "active" && thread.status.activeFlags.length === 0)

    QtObject {
        id: state
        property int nextId: 0
        property var pending: ({})
        property var subscribed: ({})
        property var syncing: ({})
    }

    function request(method, params = {}) {
        const id = ++state.nextId;
        state.pending[id] = {
            method,
            params
        };
        connection.write(JSON.stringify({
            id,
            method,
            params
        }) + "\n");
    }

    function refresh(force = false) {
        const pending = Object.values(state.pending).some(request => ["config/read", "account/read", "account/rateLimits/read", "thread/loaded/list"].includes(request.method));
        if (!connected || pending || (!force && cooldown.running))
            return;
        cooldown.restart();
        error = "";
        request("config/read");
        request("account/read");
        request("thread/loaded/list");
    }

    function refreshQuota() {
        const pending = Object.values(state.pending).some(request => request.method === "account/rateLimits/read");
        if (connected && account?.type === "chatgpt" && !pending)
            request("account/rateLimits/read");
    }

    function updateThread(thread) {
        const current = Object.assign({}, threads);
        current[thread.id] = thread;
        threads = current;
    }

    function syncSubscription(threadId) {
        if (!connected || state.syncing[threadId])
            return;
        const thread = threads[threadId];
        const active = thread?.status.type === "active" && !thread.ephemeral;
        if (active === Boolean(state.subscribed[threadId]))
            return;
        const params = {
            threadId
        };
        if (active)
            params.excludeTurns = true;
        state.syncing[threadId] = true;
        request(active ? "thread/resume" : "thread/unsubscribe", params);
    }

    function notification(message) {
        const params = message.params;
        switch (message.method) {
        case "account/updated":
            if (connected)
                request("account/read");
            break;
        case "account/rateLimits/updated":
            {
                if (account?.type !== "chatgpt")
                    break;
                const update = params.rateLimits;
                // Other model buckets have independent limits; retain the Codex bucket.
                if (update.limitId && update.limitId !== (rateLimits?.limitId ?? "codex"))
                    break;
                const merged = Object.assign({}, rateLimits);
                for (const key of Object.keys(update)) {
                    if (update[key] == null)
                        continue;
                    if (key === "primary" || key === "secondary") {
                        const window = Object.assign({}, merged[key]);
                        for (const field of Object.keys(update[key])) {
                            if (update[key][field] != null)
                                window[field] = update[key][field];
                        }
                        merged[key] = window;
                    } else {
                        merged[key] = update[key];
                    }
                }
                rateLimits = merged;
                break;
            }
        case "thread/started":
            updateThread(params.thread);
            syncSubscription(params.thread.id);
            break;
        case "thread/status/changed":
            {
                const previous = threads[params.threadId];
                updateThread(Object.assign({}, previous, {
                    id: params.threadId,
                    status: params.status
                }));
                if (previous?.status.type === "active" && params.status.type !== "active")
                    refreshQuota();
                syncSubscription(params.threadId);
                break;
            }
        case "thread/closed":
            {
                const current = Object.assign({}, threads);
                delete current[params.threadId];
                threads = current;
                delete state.subscribed[params.threadId];
                break;
            }
        }
    }

    function receive(message) {
        if (message.method) {
            // Ignore server requests; only handle notifications here.
            if (message.id === undefined)
                notification(message);
            return;
        }
        const pending = state.pending[message.id];
        if (!pending)
            return;
        delete state.pending[message.id];
        const method = pending.method;
        const threadId = pending.params.threadId;
        if (method === "thread/resume" || method === "thread/unsubscribe")
            delete state.syncing[threadId];
        if (message.error) {
            if (method === "thread/resume" && message.error.message.includes("no rollout found")) {
                // New threads are only persisted after their first prompt.
                subscriptionRetry.restart();
                return;
            }
            error = message.error.message;
            console.warn("Codex", method + ":", error);
            return;
        }
        const result = message.result;
        switch (method) {
        case "initialize":
            connection.write(JSON.stringify({
                method: "initialized"
            }) + "\n");
            connected = true;
            refresh(true);
            break;
        case "config/read":
            readProvider(result.config);
            break;
        case "account/read":
            account = result.account;
            if (account?.type === "chatgpt") {
                refreshQuota();
            } else {
                rateLimits = null;
                resetCredits = null;
            }
            break;
        case "account/rateLimits/read":
            rateLimits = result.rateLimits;
            resetCredits = result.rateLimitResetCredits;
            error = "";
            break;
        case "thread/loaded/list":
            {
                const current = {};
                for (const id of result.data) {
                    if (threads[id])
                        current[id] = threads[id];
                    request("thread/read", {
                        threadId: id
                    });
                }
                threads = current;
                break;
            }
        case "thread/read":
            updateThread(result.thread);
            syncSubscription(threadId);
            break;
        case "thread/resume":
            state.subscribed[threadId] = true;
            syncSubscription(threadId);
            break;
        case "thread/unsubscribe":
            delete state.subscribed[threadId];
            syncSubscription(threadId);
            break;
        }
    }

    function readProvider(config) {
        const id = config.model_provider ?? "openai";
        const definition = id === "openai" ? {
            name: "OpenAI",
            base_url: config.openai_base_url
        } : config.model_providers?.[id];
        if (!definition || (id === "openai" && !definition.base_url)) {
            provider = null;
            return;
        }
        provider = {
            name: definition.name,
            address: (definition.base_url ?? "").replace(/^(https?:\/\/)[^/]*@/i, "$1").split(/[?#]/)[0]
        };
    }

    Connections {
        target: Sleep

        function onResumed() {
            root.refresh(true);
        }
    }

    Connections {
        target: Network

        function onReady() {
            root.refreshQuota();
        }
    }

    Process {
        id: connection
        command: {
            const codexHome = Quickshell.env("CODEX_HOME") || Quickshell.env("HOME") + "/.codex";
            return ["websocat", "-t", "-E", "--ws-c-uri=ws://localhost/", "-", `ws-c:unix:${codexHome}/app-server-control/app-server-control.sock`];
        }
        stdinEnabled: true
        running: true
        onStarted: root.request("initialize", {
            clientInfo: {
                name: "quickshell",
                version: "0.1.0"
            },
            capabilities: {
                optOutNotificationMethods: ["item/agentMessage/delta", "item/reasoning/textDelta", "item/reasoning/summaryTextDelta", "item/commandExecution/outputDelta", "item/fileChange/outputDelta", "turn/diff/updated", "turn/plan/updated", "item/started", "item/completed"]
            }
        })
        stdout: SplitParser {
            onRead: line => root.receive(JSON.parse(line))
        }
        stderr: SplitParser {
            onRead: line => console.warn(line)
        }
        // qmllint disable signal-handler-parameters
        onExited: {
            root.connected = false;
            root.threads = {};
            state.pending = {};
            state.subscribed = {};
            state.syncing = {};
            root.error = "Codex daemon disconnected.";
            subscriptionRetry.stop();
            reconnect.restart();
        }
        // qmllint enable signal-handler-parameters
    }

    Timer {
        id: reconnect
        interval: 3000
        onTriggered: connection.running = true
    }

    Timer {
        id: subscriptionRetry
        interval: 1000
        onTriggered: {
            for (const id of Object.keys(root.threads))
                root.syncSubscription(id);
        }
    }

    Timer {
        id: cooldown
        interval: 5000
    }

    Timer {
        interval: 300000
        running: root.connected
        repeat: true
        onTriggered: root.refreshQuota()
    }
}
