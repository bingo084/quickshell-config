pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string hibernateStatus: "unknown"

    function refresh() {
        hibernateStatus = "unknown";
        hibernateQuery.running = true;
    }

    Process {
        id: hibernateQuery
        command: ["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanHibernate"]
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("CanHibernate query failed (exit " + exitCode + "):", stderr.text.trim());
                root.hibernateStatus = "error";
                return;
            }
            try {
                const result = JSON.parse(stdout.text);
                if (result.type !== "s" || !Array.isArray(result.data) || typeof result.data[0] !== "string") {
                    console.warn("Invalid CanHibernate response:", stdout.text.trim());
                    root.hibernateStatus = "error";
                    return;
                }
                root.hibernateStatus = result.data[0];
            } catch (e) {
                console.warn("Invalid CanHibernate response:", e.message, stdout.text.trim());
                root.hibernateStatus = "error";
            }
        }
        // qmllint enable signal-handler-parameters
    }
}
