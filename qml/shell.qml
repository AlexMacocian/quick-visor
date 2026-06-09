import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "quick-visor"
        function toggle(): void { VisorService.toggle(); }
        function open(): void { VisorService.open(); }
        function close(): void { VisorService.close(); }
        function refresh(): void { VisorService.refresh(); }
    }

    Visor {}

    Variants {
        model: Quickshell.screens

        ScreenLabel {}
    }
}
