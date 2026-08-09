import SwiftUI
import AppKit

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if model.hasFullDiskAccess {
                GeometryReader { geo in
                    NavigationSplitView(columnVisibility: $columnVisibility) {
                        SidebarView()
                            .navigationSplitViewColumnWidth(
                                min: 220,
                                ideal: sidebarIdealWidth(for: geo.size.width),
                                max: 280
                            )
                    } detail: {
                        SectionDetailView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .navigationSplitViewStyle(.balanced)
                    .onAppear { updateColumns(width: geo.size.width) }
                    .onChange(of: geo.size.width) { _, w in updateColumns(width: w) }
                }
            } else {
                FullDiskAccessGateView()
            }
        }
        .tint(Theme.navy)
        .background(Theme.bg)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshPermission()
            model.refreshDisk()
        }
        .onAppear {
            model.refreshPermission()
            model.refreshDisk()
            model.refreshTrashSummary()
        }
        .alert(item: Binding(
            get: { model.cleanPrompt },
            set: { model.cleanPrompt = $0 }
        )) { prompt in
            Alert(
                title: Text(prompt.alertTitle),
                message: Text(prompt.alertMessage),
                primaryButton: .destructive(Text(prompt.confirmButtonTitle)) {
                    Task { await model.executeCleanPrompt(prompt) }
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    model.cancelCleanPrompt()
                }
            )
        }
        .sheet(isPresented: $model.showOnboarding) {
            OnboardingSheetView()
                .environmentObject(model)
        }
        .alert("Clean up Trash", isPresented: $model.showTrashCleanupPrompt) {
            Button("Review Trash") { model.goToTrashCleanup() }
            Button("Not now", role: .cancel) { model.dismissTrashCleanupPrompt() }
        } message: {
            Text("Your Trash holds \(ByteText.storage(model.trashTotalBytes)). Review items and empty Trash to reclaim that space.")
        }
    }

    private func updateColumns(width: CGFloat) {
        let target: NavigationSplitViewVisibility = width < 720 ? .detailOnly
            : width < 920 ? .doubleColumn
            : .all
        if columnVisibility != target {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { columnVisibility = target }
        }
    }

    private func sidebarIdealWidth(for width: CGFloat) -> CGFloat {
        if width >= 1600 { return 272 }
        if width >= 1200 { return 252 }
        return 232
    }
}
