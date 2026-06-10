pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool visible: true
    property int selectedIndex: 0
    property var monitors: []
    property var arrangedPositions: ({})
    property var monitorSettings: ({})
    readonly property var selected: monitors.length > 0 ? monitors[selectedIndex] : null
    property string status: "Loading displays..."
    property bool refreshing: false
    property bool dirty: false

    function open() {
        visible = true;
        refresh();
    }

    function close() {
        visible = false;
        Qt.callLater(Qt.quit);
    }

    function toggle() {
        visible ? close() : open();
    }

    function refresh() {
        if (refreshing) return;
        refreshing = true;
        status = "Refreshing displays...";
        monitorProc.running = true;
    }

    function select(delta) {
        if (monitors.length === 0) return;
        selectedIndex = Math.max(0, Math.min(monitors.length - 1, selectedIndex + delta));
    }

    function selectedMonitor() {
        return selected;
    }

    function monitorX(m) {
        const pos = arrangedPositions[m.name];
        return pos ? pos.x : m.x;
    }

    function monitorY(m) {
        const pos = arrangedPositions[m.name];
        return pos ? pos.y : m.y;
    }

    function monitorMode(m) {
        const settings = monitorSettings[m.name];
        return settings && settings.mode ? settings.mode : currentModeString(m);
    }

    function monitorScale(m) {
        const settings = monitorSettings[m.name];
        return settings && typeof settings.scale === "number" ? settings.scale : m.scale;
    }

    function monitorEnabled(m) {
        const settings = monitorSettings[m.name];
        return settings && typeof settings.enabled === "boolean" ? settings.enabled : !m.disabled;
    }

    function enabledMonitorCount() {
        let count = 0;
        for (let i = 0; i < monitors.length; i++) {
            if (monitorEnabled(monitors[i])) count++;
        }
        return count;
    }

    function parsedMode(mode) {
        const match = String(mode || "").match(/^(\d+)x(\d+)(?:@([\d.]+)(?:Hz)?)?$/);
        if (!match) return null;
        return {
            width: parseInt(match[1], 10),
            height: parseInt(match[2], 10),
            refresh: match[3] ? parseFloat(match[3]) : null
        };
    }

    function monitorWidth(m) {
        const parsed = parsedMode(monitorMode(m));
        return parsed ? parsed.width : m.width;
    }

    function monitorHeight(m) {
        const parsed = parsedMode(monitorMode(m));
        return parsed ? parsed.height : m.height;
    }

    function monitorTransform(m) {
        return m && typeof m.transform === "number" ? m.transform : 0;
    }

    function monitorLogicalWidth(m) {
        const scale = monitorScale(m) || 1;
        const rotated = (monitorTransform(m) % 2) === 1;
        const pixels = rotated ? monitorHeight(m) : monitorWidth(m);
        return Math.round(pixels / scale);
    }

    function monitorLogicalHeight(m) {
        const scale = monitorScale(m) || 1;
        const rotated = (monitorTransform(m) % 2) === 1;
        const pixels = rotated ? monitorWidth(m) : monitorHeight(m);
        return Math.round(pixels / scale);
    }

    function currentModeString(m) {
        const modes = Array.isArray(m.availableModes) ? m.availableModes : [];
        let best = "";
        let bestDelta = Number.POSITIVE_INFINITY;
        for (let i = 0; i < modes.length; i++) {
            const parsed = parsedMode(modes[i]);
            if (!parsed || parsed.width !== m.width || parsed.height !== m.height || parsed.refresh === null) continue;
            const delta = Math.abs(parsed.refresh - m.refreshRate);
            if (delta < bestDelta) {
                bestDelta = delta;
                best = modes[i];
            }
        }
        if (best.length > 0) return best;
        if (modes.length > 0) return modes[0];

        const refresh = typeof m.refreshRate === "number"
            ? "@" + (Math.round(m.refreshRate * 1000) / 1000) : "";
        return m.width + "x" + m.height + refresh;
    }

    function modeForHyprland(mode) {
        return String(mode || "").replace(/Hz$/, "");
    }

    function setMonitorMode(name, mode) {
        if (!mode || mode.length === 0) return;
        const next = Object.assign({}, monitorSettings);
        const current = Object.assign({}, next[name] || {});
        current.mode = mode;
        next[name] = current;
        monitorSettings = next;
        dirty = true;
        status = "Display mode changed - apply to update Hyprland";
    }

    function setMonitorScale(name, scale) {
        const clamped = Math.max(0.5, Math.min(4.0, Math.round(scale * 100) / 100));
        const next = Object.assign({}, monitorSettings);
        const current = Object.assign({}, next[name] || {});
        current.scale = clamped;
        next[name] = current;
        monitorSettings = next;
        dirty = true;
        status = "Display scale changed - apply to update Hyprland";
    }

    function setMonitorEnabled(name, enabled) {
        if (!enabled && enabledMonitorCount() <= 1) {
            status = "At least one display must stay enabled";
            return;
        }

        const next = Object.assign({}, monitorSettings);
        const current = Object.assign({}, next[name] || {});
        current.enabled = enabled;
        next[name] = current;
        monitorSettings = next;
        dirty = true;
        status = enabled
            ? "Display enabled - apply to update Hyprland"
            : "Display disabled - apply to update Hyprland";
    }

    function adjustMonitorScale(name, delta) {
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            if (m.name === name) {
                setMonitorScale(name, monitorScale(m) + delta);
                return;
            }
        }
    }

    function selectedModeIndex(m) {
        if (!m || !Array.isArray(m.availableModes)) return -1;
        const mode = monitorMode(m);
        for (let i = 0; i < m.availableModes.length; i++) {
            if (m.availableModes[i] === mode) return i;
        }
        return -1;
    }

    function setMonitorPosition(name, x, y) {
        const next = Object.assign({}, arrangedPositions);
        next[name] = { x: Math.round(x), y: Math.round(y) };
        arrangedPositions = next;
        dirty = true;
        status = "Layout changed - apply to update Hyprland";
    }

    function snappedPosition(name, x, y) {
        let monitor = null;
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name) {
                monitor = monitors[i];
                break;
            }
        }
        if (!monitor) return { x, y };

        const snapDistance = 48;
        let bestX = x;
        let bestY = y;
        let bestDx = snapDistance + 1;
        let bestDy = snapDistance + 1;
        const left = x;
        const width = monitorLogicalWidth(monitor);
        const height = monitorLogicalHeight(monitor);
        const right = x + width;
        const top = y;
        const bottom = y + height;

        for (let i = 0; i < monitors.length; i++) {
            const other = monitors[i];
            if (other.name === name) continue;

            const otherLeft = monitorX(other);
            const otherRight = otherLeft + monitorLogicalWidth(other);
            const otherTop = monitorY(other);
            const otherBottom = otherTop + monitorLogicalHeight(other);

            const xCandidates = [
                { value: otherLeft, delta: Math.abs(left - otherLeft) },
                { value: otherRight, delta: Math.abs(left - otherRight) },
                { value: otherLeft - width, delta: Math.abs(right - otherLeft) },
                { value: otherRight - width, delta: Math.abs(right - otherRight) }
            ];

            for (let xi = 0; xi < xCandidates.length; xi++) {
                const candidate = xCandidates[xi];
                if (candidate.delta < bestDx && candidate.delta <= snapDistance) {
                    bestDx = candidate.delta;
                    bestX = candidate.value;
                }
            }

            const yCandidates = [
                { value: otherTop, delta: Math.abs(top - otherTop) },
                { value: otherBottom, delta: Math.abs(top - otherBottom) },
                { value: otherTop - height, delta: Math.abs(bottom - otherTop) },
                { value: otherBottom - height, delta: Math.abs(bottom - otherBottom) }
            ];

            for (let yi = 0; yi < yCandidates.length; yi++) {
                const candidate = yCandidates[yi];
                if (candidate.delta < bestDy && candidate.delta <= snapDistance) {
                    bestDy = candidate.delta;
                    bestY = candidate.value;
                }
            }
        }

        return { x: bestX, y: bestY };
    }

    function resetLayout() {
        const nextPositions = {};
        const nextSettings = {};
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            nextPositions[m.name] = { x: m.x, y: m.y };
            nextSettings[m.name] = { mode: currentModeString(m), scale: m.scale, enabled: !m.disabled };
        }
        arrangedPositions = nextPositions;
        monitorSettings = nextSettings;
        dirty = false;
        status = monitors.length + " display" + (monitors.length === 1 ? "" : "s") + " connected";
    }

    function layoutBounds() {
        if (monitors.length === 0) return { minX: 0, minY: 0, maxX: 1, maxY: 1, width: 1, height: 1 };

        let minX = Number.POSITIVE_INFINITY;
        let minY = Number.POSITIVE_INFINITY;
        let maxX = Number.NEGATIVE_INFINITY;
        let maxY = Number.NEGATIVE_INFINITY;

        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            const x = monitorX(m);
            const y = monitorY(m);
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + monitorLogicalWidth(m));
            maxY = Math.max(maxY, y + monitorLogicalHeight(m));
        }

        return {
            minX,
            minY,
            maxX,
            maxY,
            width: Math.max(1, maxX - minX),
            height: Math.max(1, maxY - minY)
        };
    }

    function shQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    readonly property string monitorConfPath: "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.conf"

    function monitorSpec(m) {
        if (monitorEnabled(m)) {
            return m.name + "," + modeForHyprland(monitorMode(m)) + ","
                + monitorX(m) + "x" + monitorY(m) + "," + monitorScale(m);
        }
        return m.name + ",disable";
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function monitorConfContent() {
        const now = new Date();
        const stamp = now.getFullYear() + "-" + pad2(now.getMonth() + 1) + "-" + pad2(now.getDate())
            + " at " + pad2(now.getHours()) + ":" + pad2(now.getMinutes()) + ":" + pad2(now.getSeconds());
        let body = "# Generated by quick-visor on " + stamp + ". Do not edit manually.\n\n";
        for (let i = 0; i < monitors.length; i++) {
            body += "monitor=" + monitorSpec(monitors[i]) + "\n";
        }
        return body;
    }

    function applyLayout() {
        if (!dirty || monitors.length === 0) return;

        const enableCommands = [];
        const disableCommands = [];
        const dpmsCommands = [];
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            const command = "hyprctl keyword monitor " + shQuote(monitorSpec(m));
            if (monitorEnabled(m)) {
                enableCommands.push(command);
                // Enabling a monitor that was previously off leaves DPMS off
                // (blank/grey panel, invisible cursor), so force it on.
                dpmsCommands.push("hyprctl dispatch dpms on " + shQuote(m.name));
            } else {
                disableCommands.push(command);
            }
        }

        const commands = enableCommands.concat(disableCommands).concat(dpmsCommands);
        if (commands.length === 0) return;

        // Persist to the Hyprland-sourced monitors.conf, but only if it already exists.
        const persist = "CONF=\"" + monitorConfPath + "\"; "
            + "if [ -f \"$CONF\" ]; then printf '%s' " + shQuote(monitorConfContent()) + " > \"$CONF\"; fi";
        const script = commands.join(" && ") + " && { " + persist + "; }";

        status = "Applying layout...";
        applyProc.command = ["sh", "-c", script];
        applyProc.running = true;
    }

    function formatGeometry(m) {
        if (!m) return "";
        const scale = typeof monitorScale(m) === "number" ? " @ " + monitorScale(m) + "x" : "";
        return monitorWidth(m) + "x" + monitorHeight(m) + "+"
            + monitorX(m) + "+" + monitorY(m) + scale;
    }

    function formatMode(m) {
        if (!m) return "";
        return monitorMode(m);
    }

    property Process monitorProc: Process {
        command: ["sh", "-c", "hyprctl monitors all -j 2>/dev/null || printf '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshing = false;
                try {
                    const parsed = JSON.parse(this.text || "[]");
                    root.monitors = Array.isArray(parsed) ? parsed : [];
                    if (root.selectedIndex >= root.monitors.length) {
                        root.selectedIndex = Math.max(0, root.monitors.length - 1);
                    }
                    root.resetLayout();
                    if (root.monitors.length === 0) {
                        root.status = "No Hyprland displays reported";
                    }
                } catch (e) {
                    root.monitors = [];
                    root.arrangedPositions = {};
                    root.monitorSettings = {};
                    root.dirty = false;
                    root.status = "Could not read Hyprland displays";
                    console.log("quick-visor: hyprctl monitors parse error:", e);
                }
            }
        }
    }

    property Process applyProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.dirty = false;
                root.status = "Layout applied";
                root.refresh();
            }
        }
    }

    Component.onCompleted: refresh()
}
