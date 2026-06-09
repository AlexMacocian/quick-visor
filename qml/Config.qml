pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14
    property int panelWidth: 760
    property int panelHeight: 520

    property bool loaded: false

    function _apply(obj) {
        if (typeof obj.panelWidth === "number" && obj.panelWidth > 0) panelWidth = obj.panelWidth;
        if (typeof obj.panelHeight === "number" && obj.panelHeight > 0) panelHeight = obj.panelHeight;
    }

    property Process _loader: Process {
        running: true
        command: ["sh", "-c", "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/quick-visor/config.json\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = (this.text || "").trim();
                if (text.length > 0) {
                    try {
                        root._apply(JSON.parse(text));
                    } catch (e) {
                        console.log("quick-visor: config.json parse error:", e);
                    }
                }
                root.loaded = true;
            }
        }
    }
}
