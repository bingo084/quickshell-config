pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function run(command: list<string>): var {
        if (command.length === 0)
            return Promise.reject(new Error("Command is empty."));
        return new Promise((resolve, reject) => {
            const process = invocation.createObject(root, {
                command,
                completion: {
                    resolve,
                    reject
                }
            });
            process.running = true;
        });
    }

    Component {
        id: invocation

        Process {
            required property var completion

            function finish(result, error = null) {
                const callbacks = completion;
                completion = null;
                if (error)
                    callbacks.reject(error);
                else
                    callbacks.resolve(result);
                destroy();
            }

            stdout: StdioCollector {
                id: output
            }
            stderr: StdioCollector {
                id: errors
            }

            onExited: (exitCode, exitStatus) => {
                if (exitStatus === 0)
                    finish({
                        exitCode,
                        stdout: output.text,
                        stderr: errors.text
                    });
                else
                    finish(null, new Error("Command terminated unexpectedly: " + command[0]));
            }

            // FailedToStart emits runningChanged, but not exited.
            onRunningChanged: {
                if (!running && completion)
                    finish(null, new Error("Could not start command: " + command[0]));
            }
        }
    }
}
