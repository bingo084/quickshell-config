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
            id: queryOutput
        }
        stderr: StdioCollector {
            id: queryErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn(methodName + " query failed (exit " + exitCode + "):", queryErrors.text.trim());
                status = "error";
                return;
            }
            try {
                const result = JSON.parse(queryOutput.text);
                if (result.type !== "s" || !Array.isArray(result.data) || typeof result.data[0] !== "string") {
                    console.warn("Invalid " + methodName + " response:", queryOutput.text.trim());
                    status = "error";
                    return;
                }
                status = result.data[0];
            } catch (e) {
                console.warn("Invalid " + methodName + " response:", e.message, queryOutput.text.trim());
                status = "error";
            }
        }
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
