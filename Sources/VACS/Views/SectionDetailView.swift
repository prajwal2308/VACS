import SwiftUI

struct SectionDetailView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            if model.canNavigateBack {
                SectionBackBar()
            }

            Group {
                if model.selectedSection == .overview {
                    OverviewView()
                } else if model.selectedSection == .installedApps {
                    InstalledAppsView()
                } else if model.selectedSection == .installedPackages {
                    InstalledPackagesView()
                } else if model.selectedSection == .aiSkills {
                    AISkillsView()
                } else if model.selectedSection == .about {
                    AboutView()
                } else if model.selectedSection == .trash {
                    TrashView()
                } else {
                    CategoryDetailView()
                }
            }
        }
        .background(BackNavigationCapture())
        .id(model.selectedSection)
        .transition(.opacity)
        .animation(Theme.easeOut, value: model.selectedSection)
    }
}

private struct CategoryDetailView: View {
    @EnvironmentObject var model: AppModel

    private var section: VACSection { model.selectedSection }
    private var isScanningThis: Bool {
        model.isScanning && (model.scanningSection == section || model.scanningSection == nil)
    }
    private var hasScanned: Bool { model.hasScanned(section) }
    private var hasItems: Bool { model.itemCount(for: section) > 0 }

    var body: some View {
        VStack(spacing: 0) {
            compactHeader
            if isScanningThis {
                Spacer()
                ProgressView("Measuring…").controlSize(.small)
                Spacer()
            } else if hasScanned && hasItems {
                CategorySplitView(section: section)
            } else if hasScanned {
                emptyResultsState
            } else {
                notScannedState
            }
        }
        .background(Theme.bg)
    }

    private var compactHeader: some View {
        HStack(spacing: 10) {
            SectionIconBadge(section: section, size: 28, filled: true)
            VStack(alignment: .leading, spacing: 1) {
                Text(section.rawValue).font(.system(size: 15, weight: .semibold))
                if hasScanned && hasItems {
                    Text("\(model.itemCount(for: section)) items · \(ByteText.string(model.totalBytes(for: section)))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                } else if hasScanned {
                    Text("Scanned — nothing to clean")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text(section.blurb).font(.caption).foregroundStyle(Theme.secondaryText).lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if model.isCleaning {
                BusyIndicator(label: "Cleaning…")
            }
            Button { model.scan(section: section) } label: {
                HStack(spacing: 6) {
                    if isScanningThis {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: hasScanned ? "arrow.clockwise" : "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    Text(isScanningThis ? "Scanning…" : (hasScanned ? "Rescan" : "Scan"))
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .disabled(model.isScanning || model.isCleaning)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.card)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var notScannedState: some View {
        VStack(spacing: 12) {
            Spacer()
            SectionIconBadge(section: section, size: 36, filled: true)
            Text("Not scanned yet").font(.headline)
            Button { model.scan(section: section) } label: { Text("Scan now") }
                .buttonStyle(PrimaryPillButtonStyle())
                .disabled(model.isScanning)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            SectionIconBadge(section: section, size: 36, filled: true)
            Text("Nothing to clean here").font(.headline)
            Text("Scan finished — no matching caches found, or you already cleaned them.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button { model.scan(section: section) } label: { Text("Rescan") }
                .buttonStyle(PrimaryPillButtonStyle())
                .disabled(model.isScanning)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
