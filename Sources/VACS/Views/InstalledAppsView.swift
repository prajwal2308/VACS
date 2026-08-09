import SwiftUI
import AppKit

struct InstalledAppsView: View {
    @EnvironmentObject var model: AppModel

    private var hasDetail: Bool {
        if case .installedApp = model.detailTarget { return true }
        return false
    }

    var body: some View {
        Group {
            if hasDetail {
                HSplitView {
                    appListPane.frame(minWidth: 260, idealWidth: 320)
                    detailPane
                        .frame(minWidth: 300)
                        .detailTransition(active: hasDetail)
                }
            } else {
                appListPane
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .onAppear {
            if !model.installedAppsLoaded { model.loadInstalledApps() }
        }
    }

    private var appListPane: some View {
        VStack(spacing: 0) {
            compactHeader

            HStack {
                Text("\(model.filteredInstalledApps.count) apps")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Picker("Sort", selection: $model.sortOrder) {
                    ForEach(SortOrder.allCases) { s in Text(s.rawValue).tag(s) }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            if model.isLoadingApps && !model.installedAppsLoaded {
                ScrollView {
                    SkeletonAppGrid()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 128, maximum: 156), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(model.filteredInstalledApps) { app in
                            appTile(app)
                        }
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var compactHeader: some View {
        TabHeaderWithCenteredSearch(
            leading: {
                HStack(spacing: 10) {
                    SectionIconBadge(section: .installedApps, size: 28, filled: true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Installed Apps")
                            .font(.system(size: 15, weight: .semibold))
                        if model.installedAppsLoaded {
                            Text("\(model.installedApps.count) apps")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            },
            placeholder: "Search apps",
            searchText: $model.appSearchQuery,
            trailing: {
                Button { model.loadInstalledApps() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(SecondaryOutlineButtonStyle())
                .disabled(model.isLoadingApps)
            }
        )
    }

    @ViewBuilder
    private func appTile(_ app: InstalledApp) -> some View {
        let selected: Bool = {
            if case .installedApp(let a) = model.detailTarget { return a.id == app.id }
            return false
        }()

        Button { model.openInstalledAppDetail(app) } label: {
            VStack(spacing: 6) {
                Image(nsImage: AppScanner.appIcon(for: app.appPath))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                Text(app.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.primaryText)
                Text(app.sizeText)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                if let label = app.modifiedLabel {
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.tertiaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                selected ? Theme.navy.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Theme.navy.opacity(0.35) : Theme.hairline.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detailPane: some View {
        if case .installedApp(let app) = model.detailTarget {
            DetailPanelView(
                title: app.name, subtitle: app.bundleID,
                icon: AppScanner.appIcon(for: app.appPath), systemIcon: nil,
                groups: model.detailGroups,
                selectedPaths: $model.detailSelectedPaths,
                isLoading: model.isLoadingDetail,
                installedApp: app
            )
        }
    }
}
