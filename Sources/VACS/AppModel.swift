import Foundation
import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var items: [ScanItem] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var scanningSection: VACSection?
    @Published var selection: Set<String> = []
    @Published var freeBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var lastCleanedBytes: Int64 = 0
    @Published var lifetimeTrashedBytes: Int64 = {
        if let s = UserDefaults.standard.string(forKey: "lifetimeTrashedBytes"), let v = Int64(s) { return v }
        return Int64(UserDefaults.standard.integer(forKey: "lifetimeTrashedBytes"))
    }()
    @Published var showOnboarding = false
    @Published var selectedSection: VACSection = .overview
    @Published var safetyFilter: SafetyFilter = .all
    @Published var sortOrder: SortOrder = .largest
    @Published var hasFullDiskAccess = false
    @Published private(set) var scannedSections: Set<VACSection> = []

    // Drill-down panel (PureMac-style)
    @Published var detailTarget: DetailTarget?
    @Published var detailGroups: [FileGroup] = []
    @Published var detailSelectedPaths: Set<String> = []
    @Published var isLoadingDetail = false
    @Published var detailBreadcrumbs: [DetailBreadcrumb] = []
    /// Installed-app root shows grouped caches/support; drilled folders show flat contents.
    @Published private(set) var detailShowsGroupedRoot = false

    // Installed apps
    @Published var installedApps: [InstalledApp] = []
    @Published var installedAppsLoaded = false
    @Published var isLoadingApps = false
    @Published var appSearchQuery = ""

    /// macOS Trash (~/.Trash) — browse, restore, or permanently delete.
    @Published var trashItems: [TrashItem] = []
    @Published var trashRestoreNotice: String?
    @Published var trashSelection: Set<String> = []
    @Published var isLoadingTrash = false
    @Published var trashTotalBytes: Int64 = 0
    @Published var trashLoaded = false

    /// Category cards selected on Overview (PureMac Smart Care).
    @Published var overviewSelectedSections: Set<VACSection> = []

    /// Shown before any trash operation — user must confirm every time.
    @Published var cleanPrompt: CleanPrompt?

    private let scanner = Scanner(rules: Scanner.loadRules())
    private let permission = PermissionChecker()

    var ruleCount: Int { scanner.rules.count }

    var reclaimableSafe: Int64 {
        items.filter { $0.safety == .safe }.reduce(0) { $0 + $1.sizeBytes }
    }

    var overviewSelectedSafeBytes: Int64 {
        overviewSelectedSections.reduce(0) { $0 + safeBytes(for: $1) }
    }

    var overviewVisibleSections: [VACSection] {
        overviewRows.map(\.section)
    }

    var overviewSelectedCount: Int {
        overviewVisibleSections.filter { overviewSelectedSections.contains($0) }.count
    }

    var overviewAllSelected: Bool {
        let visible = overviewVisibleSections
        return !visible.isEmpty && visible.allSatisfy { overviewSelectedSections.contains($0) }
    }

    func selectAllOverviewSections() {
        overviewSelectedSections = Set(overviewVisibleSections)
    }

    func deselectAllOverviewSections() {
        overviewSelectedSections = []
    }

    func recordTrashReclaimed(_ bytes: Int64) {
        guard bytes > 0 else { return }
        lastCleanedBytes += bytes
        lifetimeTrashedBytes += bytes
        UserDefaults.standard.set(String(lifetimeTrashedBytes), forKey: "lifetimeTrashedBytes")
    }

    func itemCount(for section: VACSection) -> Int {
        items(for: section).count
    }

    func cleanOverviewSelected() async {
        for section in overviewSelectedSections {
            await cleanSafe(in: section)
        }
    }

    // MARK: - Trash confirmation (always prompt before moving to Trash)

    func requestTrash(_ targets: [ScanItem]) {
        guard !targets.isEmpty else { return }
        let bytes = targets.reduce(0) { $0 + $1.sizeBytes }
        cleanPrompt = .scanItems(
            targets,
            summary: "\(targets.count) items · \(ByteText.string(bytes))"
        )
    }

    func requestTrash(_ item: ScanItem) { requestTrash([item]) }

    func requestCleanAllSafe() {
        requestTrash(items.filter { $0.safety == .safe })
    }

    func requestCleanSafeSelected() {
        requestTrash(items.filter { selection.contains($0.id) && $0.safety == .safe })
    }

    func requestCleanOverviewSelected() {
        var targets: [ScanItem] = []
        for section in overviewSelectedSections {
            targets += items(for: section).filter { $0.safety == .safe }
        }
        requestTrash(targets)
    }

    func requestCleanSelected(in section: VACSection) {
        requestTrash(items(for: section).filter { selection.contains($0.id) && $0.safety == .safe })
    }

    func requestCleanSafe(in section: VACSection) {
        requestTrash(items(for: section).filter { $0.safety == .safe })
    }

    func requestTrashDetailSelection() {
        let paths = detailSelectedPaths
        guard !paths.isEmpty else { return }
        let entries = detailGroups.flatMap(\.entries).filter { paths.contains($0.id) }
        let bytes = entries.reduce(0) { $0 + $1.sizeBytes }
        cleanPrompt = .detailPaths(
            paths: paths,
            summary: "\(entries.count) files · \(ByteText.string(bytes))"
        )
    }

    func cancelCleanPrompt() { cleanPrompt = nil }

    /// Run a confirmed clean — prompt is passed in so alert dismissal cannot clear it first.
    func executeCleanPrompt(_ prompt: CleanPrompt) async {
        cleanPrompt = nil
        isCleaning = true
        defer { isCleaning = false }

        switch prompt {
        case .scanItems(let targets, _):
            if await trashPaths(targets) > 0 { SystemSound.playMoveToTrash() }
        case .detailPaths(let paths, _):
            if await executeTrashDetail(paths: paths) > 0 { SystemSound.playMoveToTrash() }
        case .permanentlyDeleteTrash(let paths, _):
            if await permanentlyDeleteTrashItems(paths) > 0 { SystemSound.playDeletePermanently() }
        case .emptyTrash:
            if await emptyTrash() > 0 { SystemSound.playDeletePermanently() }
        }
    }

    func confirmCleanPrompt() async {
        guard let prompt = cleanPrompt else { return }
        await executeCleanPrompt(prompt)
    }

    func refreshPermission() {
        hasFullDiskAccess = permission.hasFullDiskAccess()
    }

    func refreshDisk() {
        let d = DiskInfo.homeVolume()
        freeBytes = d.free
        totalBytes = d.total
        refreshTrashSummary()
    }

    func selectSection(_ section: VACSection) {
        guard selectedSection != section else { return }
        withAnimation(Theme.easeOut) {
            selectedSection = section
            closeDetail()
        }
        if section == .installedApps && !installedAppsLoaded {
            loadInstalledApps()
        }
        if section == .trash {
            loadTrash()
        }
    }

    // MARK: - macOS Trash (browse · restore · permanent delete)

    func refreshTrashSummary() {
        guard hasFullDiskAccess else { return }
        Task.detached(priority: .utility) {
            let items = TrashScanner.listItems()
            let total = TrashScanner.totalBytes(in: items)
            await MainActor.run {
                self.trashTotalBytes = total
                if self.selectedSection == .trash, !self.isLoadingTrash {
                    self.trashItems = items
                }
            }
        }
    }

    func loadTrash() {
        guard hasFullDiskAccess else { return }
        isLoadingTrash = true
        Task.detached(priority: .userInitiated) {
            let items = TrashScanner.listItems()
            let total = TrashScanner.totalBytes(in: items)
            await MainActor.run {
                self.isLoadingTrash = false
                guard self.selectedSection == .trash else { return }
                self.trashItems = items
                self.trashTotalBytes = total
                self.trashSelection = []
                self.trashLoaded = true
            }
        }
    }

    func requestPermanentlyDeleteTrashSelection() {
        let paths = trashItems.filter { trashSelection.contains($0.id) }.map(\.path)
        guard !paths.isEmpty else { return }
        let bytes = trashItems.filter { trashSelection.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
        cleanPrompt = .permanentlyDeleteTrash(
            paths: paths,
            summary: "\(paths.count) items · \(ByteText.string(bytes))"
        )
    }

    func requestEmptyTrash() {
        guard !trashItems.isEmpty else { return }
        cleanPrompt = .emptyTrash(
            summary: "\(trashItems.count) items · \(ByteText.string(trashTotalBytes))"
        )
    }

    var trashAllSelected: Bool {
        !trashItems.isEmpty && trashSelection.count == trashItems.count
    }

    var trashPartiallySelected: Bool {
        !trashSelection.isEmpty && !trashAllSelected
    }

    func selectAllTrash() {
        trashSelection = Set(trashItems.map(\.id))
    }

    func deselectAllTrash() {
        trashSelection = []
    }

    func toggleTrashSelection(_ id: String) {
        if trashSelection.contains(id) { trashSelection.remove(id) }
        else { trashSelection.insert(id) }
    }

    func restoreTrashSelection() {
        let items = trashItems.filter { trashSelection.contains($0.id) }
        guard !items.isEmpty else { return }
        isCleaning = true
        let paths = items.map(\.path)
        Task {
            let outcome = await TrashScanner.restore(paths: paths)
            await MainActor.run {
                self.isCleaning = false
                if outcome.restored > 0 { SystemSound.playPutBack() }
                self.loadTrash()
                self.refreshDisk()
                if let message = outcome.message {
                    self.trashRestoreNotice = message
                }
            }
        }
    }

    @discardableResult
    private func permanentlyDeleteTrashItems(_ paths: [String]) async -> Int {
        guard !paths.isEmpty else { return 0 }
        let bytes = await Task.detached {
            TrashScanner.permanentlyDelete(paths: paths)
        }.value
        trashSelection.subtract(paths)
        trashItems.removeAll { paths.contains($0.id) }
        trashTotalBytes = TrashScanner.totalBytes(in: trashItems)
        if bytes > 0 { recordTrashReclaimed(bytes) }
        refreshDisk()
        return bytes > 0 ? paths.count : 0
    }

    @discardableResult
    private func emptyTrash() async -> Int {
        let paths = trashItems.map(\.path)
        return await permanentlyDeleteTrashItems(paths)
    }

    func items(for section: VACSection) -> [ScanItem] {
        guard let cat = section.ruleCategory else { return [] }
        let list = items.filter { $0.category == cat }
        switch sortOrder {
        case .largest: return list.sorted { $0.sizeBytes > $1.sizeBytes }
        case .name: return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func filteredItems(for section: VACSection) -> [ScanItem] {
        items(for: section).filter { safetyFilter.matches($0.safety) }
    }

    func totalBytes(for section: VACSection) -> Int64 {
        items(for: section).reduce(0) { $0 + $1.sizeBytes }
    }

    func safeBytes(for section: VACSection) -> Int64 {
        items(for: section).filter { $0.safety == .safe }.reduce(0) { $0 + $1.sizeBytes }
    }

    var overviewRows: [(section: VACSection, total: Int64, safe: Int64)] {
        VACSection.scannable.map { s in
            (s, totalBytes(for: s), safeBytes(for: s))
        }.filter { $0.total > 0 || scannedSections.contains($0.section) }
    }

    /// Live count while scan streams results (not only after scan finishes).
    var categoriesWithData: Int {
        Set(items.filter { $0.sizeBytes > 0 }.compactMap { VACSection.section(forCategory: $0.category) }).count
    }

    var filteredInstalledApps: [InstalledApp] {
        let q = appSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        var list = installedApps
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                ($0.bundleID?.lowercased().contains(q) ?? false)
            }
        }
        switch sortOrder {
        case .largest: return list.sorted { $0.totalBytes > $1.totalBytes }
        case .name: return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func loadInstalledApps() {
        guard !isLoadingApps else { return }
        isLoadingApps = true
        Task.detached(priority: .userInitiated) {
            let apps = AppScanner.listApps()
            await MainActor.run {
                self.installedApps = apps
                self.installedAppsLoaded = true
                self.isLoadingApps = false
            }
        }
    }

    func openScanItemDetail(_ item: ScanItem) {
        detailTarget = .scanItem(item)
        detailGroups = []
        detailSelectedPaths = []
        detailShowsGroupedRoot = false
        detailBreadcrumbs = [DetailBreadcrumb(name: item.name, path: item.path)]
        loadFolderDetail(path: item.path, ruleID: item.id, selectAll: true)
    }

    func openInstalledAppDetail(_ app: InstalledApp) {
        detailTarget = .installedApp(app)
        detailGroups = []
        detailSelectedPaths = []
        detailShowsGroupedRoot = true
        detailBreadcrumbs = [DetailBreadcrumb(name: app.name, path: app.appPath)]
        isLoadingDetail = true
        let path = app.appPath
        let bid = app.bundleID
        let name = app.name
        Task.detached(priority: .userInitiated) {
            let groups = AppScanner.relatedFiles(appPath: path, bundleID: bid, appName: name)
            await MainActor.run {
                guard case .installedApp(let current) = self.detailTarget, current.id == app.id else { return }
                self.detailGroups = groups
                self.detailSelectedPaths = Set(groups.flatMap(\.entries)
                    .filter { $0.kind != .application && !$0.requiresConfirm }
                    .map(\.id))
                self.isLoadingDetail = false
            }
        }
    }

    func drillIntoFolder(_ entry: FileEntry) {
        guard entry.isDrillable else { return }
        detailShowsGroupedRoot = false
        detailBreadcrumbs.append(DetailBreadcrumb(name: entry.name, path: entry.path))
        let ruleID: String? = {
            if detailBreadcrumbs.count == 2, case .scanItem(let item) = detailTarget { return item.id }
            return nil
        }()
        loadFolderDetail(path: entry.path, ruleID: ruleID, selectAll: false)
    }

    func detailGoBack() {
        guard detailBreadcrumbs.count > 1 else {
            closeDetail()
            return
        }
        detailBreadcrumbs.removeLast()
        reloadCurrentDetailView(selectAll: false)
    }

    func detailJumpTo(_ index: Int) {
        guard index >= 0, index < detailBreadcrumbs.count - 1 else { return }
        detailBreadcrumbs = Array(detailBreadcrumbs.prefix(index + 1))
        reloadCurrentDetailView(selectAll: false)
    }

    private func loadFolderDetail(path: String, ruleID: String?, selectAll: Bool) {
        isLoadingDetail = true
        Task.detached(priority: .userInitiated) {
            let groups = AppScanner.folderContents(path: path, ruleID: ruleID)
            await MainActor.run {
                guard self.detailBreadcrumbs.last?.path == path else { return }
                self.detailGroups = groups
                self.detailSelectedPaths = selectAll
                    ? Set(groups.flatMap(\.entries).map(\.id))
                    : []
                self.isLoadingDetail = false
            }
        }
    }

    private func reloadCurrentDetailView(selectAll: Bool) {
        guard let current = detailBreadcrumbs.last else { return }
        if detailBreadcrumbs.count == 1, case .installedApp(let app) = detailTarget {
            detailShowsGroupedRoot = true
            isLoadingDetail = true
            let path = app.appPath
            let bid = app.bundleID
            let name = app.name
            Task.detached(priority: .userInitiated) {
                let groups = AppScanner.relatedFiles(appPath: path, bundleID: bid, appName: name)
                await MainActor.run {
                    guard case .installedApp(let current) = self.detailTarget, current.id == app.id else { return }
                    self.detailGroups = groups
                    if selectAll {
                        self.detailSelectedPaths = Set(groups.flatMap(\.entries).map(\.id))
                    }
                    self.isLoadingDetail = false
                }
            }
            return
        }
        detailShowsGroupedRoot = false
        let ruleID: String? = {
            if detailBreadcrumbs.count == 1, case .scanItem(let item) = detailTarget { return item.id }
            return nil
        }()
        loadFolderDetail(path: current.path, ruleID: ruleID, selectAll: selectAll)
    }

    func closeDetail() {
        detailTarget = nil
        detailGroups = []
        detailSelectedPaths = []
        detailBreadcrumbs = []
        detailShowsGroupedRoot = false
    }

    func trashDetailSelection() async {
        await executeTrashDetail(paths: detailSelectedPaths)
    }

    @discardableResult
    private func executeTrashDetail(paths: Set<String>) async -> Int {
        guard !paths.isEmpty else { return 0 }
        let urls = paths.map { URL(fileURLWithPath: $0) }
        let reclaimed = detailGroups.flatMap(\.entries)
            .filter { paths.contains($0.id) }
            .reduce(0) { $0 + $1.sizeBytes }

        let mapping: [URL: URL] = await withCheckedContinuation { cont in
            NSWorkspace.shared.recycle(urls) { result, _ in
                cont.resume(returning: result)
            }
        }
        TrashOriginStore.recordRecycleResult(mapping)
        let trashed = Set(mapping.keys.map(\.path))

        guard !trashed.isEmpty else { return 0 }

        // Refresh detail after trash
        if case .installedApp = detailTarget {
            loadInstalledApps()
        } else if case .scanItem(let item) = detailTarget {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                let old = items[idx]
                let newSize = Shell.size(item.path)
                if newSize > 0 {
                    items[idx] = ScanItem(
                        id: old.id, name: old.name, path: old.path,
                        category: old.category, safety: old.safety,
                        note: old.note, command: old.command,
                        sizeBytes: newSize, known: old.known
                    )
                } else {
                    items.remove(at: idx)
                    closeDetail()
                    recordTrashReclaimed(reclaimed)
                    refreshDisk()
                    return trashed.count
                }
            }
        }
        reloadCurrentDetailView(selectAll: false)
        detailSelectedPaths.subtract(trashed)
        recordTrashReclaimed(reclaimed)
        refreshDisk()
        return trashed.count
    }

    func scan(section: VACSection? = nil) {
        guard !isScanning, hasFullDiskAccess else { return }
        closeDetail()
        isScanning = true
        scanningSection = section
        refreshDisk()

        if let section, section != .overview {
            items.removeAll { $0.category == section.ruleCategory }
        } else {
            items = []
            selection = []
            scannedSections = []
        }

        let scanner = self.scanner
        let mode: ScanMode = {
            if section == nil { return .all }
            if section == .heavyFolders { return .discoveryOnly }
            if let cat = section?.ruleCategory { return .category(cat) }
            return .all
        }()

        Task {
            for await item in Self.scanStream(scanner: scanner, mode: mode) {
                insert(item)
            }
            if let section, section != .overview {
                self.scannedSections.insert(section)
                for item in self.items(for: section) where item.safety == .safe {
                    self.selection.insert(item.id)
                }
            } else {
                self.scannedSections = Set(VACSection.scannable)
                self.overviewSelectedSections = Set(
                    VACSection.scannable.filter { self.safeBytes(for: $0) > 0 }
                )
                for item in self.items where item.safety == .safe {
                    self.selection.insert(item.id)
                }
            }
            self.isScanning = false
            self.scanningSection = nil
            self.refreshDisk()
        }
    }

    private func insert(_ item: ScanItem) {
        items.removeAll { $0.id == item.id }
        items.append(item)
        if let section = VACSection.section(forCategory: item.category) {
            scannedSections.insert(section)
        }
    }

    private enum ScanMode {
        case all
        case category(String)
        case discoveryOnly
    }

    private nonisolated static func scanStream(
        scanner: Scanner,
        mode: ScanMode
    ) -> AsyncStream<ScanItem> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) {
                var knownPaths = Set<String>()
                switch mode {
                case .all:
                    scanner.scanKnown(categories: nil) { item in
                        knownPaths.insert(item.path)
                        continuation.yield(item)
                    }
                    ProjectScanner.scan { continuation.yield($0) }
                    scanner.scanUnknown(knownPaths: knownPaths) { continuation.yield($0) }
                case .category(let cat):
                    scanner.scanKnown(categories: Set([cat])) { item in
                        knownPaths.insert(item.path)
                        continuation.yield(item)
                    }
                    if cat == "Developer" {
                        ProjectScanner.scan { continuation.yield($0) }
                    }
                case .discoveryOnly:
                    for rule in scanner.rules {
                        knownPaths.insert(PathUtil.expand(rule.path))
                    }
                    scanner.scanUnknown(knownPaths: knownPaths) { continuation.yield($0) }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Actions

    func copyCommand(_ item: ScanItem) {
        guard let cmd = item.command else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
    }

    func trash(_ item: ScanItem) async { await trashPaths([item]) }

    func cleanSafe(in section: VACSection) async {
        let targets = items(for: section).filter { $0.safety == .safe }
        await trashPaths(targets)
    }

    func cleanSafeSelected() async {
        let targets = items.filter { selection.contains($0.id) && $0.safety == .safe }
        await trashPaths(targets)
    }

    func cleanAllSafe() async {
        let targets = items.filter { $0.safety == .safe }
        await trashPaths(targets)
    }

    func cleanSelected(in section: VACSection) async {
        let targets = items(for: section).filter { selection.contains($0.id) && $0.safety == .safe }
        await trashPaths(targets)
    }

    func selectAll(in section: VACSection, filter: SafetyFilter? = nil) {
        let f = filter ?? safetyFilter
        for item in items(for: section) where f.matches(item.safety) {
            selection.insert(item.id)
        }
    }

    func deselectAll(in section: VACSection) {
        for item in items(for: section) { selection.remove(item.id) }
    }

    func selectedCount(in section: VACSection) -> Int {
        items(for: section).filter { selection.contains($0.id) }.count
    }

    func selectedSafeBytes(in section: VACSection) -> Int64 {
        items(for: section)
            .filter { selection.contains($0.id) && $0.safety == .safe }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    @discardableResult
    private func trashPaths(_ targets: [ScanItem]) async -> Int {
        guard !targets.isEmpty else { return 0 }
        let urls = targets.map { URL(fileURLWithPath: $0.path) }

        let mapping: [URL: URL] = await withCheckedContinuation { cont in
            NSWorkspace.shared.recycle(urls) { result, _ in
                cont.resume(returning: result)
            }
        }
        TrashOriginStore.recordRecycleResult(mapping)
        let trashed = Set(mapping.keys.map(\.path))

        let removedIDs = Set(targets.filter { trashed.contains($0.path) }.map(\.id))
        guard !removedIDs.isEmpty else { return 0 }
        let reclaimed = targets.filter { removedIDs.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
        items.removeAll { removedIDs.contains($0.id) }
        selection.subtract(removedIDs)
        recordTrashReclaimed(reclaimed)
        refreshDisk()
        refreshTrashSummary()
        return removedIDs.count
    }
}
