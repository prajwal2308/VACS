import SwiftUI
import AppKit

struct ItemRow: View {
    let item: ScanItem
    @Binding var pendingTrash: ScanItem?
    @EnvironmentObject var model: AppModel
    @State private var hovering = false
    @State private var copied = false

    private var selectable: Bool { item.safety == .safe || item.safety == .check }
    private var isSelected: Bool { model.selection.contains(item.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if selectable {
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { on in
                        if on { model.selection.insert(item.id) }
                        else { model.selection.remove(item.id) }
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            } else {
                Spacer().frame(width: 16)
            }

            ScanItemIconView(item: item, size: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                    SafetyChip(safety: item.safety)
                }
                Text(item.path)
                    .font(.system(size: 10.5).monospaced())
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(item.note)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.sizeText)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.primaryText)
                rowActions
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(hovering ? Theme.primaryText.opacity(0.04) : Color.clear)
        .onHover { hovering = $0 }
    }

    @ViewBuilder private var rowActions: some View {
        HStack(spacing: 8) {
            if !item.known || item.safety == .check {
                Button("Reveal") { reveal() }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
            }

            switch item.safety {
            case .safe, .check:
                Button("Move to Trash…") { model.requestTrash(item) }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
            case .command:
                Button(copied ? "Copied ✓" : "Copy command") {
                    model.copyCommand(item)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
                }
                .buttonStyle(.link)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.primaryText)
            case .never:
                EmptyView()
            }
        }
    }

    private func reveal() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }
}
