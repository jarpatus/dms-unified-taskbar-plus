import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import qs.Modals.FileBrowser

PluginSettings {
    id: root
    pluginId: "unifiedTaskbarPlus"

    ToggleSetting {
        settingKey: "compactMode"
        label: "Compact Mode"
        description: "Show only app icons without window titles"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "groupByApp"
        label: "Group by App"
        description: "Collapse multiple windows of the same app into one entry with a count badge"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "allMonitors"
        label: "Show All Monitors"
        description: "Show workspaces from all monitors instead of only the current one"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "reverseMonitorOrder"
        label: "Reverse Monitor Order"
        description: "Reverse the order in which monitors are displayed when showing all monitors"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "filledPills"
        label: "Filled Pills (Vertical)"
        description: "Use solid filled workspace pills instead of outlined borders"
        defaultValue: false
    }

    SliderSetting {
        settingKey: "iconPadding"
        label: "Icon Padding"
        minimum: 0
        maximum: 10
        defaultValue: 4
    }

    SliderSetting {
        settingKey: "itemSpacing"
        label: "Item Spacing"
        minimum: 0
        maximum: 10
        defaultValue: 2
    }

    SliderSetting {
        settingKey: "workspaceSpacing"
        label: "Workspace Spacing"
        description: "Space between workspace pills"
        minimum: 0
        maximum: 20
        defaultValue: 4
    }

    SliderSetting {
        settingKey: "titleWidth"
        label: "Title Width"
        description: "Width reserved for the window title (non-compact mode)"
        minimum: 40
        maximum: 300
        defaultValue: 120
    }

    Column {
        id: rewriteEditor
        width: parent.width
        spacing: Theme.spacingS

        property var rewriteRules: root.loadValue("titleRewrites", [])

        function persist(next) {
            rewriteRules = next;
            root.saveValue("titleRewrites", next);
        }

        function iconUrl(path) {
            if (!path) return "";
            return path.indexOf("://") < 0 ? "file://" + path : path;
        }

        Text {
            text: "Title/Icon Overrides"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        Text {
            text: "Regex match on window title; replaces the shown title and icon"
            font.pixelSize: 11
            color: Theme.withAlpha(Theme.surfaceText, 0.7)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Item {
            width: parent.width
            height: 32

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DankTextField {
                    id: matchField
                    width: 180
                    height: 32
                    placeholderText: "Match (regex)"
                }

                DankTextField {
                    id: titleField
                    width: 130
                    height: 32
                    placeholderText: "Title"
                }

                DankTextField {
                    id: iconField
                    visible: false
                    width: 0
                    height: 32
                }

                Image {
                    width: 32
                    height: 32
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: iconField.text.length > 0
                    source: rewriteEditor.iconUrl(iconField.text)
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.cornerRadius
                    color: browseArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.15) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "folder_open"
                        size: 16
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: browseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: iconBrowser.open()
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 50
                height: 32
                radius: Theme.cornerRadius
                color: addArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.8) : Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: "Add"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!titleField.text || !matchField.text) return;
                        rewriteEditor.persist([{ title: titleField.text, icon: iconField.text, pattern: matchField.text }].concat(rewriteEditor.rewriteRules));
                        titleField.text = "";
                        iconField.text = "";
                        matchField.text = "";
                    }
                }
            }
        }

        FileBrowserModal {
            id: iconBrowser
            browserTitle: "Select Icon"
            browserIcon: "image"
            fileExtensions: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.ico"]
            onFileSelected: path => iconField.text = path
        }

        Repeater {
            model: rewriteEditor.rewriteRules

            Rectangle {
                width: rewriteEditor.width
                height: 44
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Image {
                    id: rowIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: !!modelData.icon
                    source: rewriteEditor.iconUrl(modelData.icon)
                }

                Column {
                    anchors.left: rowIcon.visible ? rowIcon.right : parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: removeButton.left
                    anchors.rightMargin: Theme.spacingM

                    Text {
                        text: modelData.title
                        color: Theme.surfaceText
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: modelData.pattern
                        color: Theme.withAlpha(Theme.surfaceText, 0.6)
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Rectangle {
                    id: removeButton
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 13
                    color: removeArea.containsMouse ? Theme.errorPressed : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "delete"
                        size: 14
                        color: removeArea.containsMouse ? Theme.error : Theme.surfaceText
                    }

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rewriteEditor.persist(rewriteEditor.rewriteRules.filter(function (_, i) { return i !== index; }))
                    }
                }
            }
        }
    }
}
