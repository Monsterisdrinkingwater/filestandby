import AppKit
import SwiftUI

struct ShelfItemRow: View {
    let item: ShelfItem
    let resolvedURL: URL?
    let isSelected: Bool
    let onSelect: (NSEvent.ModifierFlags) -> Void
    let onDragURLs: () -> [URL]
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        rowContent
            .accessibilityHint("Command 点击多选，Shift 点击连续选择；拖动选中文件到 Finder 或其他应用")
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                icon

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .foregroundStyle(resolvedURL == nil ? .secondary : .primary)

                    Label(metadataText, systemImage: resolvedURL == nil ? "exclamationmark.triangle.fill" : metadataIcon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(resolvedURL == nil ? Color.orange : Color.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }
            .overlay {
                ShelfItemInteractionView(
                    title: item.displayName,
                    isSelected: isSelected,
                    isAvailable: resolvedURL != nil,
                    onClick: onSelect,
                    onPreview: preview,
                    onDragURLs: onDragURLs,
                    onShowInFinder: showInFinder,
                    onCopyPath: copyPath,
                    onRemove: onRemove
                )
            }

            if isHovering {
                HStack(spacing: 2) {
                    actionButton(
                        title: "快速预览",
                        systemImage: "eye",
                        disabled: resolvedURL == nil
                    ) { preview() }

                    actionButton(title: "移除", systemImage: "xmark") {
                        onRemove()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(isHovering ? 0.075 : 0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.65) : Color.primary.opacity(isHovering ? 0.12 : 0.07), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovering = hovering
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let resolvedURL {
            Image(nsImage: NSWorkspace.shared.icon(forFile: resolvedURL.path))
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .padding(3)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(systemName: item.isDirectory ? "folder.badge.questionmark" : "doc.badge.ellipsis")
                .font(.system(size: 25))
                .foregroundStyle(.secondary)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func preview() {
        guard let resolvedURL else { return }
        QuickLookController.shared.preview(resolvedURL)
    }

    private func showInFinder() {
        guard let resolvedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([resolvedURL])
    }

    private func copyPath() {
        guard let resolvedURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resolvedURL.path, forType: .string)
    }

    private var metadataText: String {
        guard resolvedURL != nil else { return "原文件不可用" }
        if item.isDirectory { return "文件夹" }

        let fileType = URL(fileURLWithPath: item.originalPath)
            .pathExtension
            .uppercased()
        let size = item.fileSize.map {
            ByteCountFormatter.string(fromByteCount: $0, countStyle: .file)
        }

        switch (fileType.isEmpty ? nil : fileType, size) {
        case let (type?, size?): return "\(type) · \(size)"
        case let (type?, nil): return type
        case let (nil, size?): return size
        case (nil, nil): return "文件"
        }
    }

    private var metadataIcon: String {
        item.isDirectory ? "folder.fill" : "doc.fill"
    }

    private func actionButton(
        title: String,
        systemImage: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 24)
                .background(Color.primary.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(title)
    }
}
