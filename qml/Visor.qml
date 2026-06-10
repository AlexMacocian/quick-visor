import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: root

    visible: VisorService.visible
    color: "transparent"
    implicitWidth: Config.panelWidth
    implicitHeight: Config.panelHeight
    title: "Quick Visor"

    Shortcut {
        sequence: "Esc"
        context: Qt.ApplicationShortcut
        onActivated: VisorService.close()
    }

    Shortcut {
        sequence: "Q"
        context: Qt.ApplicationShortcut
        onActivated: VisorService.close()
    }

    Shortcut {
        sequence: "E"
        context: Qt.ApplicationShortcut
        onActivated: VisorService.applyLayout()
    }

    onVisibleChanged: {
        if (visible) {
            VisorService.refresh();
            Qt.callLater(() => workspace.forceActiveFocus());
        } else if (VisorService.visible) {
            VisorService.close();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.padding * 3
            spacing: Theme.spacing * 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Display layout"
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize * 1.6
                        font.bold: true
                    }

                    Text {
                        text: VisorService.status
                        color: VisorService.dirty ? Theme.accent : Theme.idle
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                ActionButton {
                    label: "Reset"
                    enabled: VisorService.dirty
                    onClicked: VisorService.resetLayout()
                }

                ActionButton {
                    label: VisorService.refreshing ? "Refreshing..." : "Refresh"
                    enabled: !VisorService.refreshing
                    onClicked: VisorService.refresh()
                }

                ActionButton {
                    label: "Apply"
                    primary: true
                    enabled: VisorService.dirty
                    onClicked: VisorService.applyLayout()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
                opacity: 0.75
            }

            FocusScope {
                id: workspace
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true

                readonly property var bounds: VisorService.layoutBounds()
                readonly property real usableWidth: Math.max(1, width - Theme.padding * 4)
                readonly property real usableHeight: Math.max(1, height - Theme.padding * 4)
                readonly property real layoutScale: Math.max(0.05, Math.min(
                    usableWidth / bounds.width,
                    usableHeight / bounds.height
                ))
                readonly property real contentWidth: bounds.width * layoutScale
                readonly property real contentHeight: bounds.height * layoutScale
                readonly property real originX: (width - contentWidth) / 2
                readonly property real originY: (height - contentHeight) / 2

                Rectangle {
                    anchors.fill: parent
                    color: Theme.overlayWeak
                    radius: Theme.radius
                    border.color: Theme.border
                    border.width: 1
                    opacity: 0.75
                }

                Text {
                    visible: VisorService.monitors.length === 0
                    anchors.centerIn: parent
                    text: "No displays detected"
                    color: Theme.idle
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Repeater {
                    model: VisorService.monitors

                    Rectangle {
                        id: monitorCard
                        required property int index
                        required property var modelData

                        readonly property bool selected: VisorService.selectedIndex === index
                        readonly property bool enabledDisplay: VisorService.monitorEnabled(modelData)
                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property real pressLogicalX: 0
                        property real pressLogicalY: 0

                        x: workspace.originX + (VisorService.monitorX(modelData) - workspace.bounds.minX) * workspace.layoutScale
                        y: workspace.originY + (VisorService.monitorY(modelData) - workspace.bounds.minY) * workspace.layoutScale
                        width: Math.max(96, VisorService.monitorLogicalWidth(modelData) * workspace.layoutScale)
                        height: Math.max(64, VisorService.monitorLogicalHeight(modelData) * workspace.layoutScale)
                        radius: Theme.radius / 1.5
                        color: dragArea.containsMouse ? Theme.overlayWeak : Theme.background
                        border.color: selected ? Theme.accent : (enabledDisplay ? Theme.border : Theme.warning)
                        border.width: selected ? 3 : 1
                        opacity: enabledDisplay ? 1.0 : 0.55

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Math.max(0, monitorCard.radius - 4)
                            color: "transparent"
                            border.color: modelData.focused ? Theme.accent : "transparent"
                            border.width: 1
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.padding * 1.5
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || "Display"
                                color: Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(11, Theme.fontSize * 1.05)
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.model || modelData.description || ""
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(10, Theme.fontSize * 0.8)
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.fillWidth: true
                                text: VisorService.formatMode(modelData)
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(10, Theme.fontSize * 0.85)
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: VisorService.formatGeometry(modelData)
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(10, Theme.fontSize * 0.8)
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: !monitorCard.enabledDisplay
                            anchors.centerIn: parent
                            implicitWidth: disabledLabel.implicitWidth + Theme.padding * 2
                            implicitHeight: disabledLabel.implicitHeight + Theme.padding
                            radius: implicitHeight / 2
                            color: Theme.background
                            border.color: Theme.warning
                            border.width: 1

                            Text {
                                id: disabledLabel
                                anchors.centerIn: parent
                                text: "Disabled"
                                color: Theme.warning
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.max(10, Theme.fontSize * 0.9)
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: mouse => {
                                VisorService.selectedIndex = monitorCard.index;
                                const p = monitorCard.mapToItem(workspace, mouse.x, mouse.y);
                                monitorCard.pressSceneX = p.x;
                                monitorCard.pressSceneY = p.y;
                                monitorCard.pressLogicalX = VisorService.monitorX(monitorCard.modelData);
                                monitorCard.pressLogicalY = VisorService.monitorY(monitorCard.modelData);
                            }

                            onPositionChanged: mouse => {
                                if (!pressed) return;
                                const p = monitorCard.mapToItem(workspace, mouse.x, mouse.y);
                                const dx = (p.x - monitorCard.pressSceneX) / workspace.layoutScale;
                                const dy = (p.y - monitorCard.pressSceneY) / workspace.layoutScale;
                                const snapped = VisorService.snappedPosition(
                                    monitorCard.modelData.name,
                                    monitorCard.pressLogicalX + dx,
                                    monitorCard.pressLogicalY + dy
                                );
                                VisorService.setMonitorPosition(
                                    monitorCard.modelData.name,
                                    snapped.x,
                                    snapped.y
                                );
                            }
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                        VisorService.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_R) {
                        VisorService.refresh();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_E) {
                        VisorService.applyLayout();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        VisorService.select(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        VisorService.select(-1);
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                id: selectedPanel

                Layout.fillWidth: true
                Layout.preferredHeight: 132
                visible: VisorService.selected !== null
                color: Theme.overlayWeak
                radius: Theme.radius
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding * 2
                    spacing: Theme.spacing * 2

                    ColumnLayout {
                        Layout.preferredWidth: 190
                        Layout.fillHeight: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: VisorService.selected ? VisorService.selected.name : ""
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize * 1.1
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: VisorService.selected ? (VisorService.selected.model || VisorService.selected.description || "") : ""
                            color: Theme.idle
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize * 0.9
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: VisorService.selected ? VisorService.formatGeometry(VisorService.selected) : ""
                            color: Theme.idle
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize * 0.85
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.spacing

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            spacing: Theme.spacing * 1.5

                            Text {
                                Layout.preferredWidth: 170
                                text: "Resolution / refresh"
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize * 0.9
                                verticalAlignment: Text.AlignVCenter
                            }

                            ComboBox {
                                id: modeCombo

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                model: VisorService.selected && Array.isArray(VisorService.selected.availableModes)
                                    ? VisorService.selected.availableModes
                                    : []
                                currentIndex: VisorService.selectedModeIndex(VisorService.selected)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                contentItem: Text {
                                    leftPadding: Theme.padding * 1.5
                                    rightPadding: Theme.padding * 3
                                    text: modeCombo.displayText
                                    color: Theme.foreground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                indicator: Text {
                                    x: modeCombo.width - width - Theme.padding
                                    y: modeCombo.topPadding + (modeCombo.availableHeight - height) / 2
                                    text: modeCombo.popup.visible ? "▲" : "▼"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize * 0.75
                                }
                                background: Rectangle {
                                    color: modeCombo.pressed ? Theme.overlayStrong : Theme.background
                                    radius: Theme.radius / 3
                                    border.color: modeCombo.activeFocus ? Theme.accent : Theme.border
                                    border.width: 1
                                }
                                delegate: ItemDelegate {
                                    width: modeCombo.width
                                    height: Math.max(30, modeText.implicitHeight + Theme.padding)
                                    highlighted: modeCombo.highlightedIndex === index

                                    background: Rectangle {
                                        color: highlighted ? Theme.overlayStrong : Theme.background
                                        radius: Theme.radius / 3
                                    }

                                    contentItem: Text {
                                        id: modeText
                                        text: modelData
                                        color: highlighted ? Theme.accent : Theme.foreground
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                onActivated: index => {
                                    if (VisorService.selected && index >= 0) {
                                        VisorService.setMonitorMode(VisorService.selected.name, model[index]);
                                    }
                                }

                                popup: Popup {
                                    y: modeCombo.height
                                    width: modeCombo.width
                                    implicitHeight: Math.min(modeList.contentHeight, 240)
                                    padding: 1

                                    background: Rectangle {
                                        color: Theme.background
                                        border.color: Theme.border
                                        border.width: 1
                                        radius: Theme.radius / 2
                                    }

                                    contentItem: ListView {
                                        id: modeList

                                        clip: true
                                        implicitHeight: contentHeight
                                        model: modeCombo.popup.visible ? modeCombo.delegateModel : null
                                        currentIndex: modeCombo.highlightedIndex
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollIndicator.vertical: ScrollIndicator {}
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            spacing: Theme.spacing * 1.5

                            Text {
                                Layout.preferredWidth: 170
                                text: "DPI / scale"
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize * 0.9
                                verticalAlignment: Text.AlignVCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing

                                ActionButton {
                                    label: "-"
                                    enabled: VisorService.selected !== null
                                    onClicked: VisorService.adjustMonitorScale(VisorService.selected.name, -0.05)
                                }

                                TextField {
                                    id: scaleInput

                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 30
                                    text: VisorService.selected ? String(Math.round(VisorService.monitorScale(VisorService.selected) * 100)) : ""
                                    enabled: VisorService.selected !== null
                                    color: Theme.foreground
                                    selectedTextColor: Theme.background
                                    selectionColor: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 50; top: 400 }
                                    background: Rectangle {
                                        color: Theme.background
                                        radius: Theme.radius / 3
                                        border.color: scaleInput.activeFocus ? Theme.accent : Theme.border
                                        border.width: 1
                                    }
                                    onEditingFinished: {
                                        if (VisorService.selected && acceptableInput) {
                                            VisorService.setMonitorScale(VisorService.selected.name, parseInt(text, 10) / 100);
                                        }
                                    }
                                }

                                Text {
                                    text: "%"
                                    color: Theme.idle
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                ActionButton {
                                    label: "+"
                                    enabled: VisorService.selected !== null
                                    onClicked: VisorService.adjustMonitorScale(VisorService.selected.name, 0.05)
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            spacing: Theme.spacing * 1.5

                            Text {
                                Layout.preferredWidth: 170
                                text: "Enabled"
                                color: Theme.idle
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize * 0.9
                                verticalAlignment: Text.AlignVCenter
                            }

                            Switch {
                                id: enabledSwitch

                                enabled: VisorService.selected !== null
                                checked: VisorService.selected ? VisorService.monitorEnabled(VisorService.selected) : false
                                onToggled: {
                                    if (VisorService.selected) {
                                        VisorService.setMonitorEnabled(VisorService.selected.name, checked);
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 46
                                    implicitHeight: 24
                                    x: enabledSwitch.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: height / 2
                                    color: enabledSwitch.checked ? Theme.accent : Theme.background
                                    border.color: enabledSwitch.checked ? Theme.accent : Theme.border
                                    border.width: 1
                                    opacity: enabledSwitch.enabled ? 1.0 : 0.45

                                    Rectangle {
                                        x: enabledSwitch.checked ? parent.width - width - 3 : 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: enabledSwitch.checked ? Theme.background : Theme.idle

                                        Behavior on x {
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }

                                contentItem: Item {
                                    implicitWidth: enabledSwitch.indicator.implicitWidth
                                    implicitHeight: enabledSwitch.indicator.implicitHeight
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Drag displays to arrange them  |  set refresh, scale, and enabled state  |  Enter apply  |  Q/Esc close"
                color: Theme.idle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize * 0.9
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }
        }
    }

    component ActionButton: Rectangle {
        id: button

        property string label: ""
        property bool primary: false
        signal clicked()

        implicitWidth: buttonLabel.implicitWidth + Theme.padding * 3
        implicitHeight: buttonLabel.implicitHeight + Theme.padding
        color: !enabled ? Theme.background : (buttonMouse.containsMouse || primary ? Theme.overlayStrong : Theme.overlayWeak)
        opacity: enabled ? 1.0 : 0.45
        radius: Theme.radius / 2
        border.color: primary && enabled ? Theme.accent : Theme.border
        border.width: 1

        Text {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.label
            color: button.primary && button.enabled ? Theme.accent : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: button.primary
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            onClicked: button.clicked()
        }
    }
}
