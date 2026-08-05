import SwiftUI
import AppKit

struct InstalledPackagesView: View {
    @EnvironmentObject var model: AppModel
    @State private var copiedCommandID: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                TextField("Search packages", text: $model.packageSearchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline.opacity(0.35), lineWidth: 0.5))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            infoBanner

            if model.isLoadingPackages && !model.installedPackagesLoaded {
                Spacer()
                ProgressView("Scanning packages…").controlSize(.small)
                Spacer()
            } else if model.filteredInstalledPackages.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text(model.installedPackagesLoaded ? "No packages match your search." : "No packages found.")
                        .font(.headline)
                    Text("Installs from Homebrew, npm global, pip, and PATH binaries appear here.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.filteredInstalledPackages) { pkg in
                            packageRow(pkg)
                            if pkg.id != model.filteredInstalledPackages.last?.id {
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
            if !model.installedPackagesLoaded { model.loadInstalledPackages() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            SectionIconBadge(section: .installedPackages, size: 28, filled: true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Installed Packages")
                    .font(.system(size: 15, weight: .semibold))
                if model.installedPackagesLoaded {
                    Text("\(model.installedPackages.count) packages found")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
            Button { model.loadInstalledPackages() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(SecondaryOutlineButtonStyle())
            .disabled(model.isLoadingPackages)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.navy)
                .font(.system(size: 12))
            Text("Forgotten CLI tools and package installs — e.g. pentest utilities, old npm globals. Review before uninstalling.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.navy.opacity(0.06))
    }

    private func packageRow(_ pkg: InstalledPackage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pkg.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(pkg.source.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.3)
                        .foregroundStyle(Theme.navy)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.navy.opacity(0.08), in: Capsule())
                }
                Text(pkg.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
                if let cmd = pkg.uninstallCommand {
                    HStack(spacing: 6) {
                        Text(cmd)
                            .font(.system(size: 11).monospaced())
                            .foregroundStyle(Theme.primaryText)
                            .textSelection(.enabled)
                        Button {
                            copyCommand(cmd, id: pkg.id)
                        } label: {
                            Label(
                                copiedCommandID == pkg.id ? "Copied" : "Copy",
                                systemImage: copiedCommandID == pkg.id ? "checkmark" : "doc.on.doc"
                            )
                            .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(GhostButtonStyle())
                        .controlSize(.small)
                    }
                }
                Text(pkg.path)
                    .font(.system(size: 9.5).monospaced())
                    .foregroundStyle(Theme.tertiaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Text(pkg.sizeText)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                Button("Reveal") {
                    NSWorkspace.shared.selectFile(pkg.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(GhostButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(pkg.path, inFileViewerRootedAtPath: "")
            }
            if let cmd = pkg.uninstallCommand {
                Button("Copy command") { copyCommand(cmd, id: pkg.id) }
            }
        }
    }

    private func copyCommand(_ cmd: String, id: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
        copiedCommandID = id
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                if copiedCommandID == id { copiedCommandID = nil }
            }
        }
    }
}
