import SwiftUI
import AppKit

struct AISkillsView: View {
    @EnvironmentObject var model: AppModel

    private var flaggedCount: Int {
        model.aiSkillEntries.filter(\.needsAttention).count
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                TextField("Search skills & MCP", text: $model.aiSkillsSearchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline.opacity(0.35), lineWidth: 0.5))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            infoBanner

            if model.isLoadingAISkills && !model.aiSkillsLoaded {
                Spacer()
                ProgressView("Scanning AI configs…").controlSize(.small)
                Spacer()
            } else if model.filteredAISkillEntries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text(model.aiSkillsLoaded ? "No entries match your search." : "No AI skills or MCP configs found.")
                        .font(.headline)
                    Text("Cursor skills, Codex skills, and MCP server configs are scanned from your home folder.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.filteredAISkillEntries) { entry in
                            skillRow(entry)
                            if entry.id != model.filteredAISkillEntries.last?.id {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                    .elevatedCard(radius: 10)
                    .padding(12)
                }
            }
        }
        .background(Theme.bg)
        .onAppear {
            if !model.aiSkillsLoaded { model.loadAISkills() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            SectionIconBadge(section: .aiSkills, size: 28, filled: true)
            VStack(alignment: .leading, spacing: 1) {
                Text("AI & Skills")
                    .font(.system(size: 15, weight: .semibold))
                if model.aiSkillsLoaded {
                    if flaggedCount > 0 {
                        Text("\(flaggedCount) need attention · \(model.aiSkillEntries.count) total")
                            .font(.caption)
                            .foregroundStyle(Theme.dangerRed)
                    } else {
                        Text("\(model.aiSkillEntries.count) entries")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            Spacer()
            Button { model.loadAISkills() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(SecondaryOutlineButtonStyle())
            .disabled(model.isLoadingAISkills)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.checkAmber)
                .font(.system(size: 12))
            Text("Review-only — VACS flags missing SKILL.md files, stale configs, and broken MCP paths. Remove manually if unused.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.checkAmber.opacity(0.08))
    }

    private func skillRow(_ entry: AISkillEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.kind.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.3)
                        .foregroundStyle(entry.needsAttention ? Theme.dangerRed : Theme.navy)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (entry.needsAttention ? Theme.dangerRed : Theme.navy).opacity(0.08),
                            in: Capsule()
                        )
                }
                if let issue = entry.issue {
                    Text(issue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.dangerRed)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(entry.path)
                    .font(.system(size: 9.5).monospaced())
                    .foregroundStyle(Theme.tertiaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.sizeText)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                Button("Reveal") {
                    NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(GhostButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(entry.needsAttention ? Theme.dangerRed.opacity(0.04) : Color.clear)
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
            }
        }
    }
}
