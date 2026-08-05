import SwiftUI
import AppKit

@main
struct VACSApp: App {
    @StateObject private var model = AppModel()

    init() {
        if CommandLine.arguments.contains("--selftest") { SelfTest.run() }
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 680, minHeight: 480)
        }
    }
}
