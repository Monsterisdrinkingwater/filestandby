import AppKit
import Observation
import SwiftUI

struct ShelfView: View {
    @Bindable var store: ShelfStore
    let presentationState: ShelfPresentationState
    let onHide: () -> Void
    let onQuit: () -> Void

    @State private var isConfirmingClear = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.55)

            Group {
                if store.items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .opacity(0.55)

            footer
        }
        .frame(minWidth: 300, idealWidth: 340, minHeight: 300, idealHeight: 470)
        .background(.ultraThinMaterial)
        .overlay {
            if store.isDropTargeted {
                dropOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.snappy(duration: 0.22), value: store.isDropTargeted)
        .alert(
            "File Standby",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("好", role: .cancel) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .confirmationDialog(
            "清空文件架？",
            isPresented: $isConfirmingClear
        ) {
            Button("清空", role: .destructive) {
                store.clear()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只会移除文件引用，不会删除原文件。")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                WindowDragArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .help("拖动以移动文件架")

                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.68)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        TransferBoxMark(size: 18)
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("File Standby")
                                .font(.system(size: 14, weight: .bold))

                            if !store.items.isEmpty {
                                Text("\(store.items.count)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.07), in: Capsule())
                            }
                        }

                        Text("只保存引用，不复制原文件")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.trailing, 2)
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34, alignment: .leading)

            Button(action: onHide) {
                Image(systemName: presentationState.collapseDirection.systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(Color.primary.opacity(0.06), in: Circle())
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help("收起文件架")
            .animation(.easeOut(duration: 0.16), value: presentationState.collapseDirection)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(store.items) { item in
                    ShelfItemRow(
                        item: item,
                        resolvedURL: store.resolvedURL(for: item),
                        onRemove: { store.remove(item) }
                    )
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(12)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.11))
                    .frame(width: 78, height: 78)

                TransferBoxMark(size: 44)
            }

            VStack(spacing: 6) {
                Text("把文件放在这里")
                    .font(.system(size: 16, weight: .bold))

                Text("从 Finder 拖入文件或文件夹\n之后可拖动整张卡片到目标位置")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button("选择文件…", action: chooseFiles)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: chooseFiles) {
                Label("添加", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))

            Spacer()

            if !store.items.isEmpty {
                Button {
                    isConfirmingClear = true
                } label: {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }

            Button(action: onQuit) {
                Label("退出", systemImage: "power")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .help("退出 File Standby")
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
    }

    private var dropOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.accentColor.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                        )
                }
                .padding(12)

            VStack(spacing: 12) {
                TransferBoxMark(size: 48)
                    .scaleEffect(store.isDropTargeted ? 1.08 : 1)

                Text("松开以暂存")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .allowsHitTesting(false)
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.title = "选择要暂存的项目"
        panel.prompt = "加入文件架"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true

        panel.begin { response in
            guard response == .OK else { return }
            store.add(urls: panel.urls)
        }
    }
}
