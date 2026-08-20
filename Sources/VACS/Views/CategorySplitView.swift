import SwiftUI

struct CategorySplitView: View {
    @EnvironmentObject var model: AppModel
    let section: VACSection

    private var rows: [ScanItem] { model.filteredItems(for: section) }
    private var hasDetail: Bool {
        if case .scanItem = model.detailTarget { return true }
        return false
    }
    private var selectedID: String? {
        if case .scanItem(let item) = model.detailTarget { item.id }
        else { nil }
    }

    var body: some View {
        Group {
            if hasDetail {
                HSplitView {
                    listPane.frame(minWidth: 260, idealWidth: 320)
                    detailPane
                        .frame(minWidth: 280)
                        .detailTransition(active: hasDetail)
                }
            } else {
                listPane
            }
        }
    }

    private var listPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if section == .system, model.items(for: section).contains(where: { $0.safety == .check }) {
                    CheckFirstWarningBanner()
                }
                filterBar
                if rows.isEmpty {
                    Text("No items match this filter.")
                        .font(.callout)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { idx, item in
                            SelectableItemRow(
                                item: item,
                                isSelected: selectedID == item.id
                            ) { model.openScanItemDetail(item) }
                            if idx < rows.count - 1 { Divider().padding(.leading, 60) }
                        }
                    }
                    .elevatedCard(radius: 10)
                }
            }
            .padding(12)
            .padding(.bottom, 40)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 96) }
        .background(Theme.bg)
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SafetyFilterPills(filter: $model.safetyFilter)
                Spacer(minLength: 0)
                Picker("Sort", selection: $model.sortOrder) {
                    ForEach(SortOrder.allCases) { s in Text(s.rawValue).tag(s) }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            SelectionActionBar(
                totalCount: rows.count,
                selectedCount: model.selectedCount(in: section),
                selectedBytes: model.selectedSafeBytes(in: section),
                isBusy: model.isCleaning,
                onSelectAll: { model.selectAll(in: section) },
                onDeselectAll: { model.deselectAll(in: section) },
                onClean: { model.requestCleanSelected(in: section) }
            )
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if case .scanItem(let item) = model.detailTarget {
            DetailPanelView(
                title: item.name,
                subtitle: item.path,
                icon: ScanItemIcon.image(for: item),
                systemIcon: nil,
                groups: model.detailGroups,
                selectedPaths: $model.detailSelectedPaths,
                isLoading: model.isLoadingDetail
            )
        }
    }
}

struct SelectableItemRow: View {
    let item: ScanItem
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Toggle("", isOn: Binding(
                get: { model.selection.contains(item.id) },
                set: { on in
                    if on { model.selection.insert(item.id) }
                    else { model.selection.remove(item.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            ScanItemIconView(item: item, size: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 13, weight: .medium))
                    SafetyChip(safety: item.safety)
                    if let cmd = item.command {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cmd, forType: .string)
                        } label: {
                            Label("Copy cmd", systemImage: "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(SecondaryOutlineButtonStyle())
                        .controlSize(.small)
                    }
                }
                Text(item.note)
                    .font(.system(size: 11))
                    .foregroundStyle(item.safety == .check || item.safety == .command ? Theme.dangerRed : Theme.secondaryText)
                    .lineLimit(item.safety == .check ? 2 : 1)
                if let label = item.modifiedLabel {
                    Text(label)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.tertiaryText)
                }
                Text(item.path).font(.system(size: 9.5).monospaced()).foregroundStyle(Theme.tertiaryText).lineLimit(1)
            }

            Spacer(minLength: 4)
            Text(item.sizeText).font(.system(size: 12, weight: .semibold).monospacedDigit())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isSelected ? Theme.navy.opacity(0.08) : (hovering ? Theme.elevated : Color.clear),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
    }
}

/// Red banner for System / Library paths that may break profiles or app behavior.
struct CheckFirstWarningBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.dangerRed)
                .font(.system(size: 12))
            Text("Check first items may sign you out, delete profiles, or change app behavior. Read each note before removing.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.dangerRed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.dangerRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Theme.dangerRed.opacity(0.25), lineWidth: 1)
        )
    }
}
