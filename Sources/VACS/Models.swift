import Foundation
import AppKit

/// How the app is allowed to act on an item.
enum Safety: String, Codable, CaseIterable, Sendable {
    case safe, check, command, never

    var label: String {
        switch self {
        case .safe: return "Safe to clean"
        case .check: return "Check first"
        case .command: return "Use command"
        case .never: return "Keep"
        }
    }
}

struct Rule: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let path: String
    let category: String
    let safety: Safety
    let note: String
    var command: String? = nil
}

struct ScanItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let path: String
    let category: String
    let safety: Safety
    let note: String
    let command: String?
    var sizeBytes: Int64
    let known: Bool

    var sizeText: String { ByteText.string(sizeBytes) }
}

// MARK: - Installed apps + drill-down panel (PureMac-style)

enum FileGroupKind: String, CaseIterable, Identifiable {
    case application = "Application"
    case caches = "Caches"
    case applicationSupport = "Application Support"
    case preferences = "Preferences"
    case containers = "Containers"
    case logs = "Logs"
    case savedState = "Saved Application State"
    case webKit = "WebKit"
    case contents = "Contents"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .application: return "app.fill"
        case .caches: return "externaldrive.fill"
        case .applicationSupport: return "folder.fill"
        case .preferences: return "gearshape.fill"
        case .containers: return "shippingbox.fill"
        case .logs: return "doc.text.fill"
        case .savedState: return "clock.arrow.circlepath"
        case .webKit: return "globe"
        case .contents: return "folder"
        }
    }
}

struct FileEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let sizeBytes: Int64
    let kind: FileGroupKind
    /// `.app` bundles and Apple system apps need extra confirmation.
    let requiresConfirm: Bool
    let isDirectory: Bool

    var sizeText: String { ByteText.string(sizeBytes) }
    var isDrillable: Bool { isDirectory }
}

struct FileGroup: Identifiable {
    let kind: FileGroupKind
    var entries: [FileEntry]

    var id: String { kind.rawValue }
    var totalBytes: Int64 { entries.reduce(0) { $0 + $1.sizeBytes } }
}

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String?
    let appPath: String
    var totalBytes: Int64
    var fileCount: Int
    let isSystemApp: Bool

    var sizeText: String { ByteText.string(totalBytes) }
}

/// What the right-hand detail panel is showing.
enum DetailTarget: Equatable {
    case scanItem(ScanItem)
    case installedApp(InstalledApp)
}

struct DetailBreadcrumb: Hashable {
    let name: String
    let path: String
}

/// User must confirm before any trash operation.
enum CleanPrompt: Identifiable, Equatable {
    case scanItems([ScanItem], summary: String)
    case detailPaths(paths: Set<String>, summary: String)
    case permanentlyDeleteTrash(paths: [String], summary: String)
    case emptyTrash(summary: String)

    var id: String {
        switch self {
        case .scanItems(let items, _): return "scan:\(items.map(\.id).joined())"
        case .detailPaths(let paths, _): return "detail:\(paths.sorted().joined())"
        case .permanentlyDeleteTrash(let paths, _): return "trash-del:\(paths.sorted().joined())"
        case .emptyTrash: return "trash-empty"
        }
    }

    var summary: String {
        switch self {
        case .scanItems(_, let s), .detailPaths(_, let s),
             .permanentlyDeleteTrash(_, let s), .emptyTrash(let s): return s
        }
    }

    var alertTitle: String {
        switch self {
        case .permanentlyDeleteTrash: return "Delete permanently?"
        case .emptyTrash: return "Empty Trash permanently?"
        default: return "Move to Trash?"
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .emptyTrash: return "Empty Trash"
        case .permanentlyDeleteTrash: return "Delete Permanently"
        default: return "Move to Trash"
        }
    }

    var alertMessage: String {
        switch self {
        case .scanItems(_, let s):
            return "Move \(s) to the Trash? You can restore them until you empty the Trash."
        case .detailPaths(_, let s):
            return "Move \(s) to the Trash? You can restore them until you empty the Trash."
        case .permanentlyDeleteTrash(_, let s):
            return """
            \(s)

            These items are already in your Mac Trash. Deleting them here removes them forever — they will NOT move to Trash again.

            This cannot be undone.
            """
        case .emptyTrash(let s):
            return """
            \(s)

            This permanently deletes everything in your Mac Trash — the same as Finder → Empty Trash.

            Files cannot be recovered after this. VACS will not send them anywhere else; they are erased from disk.

            Make sure you have reviewed each item below before continuing.
            """
        }
    }
}

enum ByteText {
    /// Binary (1024) — cache sizes from `du`.
    static func string(_ bytes: Int64) -> String {
        format(bytes, divisor: 1024)
    }

    /// Decimal (1000) — whole-disk stats to match **System Settings → Storage**.
    static func storage(_ bytes: Int64) -> String {
        format(bytes, divisor: 1000)
    }

    private static func format(_ bytes: Int64, divisor: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var idx = 0
        while value >= divisor && idx < units.count - 1 {
            value /= divisor
            idx += 1
        }
        return idx == 0
            ? "\(Int(value)) \(units[idx])"
            : String(format: "%.1f %@", value, units[idx])
    }
}
