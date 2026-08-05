import SwiftUI

/// Sidebar destinations — PureMac-style categories, Purge-style calm labels.
enum VACSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case installedApps = "Installed Apps"
    case developer = "Developer"
    case packageManagers = "Package Managers"
    case browserAutomation = "Browser Automation"
    case containers = "Containers & K8s"
    case aiTools = "AI Tools"
    case apps = "Apps"
    case system = "System"
    case heavyFolders = "Heavy folders"
    case trash = "Trash"
    case about = "About"

    var id: String { rawValue }

    /// Maps to the `category` field in rules.json (or discovery bucket).
    var ruleCategory: String? {
        switch self {
        case .overview, .installedApps, .about, .trash: return nil
        case .heavyFolders: return "Unknown heavy folders"
        default: return rawValue
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .installedApps: return "app.badge.fill"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .packageManagers: return "archivebox.fill"
        case .browserAutomation: return "globe.americas.fill"
        case .containers: return "shippingbox.fill"
        case .aiTools: return "sparkles"
        case .apps: return "bubble.left.and.bubble.right.fill"
        case .system: return "externaldrive.fill"
        case .heavyFolders: return "folder.badge.questionmark"
        case .trash: return "trash.fill"
        case .about: return "info.circle"
        }
    }

    var blurb: String {
        switch self {
        case .overview: return "Disk usage and reclaimable space at a glance."
        case .installedApps: return "See every file an app dropped on your Mac — caches, containers, preferences."
        case .developer: return "Xcode, simulators, IDE caches, and build artifacts."
        case .packageManagers: return "npm, Homebrew, pip, Cargo, Gradle, and other package caches."
        case .browserAutomation: return "Puppeteer, Playwright, and Selenium browser downloads."
        case .containers: return "Docker, Minikube, Colima — with the correct CLI commands."
        case .aiTools: return "LLM weights, Hugging Face, and AI IDE working data."
        case .apps: return "Zoom, Discord, Slack, and everyday app temp files."
        case .system: return "Shared app caches, logs, and browser data."
        case .heavyFolders: return "Large folders VACS doesn't recognize yet — review before removing."
        case .trash: return "Your Mac Trash — browse, restore, or permanently empty."
        case .about: return "Version, stats, and how VACS works."
        }
    }

    static var scannable: [VACSection] {
        allCases.filter { $0 != .overview && $0 != .installedApps && $0 != .about && $0 != .trash }
    }

    /// PureMac “Advanced Tools” equivalents — shown as a sidebar subgroup under Cleanup.
    static var advancedTools: [VACSection] {
        [.developer, .packageManagers, .browserAutomation, .containers, .aiTools]
    }

    static var generalCleanup: [VACSection] {
        [.apps, .system, .heavyFolders]
    }

    /// Maps PureMac Advanced Tools labels → VACS sidebar section.
    var pureMacAdvancedToolLabel: String? {
        switch self {
        case .aiTools: return "AI Apps"
        case .developer: return "Xcode Junk"
        case .packageManagers: return "Brew / Node / pip caches"
        case .containers: return "Docker Cache"
        case .browserAutomation: return "Browser automation"
        default: return nil
        }
    }

    static func section(forCategory category: String) -> VACSection? {
        if category == "Unknown heavy folders" { return .heavyFolders }
        return scannable.first { $0.ruleCategory == category }
    }

    /// Shorter labels so sidebar rows don't truncate.
    var sidebarLabel: String {
        switch self {
        case .packageManagers: return "Packages"
        case .browserAutomation: return "Browsers"
        case .containers: return "Containers"
        case .apps: return "Apps"
        case .heavyFolders: return "Heavy"
        default: return rawValue
        }
    }
}

enum SafetyFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case safe = "Safe to clean"
    case check = "Check first"

    var id: String { rawValue }

    func matches(_ safety: Safety) -> Bool {
        switch self {
        case .all: return true
        case .safe: return safety == .safe
        case .check: return safety == .check || safety == .command
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case largest = "Largest"
    case name = "Name"

    var id: String { rawValue }
}
