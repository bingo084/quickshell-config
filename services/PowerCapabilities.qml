pragma Singleton

import Quickshell

Singleton {
    id: root
    property var capabilities: ({})
    property bool checking

    function refresh() {
        if (checking)
            return;
        checking = true;
        capabilities = {};
        const suspend = query("CanSuspend");
        const hibernate = query("CanHibernate");
        return Promise.all([suspend, hibernate]).then(([suspend, hibernate]) => {
            root.capabilities = {
                suspend,
                hibernate
            };
            root.checking = false;
        });
    }

    function canExecute(capability): bool {
        if (capability == null)
            return true;
        return capabilities[capability] === "yes";
    }

    function query(methodName: string): var {
        return Command.run(["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", methodName]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            const response = JSON.parse(result.stdout);
            if (response.type !== "s" || !Array.isArray(response.data) || typeof response.data[0] !== "string")
                throw new Error("Invalid response: " + result.stdout.trim());
            return response.data[0];
        }).catch(error => {
            console.warn(methodName + " query failed:", error.message);
            return "error";
        });
    }
}
