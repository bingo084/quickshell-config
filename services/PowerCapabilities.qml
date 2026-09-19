pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    readonly property var queriesByCapability: ({
            suspend: suspendQuery,
            hibernate: hibernateQuery
        })

    function refresh() {
        for (const capability in queriesByCapability)
            queriesByCapability[capability].refresh();
    }

    function canExecute(capability): bool {
        if (capability == null)
            return true;
        return queriesByCapability[capability]?.status === "yes";
    }

    component CapabilityQuery: Process {
        id: query
        required property string methodName
        property string status: "unknown"

        function refresh() {
            status = "unknown";
            running = true;
        }

        command: ["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", methodName]
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn(methodName + " query failed (exit " + exitCode + "):", stderr.text.trim());
                status = "error";
                return;
            }
            try {
                const result = JSON.parse(stdout.text);
                if (result.type !== "s" || !Array.isArray(result.data) || typeof result.data[0] !== "string") {
                    console.warn("Invalid " + methodName + " response:", stdout.text.trim());
                    status = "error";
                    return;
                }
                status = result.data[0];
            } catch (e) {
                console.warn("Invalid " + methodName + " response:", e.message, stdout.text.trim());
                status = "error";
            }
        }
        // qmllint enable signal-handler-parameters
    }

    CapabilityQuery {
        id: hibernateQuery
        methodName: "CanHibernate"
    }

    CapabilityQuery {
        id: suspendQuery
        methodName: "CanSuspend"
    }
}
