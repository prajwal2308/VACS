import SwiftUI

// MARK: - Sidebar storage card (Purge pattern, monochrome)

struct SidebarStorageCard: View {
    @EnvironmentObject var model: AppModel

    private var usedFraction: Double {
        guard model.totalBytes > 0 else { return 0 }
        return Double(model.totalBytes - model.freeBytes) / Double(model.totalBytes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STORAGE")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.tertiaryText)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline.opacity(0.35))
                    Capsule()
                        .fill(Theme.navy)
                        .frame(width: max(4, geo.size.width * usedFraction))
                }
            }
            .frame(height: 5)

            HStack {
                Text(ByteText.storage(model.totalBytes - model.freeBytes) + " used")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(ByteText.storage(model.freeBytes) + " free")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
            }

            Text("Whole disk · same accounting as System Settings")
                .font(.system(size: 8.5))
                .foregroundStyle(Theme.tertiaryText)

            if model.reclaimableSafe > 0 {
                Divider().padding(.vertical, 2)

                Text("SAFE TO CLEAN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.tertiaryText)

                Text(ByteText.string(model.reclaimableSafe))
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.primaryText)
                    .displayTitle()

                Button {
                    model.requestCleanAllSafe()
                } label: {
                    Text("Clean \(ByteText.string(model.reclaimableSafe))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPillButtonStyle())
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(model.hasFullDiskAccess ? Theme.safeGreen : Theme.secondaryText)
                    .frame(width: 5, height: 5)
                Text(model.hasFullDiskAccess ? "Full Disk Access granted" : "Access needed")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.tertiaryText)
            }
            .padding(.top, 2)
        }
        .padding(10)
        .elevatedCard(radius: 10)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Smart Scan hero

struct SmartCareHero: View {
    @EnvironmentObject var model: AppModel
    let hasScanResults: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hasScanResults ? "SCAN COMPLETE" : "SMART SCAN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.heroSubtext)

                Text(hasScanResults ? "Ready to reclaim" : "Find what's eating your disk")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.heroText.opacity(0.92))

                Text(ByteText.string(hasScanResults ? model.reclaimableSafe : 0))
                    .font(.system(size: 32, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.heroText)
                    .displayTitle()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 1), value: model.reclaimableSafe)

                if hasScanResults {
                    let n = model.categoriesWithData
                    Text("across \(n) categor\(n == 1 ? "y" : "ies")\(model.isScanning ? " · scanning" : "") · trash-safe")
                        .font(.caption)
                        .foregroundStyle(Theme.heroSubtext)
                }

                HStack(spacing: 10) {
                    if hasScanResults && model.overviewSelectedSafeBytes > 0 {
                        Button {
                            model.requestCleanOverviewSelected()
                        } label: {
                            Label(
                                "Clean Selected (\(ByteText.string(model.overviewSelectedSafeBytes)))",
                                systemImage: "trash"
                            )
                            .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(PrimaryPillButtonStyle(inverted: true))
                    }

                    Button {
                        model.scan(section: nil)
                    } label: {
                        Text(model.isScanning && model.scanningSection == nil ? "Scanning…" : "Scan again")
                    }
                    .buttonStyle(SecondaryOutlineButtonStyle(lightOnDark: true))
                    .disabled(model.isScanning)
                }
                .padding(.top, 6)
            }

            Spacer(minLength: 0)

            DiskStackGraphic()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

private struct DiskStackGraphic: View {
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.05 + Double(i) * 0.035))
                    .frame(width: 68 - CGFloat(i * 5), height: 12)
                    .offset(y: CGFloat(i) * -9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                            .frame(width: 68 - CGFloat(i * 5), height: 12)
                            .offset(y: CGFloat(i) * -9)
                    )
            }
        }
        .frame(width: 72, height: 56)
    }
}

// MARK: - Overview selection bar

struct OverviewSelectionBar: View {
    @EnvironmentObject var model: AppModel

    private var visibleCount: Int { model.overviewRows.count }
    private var selectedCount: Int { model.overviewSelectedCount }

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { model.overviewAllSelected },
                set: { on in
                    if on { model.selectAllOverviewSections() }
                    else { model.deselectAllOverviewSections() }
                }
            )) {
                Text(selectionLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
            }
            .toggleStyle(.checkbox)

            if selectedCount > 0 && !model.overviewAllSelected {
                Button("Deselect All") { model.deselectAllOverviewSections() }
                    .buttonStyle(GhostButtonStyle())
            }

            Spacer(minLength: 8)

            if model.overviewSelectedSafeBytes > 0 {
                Button { model.requestCleanOverviewSelected() } label: {
                    Label(
                        "Clean Selected (\(ByteText.string(model.overviewSelectedSafeBytes)))",
                        systemImage: "trash"
                    )
                    .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(PrimaryPillButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairline.opacity(0.72), lineWidth: 1))
    }

    private var selectionLabel: String {
        if selectedCount == 0 { return "Select All" }
        if model.overviewAllSelected { return "All \(visibleCount) selected" }
        return "\(selectedCount) of \(visibleCount) selected"
    }
}

// MARK: - Category review card

struct CategoryReviewCard: View {
    let section: VACSection
    let total: Int64
    let safe: Int64
    let itemCount: Int
    @Binding var isSelected: Bool
    let onReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                Spacer()
                SectionIconBadge(section: section, size: 28, filled: true)
            }

            Text(ByteText.string(total))
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .displayTitle()
                .foregroundStyle(Theme.primaryText)
                .padding(.top, 8)

            Text(section.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .padding(.top, 2)

            Text("\(itemCount) items found")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)

            if isSelected && safe > 0 {
                Text("\(ByteText.string(safe)) selected")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.safeGreen)
                    .padding(.top, 2)
            } else if safe > 0 {
                Text("\(ByteText.string(safe)) safe")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            HStack {
                Spacer()
                Button("Review", action: onReview)
                    .buttonStyle(SecondaryOutlineButtonStyle())
                    .controlSize(.small)
            }
        }
        .padding(12)
        .frame(minHeight: 130)
        .softTintCard(selected: isSelected)
    }
}

// MARK: - Selection bar (PureMac + Purge)

struct SelectionActionBar: View {
    let totalCount: Int
    let selectedCount: Int
    let selectedBytes: Int64
    var isBusy = false
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onClean: () -> Void

    private var allSelected: Bool { totalCount > 0 && selectedCount == totalCount }

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { allSelected },
                set: { on in if on { onSelectAll() } else { onDeselectAll() } }
            )) {
                Text("\(selectedCount) of \(totalCount) selected")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
            }
            .toggleStyle(.checkbox)

            Spacer()

            if isBusy {
                BusyIndicator(label: "Cleaning…")
            }

            if selectedCount > 0 {
                Text(ByteText.string(selectedBytes))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.primaryText)
            }

            if selectedCount > 0 && selectedBytes > 0 {
                Button(action: onClean) {
                    Label(
                        "Clean Selected (\(ByteText.string(selectedBytes)))",
                        systemImage: "trash"
                    )
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(DestructivePillButtonStyle())
                .disabled(isBusy)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairline.opacity(0.72), lineWidth: 1))
    }
}

// MARK: - Busy indicator (clean / delete in progress)

struct BusyIndicator: View {
    var label: String = "Working…"

    var body: some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Filter pills

struct SafetyFilterPills: View {
    @Binding var filter: SafetyFilter

    var body: some View {
        HStack(spacing: 6) {
            ForEach(SafetyFilter.allCases) { f in
                let selected = filter == f
                Button { withAnimation(.easeOut(duration: 0.15)) { filter = f } } label: {
                    Text(f.rawValue)
                        .font(.system(size: 11, weight: selected ? .semibold : .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selected ? Theme.navy : Theme.elevated, in: Capsule())
                        .foregroundStyle(selected ? .white : Theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
