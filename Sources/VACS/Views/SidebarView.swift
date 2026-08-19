import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 2) {
                    sectionHeader("Overview")
                    SidebarNavRow(section: .overview)

                    sectionHeader("Applications")
                    SidebarNavRow(section: .installedApps)
                    SidebarNavRow(section: .installedPackages)

                    sectionHeader("Cleanup")
                    if !visibleAdvancedTools.isEmpty {
                        sectionHeader("Advanced Tools", subtle: true)
                        ForEach(visibleAdvancedTools) { section in
                            SidebarNavRow(section: section)
                        }
                    }
                    if !visibleGeneralCleanup.isEmpty {
                        sectionHeader("More", subtle: true)
                        ForEach(visibleGeneralCleanup) { section in
                            SidebarNavRow(section: section)
                        }
                    }
                    SidebarNavRow(section: .trash)

                    sectionHeader("App")
                    SidebarNavRow(section: .about)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            SidebarStorageCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.elevated)
    }

    private var visibleAdvancedTools: [VACSection] {
        VACSection.advancedTools.filter { section in
            !model.scannedSections.contains(section) || model.totalBytes(for: section) > 0 || model.selectedSection == section
        }
    }

    private var visibleGeneralCleanup: [VACSection] {
        VACSection.generalCleanup.filter { section in
            !model.scannedSections.contains(section) || model.totalBytes(for: section) > 0 || model.selectedSection == section
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppMark(size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text("VACS")
                    .font(.system(size: 14, weight: .bold))
                Text("\(model.ruleCount) paths")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func sectionHeader(_ title: String, subtle: Bool = false) -> some View {
        Text(title.uppercased())
            .font(.system(size: subtle ? 9 : 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(subtle ? Theme.tertiaryText.opacity(0.85) : Theme.tertiaryText)
            .padding(.horizontal, 8)
            .padding(.top, subtle ? 6 : 10)
            .padding(.bottom, 4)
    }
}

// MARK: - Clickable nav row

private struct SidebarNavRow: View {
    @EnvironmentObject var model: AppModel
    let section: VACSection

    private var isSelected: Bool { model.selectedSection == section }

    var body: some View {
        Button {
            model.selectSection(section)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.navy : Theme.secondaryText)
                    .frame(width: 18, alignment: .center)

                Text(section.sidebarLabel)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                badgeText
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(SidebarNavButtonStyle(isSelected: isSelected))
    }

    @ViewBuilder
    private var badgeText: some View {
        if section == .installedApps, model.installedAppsLoaded {
            Text("\(model.installedApps.count)")
        } else if section == .installedPackages, model.installedPackagesLoaded {
            Text("\(model.installedPackages.count)")
        } else if section == .aiSkills, model.aiSkillsLoaded {
            let flagged = model.aiSkillEntries.filter(\.needsAttention).count
            if flagged > 0 {
                Text("\(flagged)")
                    .foregroundStyle(Theme.dangerRed)
            } else {
                Text("\(model.aiSkillEntries.count)")
            }
        } else if section == .trash, model.trashTotalBytes > 0 {
            Text(ByteText.storage(model.trashTotalBytes))
                .foregroundStyle(model.trashDominatesReclaimable ? Theme.dangerRed : Theme.secondaryText)
        } else if section != .overview && section != .installedApps && section != .installedPackages
                    && section != .aiSkills && section != .trash,
                  model.scannedSections.contains(section) {
            let total = model.totalBytes(for: section)
            if total > 0 {
                Text(ByteText.string(total))
            }
        }
    }
}
