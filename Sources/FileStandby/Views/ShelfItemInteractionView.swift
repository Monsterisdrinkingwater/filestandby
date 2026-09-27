import AppKit
import SwiftUI

struct ShelfItemInteractionView: NSViewRepresentable {
    let title: String
    let isSelected: Bool
    let isAvailable: Bool
    let onClick: (NSEvent.ModifierFlags) -> Void
    let onPreview: () -> Void
    let onDragURLs: () -> [URL]
    let onShowInFinder: () -> Void
    let onCopyPath: () -> Void
    let onRemove: () -> Void

    func makeNSView(context: Context) -> ShelfItemInteractionNSView {
        ShelfItemInteractionNSView()
    }

    func updateNSView(_ view: ShelfItemInteractionNSView, context: Context) {
        view.title = title
        view.isSelected = isSelected
        view.isAvailable = isAvailable
        view.onClick = onClick
        view.onPreview = onPreview
        view.onDragURLs = onDragURLs
        view.onShowInFinder = onShowInFinder
        view.onCopyPath = onCopyPath
        view.onRemove = onRemove
        view.toolTip = "Command 点击多选，Shift 点击连续选择；拖动选中项目可一起导出"
    }
}

final class ShelfItemInteractionNSView: NSView, NSDraggingSource {
    var title = ""
    var isSelected = false
    var isAvailable = false
    var onClick: ((NSEvent.ModifierFlags) -> Void)?
    var onPreview: (() -> Void)?
    var onDragURLs: (() -> [URL])?
    var onShowInFinder: (() -> Void)?
    var onCopyPath: (() -> Void)?
    var onRemove: (() -> Void)?

    private var mouseDownPoint: NSPoint?
    private var didStartDrag = false

    override var mouseDownCanMoveWindow: Bool { false }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
    override func accessibilityLabel() -> String? { title }
    override func accessibilityValue() -> Any? { isSelected ? "已选中" : "未选中" }
    override func accessibilityHelp() -> String? {
        "Command 点击多选，Shift 点击连续选择；拖动选中项目可一起导出"
    }

    override func accessibilityPerformPress() -> Bool {
        onClick?([])
        return true
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownPoint = convert(event.locationInWindow, from: nil)
        didStartDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !didStartDrag, let mouseDownPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard hypot(point.x - mouseDownPoint.x, point.y - mouseDownPoint.y) >= 4 else { return }
        guard let urls = onDragURLs?(), !urls.isEmpty else { return }

        didStartDrag = true
        let items = Self.draggingItems(for: urls, at: mouseDownPoint)
        beginDraggingSession(with: items, event: event, source: self)
    }

    static func draggingItems(for urls: [URL], at point: NSPoint) -> [NSDraggingItem] {
        urls.enumerated().map { index, url in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let image = NSWorkspace.shared.icon(forFile: url.path)
            image.size = NSSize(width: 42, height: 42)
            item.setDraggingFrame(
                NSRect(
                    x: point.x - 21 + CGFloat(index % 3) * 3,
                    y: point.y - 21 - CGFloat(index % 3) * 3,
                    width: 42,
                    height: 42
                ),
                contents: image
            )
            return item
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { mouseDownPoint = nil }
        guard !didStartDrag else { return }
        onClick?(event.modifierFlags)
        if event.clickCount == 2 {
            onPreview?()
        }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        addMenuItem("快速预览", to: menu, action: #selector(preview), enabled: isAvailable)
        addMenuItem("在 Finder 中显示", to: menu, action: #selector(showInFinder), enabled: isAvailable)
        addMenuItem("复制路径", to: menu, action: #selector(copyPath), enabled: isAvailable)
        menu.addItem(.separator())
        addMenuItem("从文件架移除", to: menu, action: #selector(remove))
        return menu
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .arrow)
    }

    private func addMenuItem(
        _ title: String,
        to menu: NSMenu,
        action: Selector,
        enabled: Bool = true
    ) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        menu.addItem(item)
    }

    @objc private func preview() { onPreview?() }
    @objc private func showInFinder() { onShowInFinder?() }
    @objc private func copyPath() { onCopyPath?() }
    @objc private func remove() { onRemove?() }
}
