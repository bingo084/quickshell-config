pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.services

Singleton {
    id: root
    readonly property alias banners: bannerModel
    readonly property alias notifications: notificationModel
    readonly property alias history: historyModel
    readonly property alias groups: groupModel
    property bool quiet: false
    property bool popupVisible: false
    property bool notificationsVisible: false
    onNotificationsVisibleChanged: {
        if (notificationsVisible)
            markRead();
    }
    property var records: []
    readonly property int historyLimit: 1000
    readonly property int unreadCount: {
        let count = 0;
        for (let i = 0; i < notificationModel.count; i++)
            count += notificationModel.get(i).record.unread ? 1 : 0;
        return count;
    }
    onPopupVisibleChanged: {
        if (!popupVisible)
            return;
        while (bannerModel.count > 0)
            removeBanner(bannerModel.get(0).record);
    }
    Component.onDestruction: save()

    PersistentProperties {
        id: state
        reloadableId: "notifications"
        property string recordsJson: ""
        onLoaded: root.loadHistory()
    }
    ListModel {
        id: notificationModel
    }
    ListModel {
        id: groupModel
    }
    ListModel {
        id: bannerModel
    }
    ListModel {
        id: historyModel
    }

    FileView {
        id: historyFile
        path: Quickshell.statePath("notifications.json")
        blockLoading: true
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Could not read notification history:", FileViewError.toString(error));
        }
        onSaveFailed: error => console.warn("Could not save notification history:", FileViewError.toString(error))
    }
    NotificationServer {
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            const key = `${Quickshell.instanceId}:${notification.id}`;
            let record = root.records.find(record => record.snapshot.key === key);
            if (record)
                root.removeHistory(record);
            else
                record = recordComponent.createObject(root, {
                    snapshot: {
                        key,
                        receivedAt: Date.now()
                    }
                });
            record.notification = notification;
            record.output = NiriService.focusedScreen()?.name ?? "";
            record.unread = !notification.lastGeneration && !root.notificationsVisible;
            root.capture(record, record.snapshot.receivedAt);
            notificationModel.insert(0, {
                record
            });
            if (!notification.lastGeneration)
                root.showBanner(record);
            root.syncGroups();
        }
    }

    function loadHistory() {
        try {
            const snapshots = JSON.parse(state.recordsJson || historyFile.text() || "[]");
            records = snapshots.slice(0, historyLimit).map(snapshot => recordComponent.createObject(root, {
                    snapshot,
                    stored: true
                }));
            historyModel.append(records.map(record => ({
                        record
                    })));
        } catch (error) {
            console.warn("Could not load notification history:", error);
        }
    }

    function save() {
        state.recordsJson = JSON.stringify(records.map(record => record.snapshot));
        historyFile.setText(state.recordsJson);
    }

    function removeHistory(record: var) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).record === record) {
                historyModel.remove(i);
                return;
            }
        }
    }

    function capture(record: var, receivedAt: double) {
        const notification = record.notification;
        const snapshot = {
            key: record.snapshot.key,
            appName: notification.appName,
            appIcon: notification.appIcon,
            desktopEntry: notification.desktopEntry,
            summary: notification.summary,
            body: notification.body,
            urgency: notification.urgency,
            receivedAt
        };
        if (record.stored && Object.keys(snapshot).every(key => snapshot[key] === record.snapshot[key]))
            return;
        record.snapshot = snapshot;
        if (!record.stored) {
            records.push(record);
            record.stored = true;
        }
        records.sort((a, b) => b.snapshot.receivedAt - a.snapshot.receivedAt);
        for (const removed of records.splice(historyLimit)) {
            removeHistory(removed);
            removed.stored = false;
            removed.release();
        }
        Qt.callLater(save);
    }

    function archive(record: var) {
        if (!record.active)
            return;
        capture(record, record.snapshot.receivedAt);
        record.notification = null;
        record.hideBanner();
        if (record.stored) {
            let index = 0;
            while (index < historyModel.count && historyModel.get(index).record.snapshot.receivedAt >= record.snapshot.receivedAt)
                index++;
            historyModel.insert(index, {
                record
            });
        }
        for (let i = 0; i < notificationModel.count; i++) {
            if (notificationModel.get(i).record === record) {
                notificationModel.remove(i);
                break;
            }
        }
        syncGroups();
        record.release();
    }

    function activate(record: var, action: var): bool {
        if (record.active && action) {
            record.unread = false;
            action.invoke();
            return true;
        }
        if (!openApplication(record.snapshot))
            return false;
        if (record.active) {
            record.unread = false;
            record.hideBanner();
        }
        return true;
    }

    function openApplication(snapshot: var): bool {
        const entry = snapshot.desktopEntry ? DesktopEntries.byId(snapshot.desktopEntry) : null;
        const app = entry ?? DesktopEntries.applications.values.find(app => app.name === snapshot.appName);
        const ids = [snapshot.desktopEntry, app?.id, app?.startupClass].filter(Boolean);
        const window = ToplevelManager.toplevels.values.find(window => ids.includes(window.appId));
        if (window)
            window.activate();
        else if (app)
            app.execute();
        else
            return false;
        return true;
    }

    function syncGroups() {
        const apps = new Map();
        for (let i = 0; i < notificationModel.count; i++) {
            const record = notificationModel.get(i).record;
            const snapshot = record.snapshot;
            const key = snapshot.desktopEntry || snapshot.appName || snapshot.appIcon || "Notifications";
            if (!apps.has(key))
                apps.set(key, []);
            apps.get(key).push(record);
        }

        let index = 0;
        for (const [key, records] of apps) {
            let found = index;
            while (found < groupModel.count && groupModel.get(found).key !== key)
                found++;
            if (found === groupModel.count)
                groupModel.insert(index, {
                    key: key,
                    entries: []
                });
            else if (found !== index)
                groupModel.move(found, index, 1);

            const entries = groupModel.get(index).entries;
            for (let i = 0; i < records.length; i++) {
                let position = i;
                while (position < entries.count && entries.get(position).record !== records[i])
                    position++;
                if (position === entries.count)
                    entries.insert(i, {
                        record: records[i]
                    });
                else if (position !== i)
                    entries.move(position, i, 1);
            }
            if (entries.count > records.length)
                entries.remove(records.length, entries.count - records.length);
            index++;
        }
        if (groupModel.count > index)
            groupModel.remove(index, groupModel.count - index);
    }

    function removeBanner(record: var) {
        for (let i = 0; i < bannerModel.count; i++) {
            if (bannerModel.get(i).record === record) {
                bannerModel.remove(i);
                record.banner = false;
                record.release();
                return;
            }
        }
    }

    function promote(record: var) {
        for (let i = 0; i < notificationModel.count; i++) {
            if (notificationModel.get(i).record === record) {
                if (i > 0)
                    notificationModel.move(i, 0, 1);
                syncGroups();
                return;
            }
        }
    }

    function showBanner(record: var) {
        if (popupVisible || (quiet && record.snapshot.urgency !== NotificationUrgency.Critical)) {
            record.hideBanner();
            return;
        }
        if (!Quickshell.screens.some(screen => screen.name === record.output))
            record.output = NiriService.focusedScreen()?.name ?? "";
        record.bannerClosing = false;
        if (!record.banner) {
            record.banner = true;
            bannerModel.insert(0, {
                record
            });
        }
    }

    function markRead() {
        for (let i = 0; i < notificationModel.count; i++)
            notificationModel.get(i).record.unread = false;
    }

    function dismiss(record: var) {
        if (record.active)
            record.notification.dismiss();
    }

    function clear() {
        while (notificationModel.count > 0)
            dismiss(notificationModel.get(0).record);
    }

    function clearGroup(entries) {
        const records = Array.from({
            length: entries.count
        }, (_, i) => entries.get(i).record);
        records.forEach(dismiss);
    }

    Component {
        id: recordComponent
        Scope {
            id: record
            required property var snapshot
            property Notification notification: null
            readonly property bool active: notification !== null
            property bool stored: false
            property bool unread: false
            property string output: ""
            property bool banner: false
            property bool bannerClosing: false
            property int viewers: 0
            readonly property date receivedAt: new Date(snapshot.receivedAt)
            readonly property var actions: active ? Array.from(notification.actions) : []
            readonly property string image: active ? notification.image : ""
            readonly property real timeout: !active || snapshot.urgency === NotificationUrgency.Critical ? 0 : notification.expireTimeout < 0 ? 6000 : notification.expireTimeout
            signal refreshed

            function release() {
                if (!stored && !active && !banner && viewers === 0)
                    destroy();
            }
            function hideBanner() {
                bannerClosing = true;
            }
            function refresh() {
                if (!active)
                    return;
                root.capture(record, Date.now());
                unread = !root.notificationsVisible;
                root.promote(record);
                root.showBanner(record);
                refreshed();
            }
            Connections {
                target: record.notification
                function onClosed() {
                    root.archive(record);
                }
                function onSummaryChanged() {
                    Qt.callLater(record.refresh);
                }
                function onBodyChanged() {
                    Qt.callLater(record.refresh);
                }
                function onActionsChanged() {
                    Qt.callLater(record.refresh);
                }
                function onImageChanged() {
                    Qt.callLater(record.refresh);
                }
                function onExpireTimeoutChanged() {
                    Qt.callLater(record.refresh);
                }
                function onUrgencyChanged() {
                    Qt.callLater(record.refresh);
                }
                function onHintsChanged() {
                    Qt.callLater(record.refresh);
                }
                function onAppNameChanged() {
                    Qt.callLater(record.refresh);
                }
                function onAppIconChanged() {
                    Qt.callLater(record.refresh);
                }
            }
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            const outputs = Quickshell.screens.map(screen => screen.name);
            for (let i = 0; i < bannerModel.count; i++) {
                const record = bannerModel.get(i).record;
                if (!outputs.includes(record.output))
                    record.output = NiriService.focusedScreen()?.name ?? "";
            }
        }
    }
}
