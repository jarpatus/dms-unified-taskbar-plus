import QtQuick
import QtQuick.Window
import QtQml
import Quickshell
import Quickshell.Wayland
import "../../../" as Production

// This is intentionally a service-free boundary: the fixture has notifying
// scalar/object properties, while the adapter receives the same fresh snapshot
// shape that UnifiedTaskbar.qml supplies in production.
ShellRoot {
    id: root

    property int failures: 0
    property int completedCases: 0
    property int rowCreated: 0
    property int rowDestroyed: 0
    property int columnCreated: 0
    property int columnDestroyed: 0
    property int rowEntryCreated: 0
    property int rowEntryDestroyed: 0
    property int columnEntryCreated: 0
    property int columnEntryDestroyed: 0
    property int adapterDestroyed: 0
    property int destroyedWorkspaceRecords: 0
    property int destroyedEntryRecords: 0
    property var initialWorkspaceRecords: []
    property var initialEntryRecords: []
    property var initialRowDelegates: []
    property var initialColumnDelegates: []
    property var initialRowEntryDelegates: []
    property var initialColumnEntryDelegates: []
    property var rowEntryDelegatesByKey: ({})
    property var columnEntryDelegatesByKey: ({})
    property var rowWorkspaceDelegatesByKey: ({})
    property var columnWorkspaceDelegatesByKey: ({})
    property var initialOuterArray: null
    property var initialEntryArray: null
    property int initialReconcileCount: 0
    property var replacementEntryRecord: null
    property var removedEntryRecord: null
    property var teardownAdapter: null

    QtObject {
        id: workspaceOne
        property int id: 1
    }
    QtObject {
        id: workspaceTwo
        property int id: 2
    }
    QtObject {
        id: workspaceEmpty
        property int id: 3
    }

    QtObject {
        id: firstWindow
        property string title: "Editor one"
        // Mirrors the installed Niri enrichment copying a native `toplevel`
        // property onto an already-actionable wrapper.
        property var toplevel: ({ nativeId: "first" })
        property bool focused: true
        property bool activated: true
        property int activations: 0
        property int closes: 0
        function activate() { activations++; }
        function close() { closes++; }
    }
    QtObject {
        id: firstWindowReplacement
        property string title: "Editor one (replacement)"
        property bool focused: false
        property bool activated: false
        property int activations: 0
        property int closes: 0
        function activate() { activations++; }
        function close() { closes++; }
    }
    QtObject {
        id: secondWindow
        property string title: "Terminal"
        // Keep this wrapper-shaped fixture representative of Niri enrichment;
        // action methods must remain reachable despite this nested property.
        property var toplevel: ({ nativeId: "second" })
        property bool focused: false
        property bool activated: false
        property int activations: 0
        property int closes: 0
        function activate() { activations++; }
        function close() { closes++; }
    }
    QtObject {
        id: thirdWindow
        property string title: "Browser"
        property bool focused: false
        property bool activated: false
        property int activations: 0
        property int closes: 0
        function activate() { activations++; }
        function close() { closes++; }
    }

    QtObject {
        id: fixture
        property string compositor: "niri"
        property bool groupByApp: false
        property bool useReplacement: false
        property bool reorder: false
        property bool removeSecond: false
        property bool removeFirst: false
        property bool emptyWorkspaceActive: false
        property bool wsOneActive: true
        property bool wsTwoActive: false
        property bool firstFocused: true
        property bool secondFocused: false
        property bool firstActivated: true
        property bool secondActivated: false
        property bool thirdActivated: false
        property bool adapterDestroyed: false
        property string phase: "initial"
        property QtObject first: firstWindow
        property QtObject replacement: firstWindowReplacement
        property QtObject second: secondWindow
        property QtObject third: thirdWindow
        property QtObject wsOne: workspaceOne
        property QtObject wsTwo: workspaceTwo
        property QtObject wsEmpty: workspaceEmpty
    }

    // Every field consumed by the adapter is copied here. In particular, title,
    // focus and activation are scalar dependencies, not nested-JS mutation.
    Production.TaskbarModel {
        id: adapter
        snapshot: ({
            compositor: fixture.compositor,
            groupByApp: fixture.groupByApp,
            workspaces: [
                {
                    workspaceId: 1,
                    workspace: fixture.wsOne,
                    active: fixture.wsOneActive,
                    hasClients: fixture.phase !== "emptyOne"
                },
                {
                    workspaceId: 2,
                    workspace: fixture.wsTwo,
                    active: fixture.wsTwoActive,
                    hasClients: true
                },
                {
                    workspaceId: 3,
                    workspace: fixture.wsEmpty,
                    active: fixture.emptyWorkspaceActive,
                    hasClients: false
                }
            ],
            windows: snapshotWindows()
            /* legacy snapshot expression retained in source history:
                fixture.reorder ? (fixture.removeSecond ? [ 
                    {
                        toplevel: fixture.useReplacement ? fixture.replacement : fixture.first,
                        niriWindowId: "niri-first",
                        workspaceId: 1,
                        appId: "editor",
                        title: (fixture.useReplacement ? fixture.replacement : fixture.first).title,
                        focused: fixture.firstFocused,
                        activated: fixture.firstActivated
                    },
                    {
                        toplevel: fixture.third,
                        niriWindowId: "niri-third",
                        workspaceId: 2,
                        appId: "browser",
                        title: fixture.third.title,
                        focused: false,
                        activated: false
                    }
                ] : [
                    {
                        toplevel: fixture.second,
                        niriWindowId: "niri-second",
                        workspaceId: 1,
                        appId: fixture.groupByApp ? "editor" : "terminal",
                        title: fixture.second.title,
                        focused: fixture.secondFocused,
                        activated: fixture.secondActivated
                    },
                    {
                        toplevel: fixture.useReplacement ? fixture.replacement : fixture.first,
                        niriWindowId: "niri-first",
                        workspaceId: 1,
                        appId: "editor",
                        title: (fixture.useReplacement ? fixture.replacement : fixture.first).title,
                        focused: fixture.firstFocused,
                        activated: fixture.firstActivated
                    },
                    {
                        toplevel: fixture.third,
                        niriWindowId: "niri-third",
                        workspaceId: 2,
                        appId: "browser",
                        title: fixture.third.title,
                        focused: false,
                        activated: false
                    }
                ])
                : (fixture.removeSecond ? [
                    {
                        toplevel: fixture.useReplacement ? fixture.replacement : fixture.first,
                        niriWindowId: "niri-first",
                        workspaceId: 1,
                        appId: "editor",
                        title: (fixture.useReplacement ? fixture.replacement : fixture.first).title,
                        focused: fixture.firstFocused,
                        activated: fixture.firstActivated
                    },
                    {
                        toplevel: fixture.third,
                        niriWindowId: "niri-third",
                        workspaceId: 2,
                        appId: "browser",
                        title: fixture.third.title,
                        focused: false,
                        activated: false
                    }
                ] : [
                    {
                        toplevel: fixture.useReplacement ? fixture.replacement : fixture.first,
                        niriWindowId: "niri-first",
                        workspaceId: 1,
                        appId: "editor",
                        title: (fixture.useReplacement ? fixture.replacement : fixture.first).title,
                        focused: fixture.firstFocused,
                        activated: fixture.firstActivated
                    },
                    {
                        toplevel: fixture.second,
                        niriWindowId: "niri-second",
                        workspaceId: 1,
                        appId: fixture.groupByApp ? "editor" : "terminal",
                        title: fixture.second.title,
                        focused: fixture.secondFocused,
                        activated: fixture.secondActivated
                    },
                    {
                        toplevel: fixture.third,
                        niriWindowId: "niri-third",
                        workspaceId: 2,
                        appId: "browser",
                        title: fixture.third.title,
                        focused: false,
                        activated: false
                    }
                ])
            */
        })
    }

    function snapshotWindows() {
        const currentFirst = fixture.useReplacement ? fixture.replacement : fixture.first;
        const first = {
            toplevel: currentFirst,
            niriWindowId: "niri-first",
            workspaceId: 1,
            appId: "editor",
            title: currentFirst.title,
            focused: fixture.firstFocused,
            activated: fixture.firstActivated
        };
        const second = {
            toplevel: fixture.second,
            niriWindowId: "niri-second",
            workspaceId: 1,
            appId: fixture.groupByApp ? "editor" : "terminal",
            title: fixture.second.title,
            focused: fixture.secondFocused,
            activated: fixture.secondActivated
        };
        const third = {
            toplevel: fixture.third,
            niriWindowId: "niri-third",
            workspaceId: 2,
            appId: "browser",
            title: fixture.third.title,
            focused: false,
            activated: fixture.thirdActivated
        };
        const result = [];
        if (!fixture.removeFirst) result.push(first);
        if (!fixture.removeSecond) result.push(second);
        result.push(third);
        if (fixture.reorder) result.reverse();
        return result;
    }

    Connections {
        target: adapter
        ignoreUnknownSignals: true
        function onDestroyed() { root.adapterDestroyed++; }
    }
    Connections {
        target: root.initialWorkspaceRecords.length > 0 ? root.initialWorkspaceRecords[0] : null
        ignoreUnknownSignals: true
        function onDestroyed() { root.destroyedWorkspaceRecords++; }
    }
    Connections {
        target: root.initialWorkspaceRecords.length > 1 ? root.initialWorkspaceRecords[1] : null
        ignoreUnknownSignals: true
        function onDestroyed() { root.destroyedWorkspaceRecords++; }
    }
    Connections {
        target: root.initialEntryRecords.length > 0 ? root.initialEntryRecords[0] : null
        ignoreUnknownSignals: true
        function onDestroyed() { root.destroyedEntryRecords++; }
    }
    Connections {
        target: root.initialEntryRecords.length > 1 ? root.initialEntryRecords[1] : null
        ignoreUnknownSignals: true
        function onDestroyed() { root.destroyedEntryRecords++; }
    }

    ScriptModel {
        id: horizontalWorkspaces
        values: adapter ? adapter.visibleWorkspaces : []
        objectProp: "workspaceId"
    }
    ScriptModel {
        id: verticalWorkspaces
        values: adapter ? adapter.visibleWorkspaces : []
        objectProp: "workspaceId"
    }

    Window {
        id: testWindow
        visible: true
        width: 320
        height: 180
        color: "#202020"
        title: "Unified Taskbar TaskbarModel integration"

        Row {
            id: horizontalRow
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 2
            Repeater {
                id: horizontalWorkspaceRepeater
                model: horizontalWorkspaces
                delegate: Component {
                    Rectangle {
                        width: 80
                        height: 40
                        color: modelData.active ? "#446688" : "#303030"
                        property var workspaceRecord: modelData
                        Component.onCompleted: {
                            root.initialRowDelegates.push(this);
                            if (workspaceRecord) root.rowWorkspaceDelegatesByKey[String(workspaceRecord.workspaceId)] = this;
                        }
                        Component.onDestruction: root.rowDestroyed++

                        ScriptModel {
                            id: horizontalEntries
                            values: workspaceRecord ? workspaceRecord.entries : []
                            objectProp: "entryKey"
                        }
                        Repeater {
                            model: horizontalEntries
                            delegate: Component {
                                Rectangle {
                                    width: 35
                                    height: 20
                                    property var entryRecord: modelData
                                    color: entryRecord && entryRecord.focused ? "#f0c674" : "#707070"
                                    Component.onCompleted: {
                                        root.rowCreated++;
                                        root.initialRowEntryDelegates.push(this);
                                        if (entryRecord) root.rowEntryDelegatesByKey[entryRecord.entryKey] = this;
                                    }
                                    Component.onDestruction: {
                                        root.rowEntryDestroyed++;
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: entryRecord ? entryRecord.title : ""
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: verticalColumn
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2
            Repeater {
                id: verticalWorkspaceRepeater
                model: verticalWorkspaces
                delegate: Component {
                    Rectangle {
                        width: 80
                        height: 40
                        color: modelData.active ? "#668844" : "#303030"
                        property var workspaceRecord: modelData
                        Component.onCompleted: {
                            root.initialColumnDelegates.push(this);
                            if (workspaceRecord) root.columnWorkspaceDelegatesByKey[String(workspaceRecord.workspaceId)] = this;
                        }
                        Component.onDestruction: root.columnDestroyed++
                        ScriptModel {
                            id: verticalEntries
                            values: workspaceRecord ? workspaceRecord.entries : []
                            objectProp: "entryKey"
                        }
                        Repeater {
                            model: verticalEntries
                            delegate: Component {
                                Rectangle {
                                    width: 35
                                    height: 20
                                    property var entryRecord: modelData
                                    color: entryRecord && entryRecord.focused ? "#f0c674" : "#707070"
                                    Component.onCompleted: {
                                        root.columnCreated++;
                                        root.initialColumnEntryDelegates.push(this);
                                        if (entryRecord) root.columnEntryDelegatesByKey[entryRecord.entryKey] = this;
                                    }
                                    Component.onDestruction: {
                                        root.columnEntryDestroyed++;
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: entryRecord ? entryRecord.title : ""
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        repeat: false
        running: true
        onTriggered: {
            fail("watchdog", "scenario did not finish")
            Qt.quit()
        }
    }

    function fail(name, detail) {
        failures++;
        console.error("QML_TEST_FAIL:" + name + (detail ? ": " + detail : ""));
    }

    function pass(name) {
        completedCases++;
        console.log("QML_TEST_PASS:" + name);
    }

    function assertTrue(condition, name, detail) {
        if (!condition) fail(name, detail || "assertion failed");
        return condition;
    }

    function waitForBindings(callback) {
        // The adapter coalesces notifications with Qt.callLater. A second turn
        // lets both ScriptModels and their Repeaters consume the publication.
        Qt.callLater(function() { Qt.callLater(callback); });
    }

    function workspace(id) {
        for (let item of adapter.visibleWorkspaces || []) {
            if (item.workspaceId === id) return item;
        }
        return null;
    }

    function entry(id) {
        const ws = workspace(1);
        if (!ws) return null;
        for (let item of ws.entries || []) {
            if (item.entryKey.indexOf(id) !== -1) return item;
        }
        return null;
    }

    function begin() {
        waitForBindings(runLifecycle);
    }

    function runLifecycle() {
        const wsOne = workspace(1);
        const wsTwo = workspace(2);
        assertTrue(!!wsOne && !!wsTwo, "qml_delegate_identity_reorder_remove", "populated workspaces are visible");
        assertTrue((wsOne.entries || []).length === 2 && (wsTwo.entries || []).length === 1,
            "qml_delegate_identity_reorder_remove", "row/column source entries are populated");
        assertTrue(root.initialRowDelegates.length >= 2 && root.initialColumnDelegates.length >= 2,
            "qml_delegate_identity_reorder_remove", "both row and column Repeaters created delegates");
        assertTrue(root.initialRowEntryDelegates.length >= 3 && root.initialColumnEntryDelegates.length >= 3,
            "qml_delegate_identity_reorder_remove", "both consumers created entry delegates");
        root.initialWorkspaceRecords = [wsOne, wsTwo];
        root.initialEntryRecords = [wsOne.entries[0], wsOne.entries[1]];
        root.initialOuterArray = adapter.visibleWorkspaces;
        root.initialEntryArray = wsOne.entries;
        root.initialReconcileCount = adapter.reconcileCount;
        const unchangedPayloads = wsOne.entries[0].payloads;
        adapter.reconcile();
        assertTrue(wsOne.entries[0].payloads === unchangedPayloads,
            "qml_unchanged_payload_snapshot", "unchanged reconcile retains the payload snapshot array");
        fixture.reorder = true;
        waitForBindings(function() {
            const reorderedOne = workspace(1);
            const reorderedTwo = workspace(2);
            assertTrue(reorderedOne === wsOne && reorderedTwo === wsTwo,
                "qml_delegate_identity_reorder_remove", "ungrouped reorder retains workspace record refs");
            assertTrue(reorderedOne.entries !== root.initialEntryArray,
                "qml_delegate_identity_reorder_remove", "reorder publishes a changed entry order array");
            assertTrue(entry("niri-first") === root.initialEntryRecords[0]
                    && entry("niri-second") === root.initialEntryRecords[1],
                "qml_delegate_identity_reorder_remove", "ungrouped reorder retains entry record refs");
            assertTrue(root.rowWorkspaceDelegatesByKey["1"].workspaceRecord === wsOne
                    && root.columnWorkspaceDelegatesByKey["1"].workspaceRecord === wsOne,
                "qml_delegate_identity_reorder_remove", "row and column workspace delegates retain reordered record");
            fixture.reorder = false;
            fixture.removeSecond = true;
            adapter.reconcile();
            const removed = entry("niri-second");
            assertTrue(!removed && adapter.pendingEntryCount > 0,
                "qml_delegate_identity_reorder_remove", "ungrouped removal publishes omission and pending retirement");
            waitForBindings(function() {
                assertTrue(adapter.pendingEntryCount === 0 && root.rowEntryDestroyed > 0 && root.columnEntryDestroyed > 0,
                    "qml_delegate_identity_reorder_remove", "removed row/column entry delegates eventually destroy");
                assertTrue(root.destroyedEntryRecords === 0,
                    "qml_delegate_identity_reorder_remove", "initial surviving records are not destroyed by preceding removal");
                pass("qml_delegate_identity_reorder_remove");
                fixture.removeSecond = false;
                waitForBindings(runFixtureReactivity);
            });
        });
    }

    function runFixtureReactivity() {
        const beforeCount = adapter.reconcileCount;
        const beforeWs = workspace(1);
        const beforeEntry = entry("niri-first");
        fixture.phase = "focus";
        fixture.firstFocused = false;
        fixture.firstActivated = false;
        firstWindow.title = "Editor one (focused update)";
        fixture.secondFocused = true;
        // Multiple notifying dependencies change in one turn; one scheduled
        // reconcile is the substantive coalescing assertion.
        waitForBindings(function() {
            const afterCount = adapter.reconcileCount;
            const afterWs = workspace(1);
            const afterEntry = entry("niri-first");
            assertTrue(afterCount === beforeCount + 1, "qml_fixture_reactivity_and_coalescing",
                "same-turn fixture changes trigger one reconcile");
            assertTrue(afterWs === beforeWs && afterEntry === beforeEntry,
                "qml_fixture_reactivity_and_coalescing", "records survive scalar changes");
            assertTrue(afterEntry.title === "Editor one (focused update)" && !afterEntry.focused,
                "qml_fixture_reactivity_and_coalescing", "title/focus payloads propagate");
            pass("qml_fixture_reactivity_and_coalescing");
            waitForBindings(runFocusActive);
        });
    }

    function runFocusActive() {
        const beforeOuter = adapter.visibleWorkspaces;
        const beforeEntriesOne = workspace(1).entries;
        const beforeEntriesTwo = workspace(2).entries;
        const beforeWsOne = workspace(1);
        const beforeWsTwo = workspace(2);
        const beforeWindowsOne = beforeEntriesOne.map(item => item.windows);
        fixture.phase = "focus";
        fixture.emptyWorkspaceActive = false;
        fixture.wsOneActive = false;
        fixture.wsTwoActive = true;
        fixture.secondFocused = true;
        fixture.firstFocused = false;
        fixture.firstActivated = false;
        waitForBindings(function() {
            assertTrue(adapter.visibleWorkspaces === beforeOuter,
                "qml_active_focus_and_title_updates", "populated active transition retains outer array");
            assertTrue(workspace(1) === beforeWsOne && workspace(2) === beforeWsTwo,
                "qml_active_focus_and_title_updates", "populated workspace records survive active update");
            assertTrue(workspace(1).entries === beforeEntriesOne && workspace(2).entries === beforeEntriesTwo,
                "qml_active_focus_and_title_updates", "populated entry arrays remain stable");
            assertTrue(workspace(1).entries[0].windows === beforeWindowsOne[0]
                    && workspace(1).entries[1].windows === beforeWindowsOne[1],
                "qml_active_focus_and_title_updates", "focus-only update retains windows arrays");
            const wsOneRow = root.rowWorkspaceDelegatesByKey["1"];
            const wsOneColumn = root.columnWorkspaceDelegatesByKey["1"];
            const wsTwoRow = root.rowWorkspaceDelegatesByKey["2"];
            const wsTwoColumn = root.columnWorkspaceDelegatesByKey["2"];
            assertTrue(String(wsOneRow.color) === "#303030" && String(wsOneColumn.color) === "#303030"
                    && String(wsTwoRow.color) === "#446688" && String(wsTwoColumn.color) === "#668844",
                "qml_active_focus_and_title_updates", "both row/column active colors update");
            assertTrue(entry("niri-second").focused, "qml_active_focus_and_title_updates", "focused property updates");
            const focusedKey = entry("niri-second").entryKey;
            const focusedRowDelegate = root.rowEntryDelegatesByKey[focusedKey];
            const focusedColumnDelegate = root.columnEntryDelegatesByKey[focusedKey];
            assertTrue(focusedRowDelegate && focusedColumnDelegate
                    && String(focusedRowDelegate.color).toLowerCase() === "#f0c674"
                    && String(focusedColumnDelegate.color).toLowerCase() === "#f0c674",
                "qml_active_focus_and_title_updates", "focused color binding updates in both consumers");
            pass("qml_active_focus_and_title_updates");
            waitForBindings(runEmptyTransition);
        });
    }

    function runEmptyTransition() {
        fixture.emptyWorkspaceActive = false;
        waitForBindings(function() {
            assertTrue(!workspace(3), "qml_empty_workspace_transition", "inactive empty workspace is omitted");
            fixture.emptyWorkspaceActive = true;
            waitForBindings(function() {
                const empty = workspace(3);
                assertTrue(!!empty && empty.active && empty.entries.length === 0,
                    "qml_empty_workspace_transition", "active empty workspace is visible");
                pass("qml_empty_workspace_transition");
                fixture.groupByApp = true;
                fixture.phase = "grouped";
                fixture.firstActivated = true;
                fixture.secondActivated = false;
                waitForBindings(runGroupedActions);
            });
        });
    }

    function runGroupedActions() {
        const grouped = workspace(1).entries[0];
        assertTrue(grouped && grouped.isGrouped && grouped.windows.length === 2,
            "qml_grouped_action_and_cycling", "grouped entry contains both same-app windows");
        assertTrue(grouped.toplevel === firstWindow,
            "qml_grouped_action_and_cycling", "first grouped window is representative");
        assertTrue(grouped.payloads.length === 2 && grouped.payloads[0].key.indexOf("niri-first") !== -1
                && grouped.payloads[1].key.indexOf("niri-second") !== -1
                && grouped.payloads[0].title === firstWindow.title,
            "qml_grouped_context_payloads", "grouped menu payloads expose stable keys and current titles");
        assertTrue(!workspace(2).entries[0].closeAllWindows(),
            "qml_grouped_close_all_guard", "close-all is unavailable for an ungrouped entry");
        const beforeSecondActivations = secondWindow.activations;
        firstWindow.activations = 0;
        firstWindow.closes = 0;
        firstWindowReplacement.activations = 0;
        firstWindowReplacement.closes = 0;
        secondWindow.activations = 0;
        secondWindow.closes = 0;
        fixture.phase = "replacement";
        fixture.useReplacement = true;
        fixture.reorder = true;
        fixture.firstActivated = false;
        fixture.secondActivated = true;
        waitForBindings(function() {
            const current = workspace(1).entries[0];
            root.replacementEntryRecord = current;
            assertTrue(current === grouped && current.toplevel === secondWindow,
                "qml_current_wrapper_action_targets", "group representative refreshes without entry reconstruction");
            assertTrue(current.title === secondWindow.title,
                "qml_current_wrapper_action_targets", "representative title is current");
            // Invoke the same production methods through stored row and column
            // consumers, after wrapper replacement/reorder has completed.
            const currentKey = current.entryKey;
            const rowDelegate = root.rowEntryDelegatesByKey[currentKey];
            const columnDelegate = root.columnEntryDelegatesByKey[currentKey];
            const rowRecord = rowDelegate ? rowDelegate.entryRecord : null;
            const columnRecord = columnDelegate ? columnDelegate.entryRecord : null;
            assertTrue(rowRecord === current && columnRecord === current,
                "qml_current_wrapper_action_targets", "row and column consumers retain the current record");
            const currentSecond = current.payloads.find(payload => payload.title === secondWindow.title);
            const currentReplacement = current.payloads.find(payload => payload.title === firstWindowReplacement.title);
            assertTrue(currentSecond && currentReplacement
                    && current.activateWindow(currentSecond.key)
                    && current.closeWindow(currentReplacement.key),
                "qml_context_record_methods", "keyed menu methods resolve current wrappers after replacement");
            assertTrue(secondWindow.activations === 1 && firstWindowReplacement.closes === 1,
                "qml_context_record_methods", "keyed activation and close target their payload keys");
            assertTrue(current.closeAllWindows(),
                "qml_context_record_methods", "grouped close-all accepts the current multi-window record");
            assertTrue(secondWindow.closes === 1 && firstWindowReplacement.closes === 2,
                "qml_context_record_methods", "close-all closes only windows in the current group");
            firstWindow.activations = 0;
            firstWindow.closes = 0;
            firstWindowReplacement.activations = 0;
            firstWindowReplacement.closes = 0;
            secondWindow.activations = 0;
            secondWindow.closes = 0;
            rowRecord.activateNext();
            columnRecord.closeRepresentative();
            const target = columnRecord.contextTarget();
            assertTrue(target === secondWindow,
                "qml_current_wrapper_action_targets", "actions resolve the current representative wrapper");
            assertTrue(secondWindow.activations === 1 && secondWindow.closes === 1,
                "qml_current_wrapper_action_targets", "row/column actions reached only current wrapper");
            assertTrue(firstWindow.activations === 0 && firstWindow.closes === 0
                    && firstWindowReplacement.activations === 0 && firstWindowReplacement.closes === 0,
                "qml_current_wrapper_action_targets", "old and replacement non-target spies remain unchanged");
            fixture.firstActivated = true;
            fixture.secondActivated = false;
            adapter.reconcile();
            const cycling = workspace(1).entries[0];
            const beforeCycle = secondWindow.activations;
            cycling.activateNext();
            assertTrue(secondWindow.activations === beforeCycle + 1 && firstWindow.activations === 0,
                "qml_grouped_action_and_cycling", "activated-only cycling selects the next current wrapper");
            pass("qml_grouped_action_and_cycling");
            pass("qml_current_wrapper_action_targets");
            fixture.groupByApp = false;
            fixture.removeSecond = true;
            fixture.phase = "remove";
            waitForBindings(runRemoveReadd);
        });
    }

    function runRemoveReadd() {
        const before = entry("niri-first");
        root.removedEntryRecord = before;
        fixture.removeFirst = true;
        fixture.removeSecond = false;
        fixture.phase = "remove";
        adapter.reconcile();
        assertTrue(adapter.pendingEntryCount > 0,
            "qml_remove_readd_before_flush", "removal is pending before queued flush");
        fixture.removeFirst = false;
        fixture.phase = "readd";
        adapter.reconcile();
        waitForBindings(function() {
            const after = entry("niri-first");
            assertTrue(after === before,
                "qml_remove_readd_before_flush", "record is reused when key reappears before retirement");
            assertTrue(adapter.pendingEntryCount === 0 && adapter.pendingWorkspaceCount === 0,
                "qml_remove_readd_before_flush", "pending sets clear after reuse");
            fixture.removeFirst = true;
            fixture.phase = "remove";
            adapter.reconcile();
            assertTrue(adapter.pendingEntryCount > 0,
                "qml_remove_readd_before_flush", "second removal enters pending set before flush");
            waitForBindings(function() {
                assertTrue(adapter.pendingEntryCount === 0 && adapter.pendingWorkspaceCount === 0,
                    "qml_remove_readd_before_flush", "queued retirement eventually clears pending sets");
                assertTrue(root.removedEntryRecord === null,
                    "qml_remove_readd_before_flush", "retired record was actually destroyed");
                pass("qml_remove_readd_before_flush");
                waitForBindings(runTeardown);
            });
        });
    }

    function runTeardown() {
        const lifetime = adapter._lifetime;
        const beforeGeneration = lifetime.generation;
        const entries = adapter._entryRecords;
        const pendingEntries = adapter._pendingEntries;
        const pendingWorkspaces = adapter._pendingWorkspaces;
        const entryKeys = Object.keys(entries);
        // QML var properties null their QObject references on actual deletion.
        root.removedEntryRecord = entries[entryKeys[0]];
        assertTrue(root.removedEntryRecord !== null, "qml_teardown_with_queued_reconcile", "live child exists before teardown");
        assertTrue(adapter.pendingEntryCount === 0 && adapter.pendingWorkspaceCount === 0,
            "qml_teardown_with_queued_reconcile", "pending sets are empty before destruction");
        fixture.phase = "teardown";
        fixture.emptyWorkspaceActive = false;
        fixture.firstFocused = false;
        // Keep only scalar liveness observations after destruction. Accessing a
        // destroyed QObject in a queued callback is itself a failure caught by
        // the runner, so the callback must not dereference adapter properties.
        adapter.destroy();
        fixture.firstFocused = true;
        fixture.phase = "teardown-queued-update";
        waitForBindings(function() {
            assertTrue(!lifetime.alive && lifetime.generation > beforeGeneration,
                "qml_teardown_with_queued_reconcile", "destruction invalidated the queued callback lifetime token");
            assertTrue(pendingEntries.size === 0 && pendingWorkspaces.size === 0,
                "qml_teardown_with_queued_reconcile", "destruction cleared actual pending sets");
            assertTrue(root.removedEntryRecord === null,
                "qml_teardown_with_queued_reconcile", "parent-owned entry was actually destroyed");
            pass("qml_teardown_with_queued_reconcile");
            if (failures === 0 && completedCases === 8) console.log("QML_TEST_SUITE_COMPLETE");
            else console.error("QML_TEST_FAIL:suite: " + failures + " failures");
            Qt.quit();
        });
    }

    Component.onCompleted: Qt.callLater(begin)
}
