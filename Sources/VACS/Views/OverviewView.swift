import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: AppModel

    private var hasResults: Bool { !model.items.isEmpty || !model.overviewRows.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Scan")
                        .font(.system(size: 22, weight: .bold))
                        .displayTitle()
                    Text("Choose what to keep, then clean in one pass.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }

                SmartCareHero(hasScanResults: hasResults)

                if hasResults {
                    reviewSection
                } else if model.isScanning && model.scanningSection == nil {
                    scanningPlaceholder
                } else {
                    emptyHero
                }
            }
            .padding(14)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg)
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review what was found").font(.headline)

            OverviewSelectionBar()

            Text("Tap items to include or skip. Category checkbox selects all safe items in that group.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 10)],
                spacing: 10
            ) {
                ForEach(model.overviewRows, id: \.section) { row in
                    CategoryReviewCard(
                        section: row.section,
                        total: row.total,
                        safe: row.safe,
                        itemCount: model.itemCount(for: row.section),
                        safeItems: model.safeItems(for: row.section),
                        allItems: model.items(for: row.section),
                        onReview: { model.selectSection(row.section) }
                    )
                }
            }
        }
    }

    private var scanningPlaceholder: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text("Measuring folders…").foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .elevatedCard()
    }

    private var emptyHero: some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Theme.navy.opacity(0.5))
            Text("Run your first scan").font(.headline)
            Text("VACS measures every dev cache and notes what's safe to reclaim.")
                .font(.callout)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button { model.scan(section: nil) } label: {
                Text("Scan all categories")
            }
            .buttonStyle(PrimaryPillButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .elevatedCard()
    }
}
