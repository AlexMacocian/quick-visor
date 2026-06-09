import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var modelData

    screen: root.modelData
    visible: VisorService.visible && root.modelData !== undefined
    color: "transparent"
    exclusiveZone: 0
    implicitWidth: badge.implicitWidth
    implicitHeight: badge.implicitHeight

    anchors {
        left: true
        bottom: true
    }

    margins {
        left: 24
        bottom: 24
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        id: badge

        implicitWidth: content.implicitWidth + Theme.padding * 3
        implicitHeight: content.implicitHeight + Theme.padding * 2
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.accent
        border.width: 2

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.spacing

            Text {
                text: root.modelData ? root.modelData.name : ""
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize * 1.2
                font.bold: true
            }

            Text {
                visible: root.modelData && root.modelData.model.length > 0
                text: root.modelData ? root.modelData.model : ""
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
