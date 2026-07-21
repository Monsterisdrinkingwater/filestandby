import AppKit
import SwiftUI

@MainActor
enum DraggedFileReader {
    static func isExternalDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        // AppKit only exposes a concrete dragging source for a session started
        // inside this process. Outbound shelf drags must not be accepted back by
        // the shelf, otherwise the inbound overlay can remain visible.
        draggingInfo.draggingSource == nil
    }

    static func urls(from draggingInfo: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        let objects = draggingInfo.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) ?? []

        return objects.compactMap { object in
            (object as? NSURL).map { $0 as URL }
        }
    }
}

@MainActor
final class ShelfDropHostingView: NSHostingView<ShelfView> {
    private let store: ShelfStore

    required init(rootView: ShelfView) {
        self.store = rootView.store
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard DraggedFileReader.isExternalDrag(sender),
              !DraggedFileReader.urls(from: sender).isEmpty
        else {
            store.isDropTargeted = false
            return []
        }
        store.isDropTargeted = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard DraggedFileReader.isExternalDrag(sender) else { return [] }
        return DraggedFileReader.urls(from: sender).isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        store.isDropTargeted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard DraggedFileReader.isExternalDrag(sender) else {
            store.isDropTargeted = false
            return false
        }
        let urls = DraggedFileReader.urls(from: sender)
        store.isDropTargeted = false
        guard !urls.isEmpty else { return false }
        store.add(urls: urls)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        store.isDropTargeted = false
    }
}

@MainActor
final class EdgeDropView: NSView {
    var onOpen: (() -> Void)?
    var onMove: ((EdgeHandleDragUpdate) -> Void)?
    var onMoveEnded: (() -> Void)?
    var onRevealForDrag: (() -> Void)?
    var onDrop: (([URL]) -> Void)?
    var onTargetChange: ((Bool) -> Void)?

    private var isHovering = false
    private var isDraggingOver = false
    private var pointerInteraction = EdgeHandlePointerInteraction()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        toolTip = "点击打开文件架；拖动可移动接收器"
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("File Standby 文件架")
        setAccessibilityHelp("点击打开文件架；拖动可移动接收器；也可把文件拖到这里")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(
            NSTrackingArea(
                rect: bounds,
                options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                owner: self
            )
        )
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        pointerInteraction.begin(
            screenLocation: NSEvent.mouseLocation,
            pointerOffsetInWindow: event.locationInWindow,
            windowSize: bounds.size
        )
    }

    override func mouseDragged(with event: NSEvent) {
        guard let update = pointerInteraction.dragUpdate(
            at: NSEvent.mouseLocation
        ) else { return }
        onMove?(update)
    }

    override func mouseUp(with event: NSEvent) {
        switch pointerInteraction.endResult() {
        case .click:
            onOpen?()
        case .moved:
            onMoveEnded?()
        case .inactive:
            break
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func accessibilityPerformPress() -> Bool {
        onOpen?()
        return true
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard DraggedFileReader.isExternalDrag(sender),
              !DraggedFileReader.urls(from: sender).isEmpty
        else {
            finishTargeting()
            return []
        }
        isDraggingOver = true
        onTargetChange?(true)
        onRevealForDrag?()
        needsDisplay = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard DraggedFileReader.isExternalDrag(sender) else { return [] }
        return DraggedFileReader.urls(from: sender).isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        finishTargeting()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard DraggedFileReader.isExternalDrag(sender) else {
            finishTargeting()
            return false
        }
        let urls = DraggedFileReader.urls(from: sender)
        finishTargeting()
        guard !urls.isEmpty else { return false }
        onDrop?(urls)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        finishTargeting()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let accent = NSColor.controlAccentColor
        let backgroundAlpha: CGFloat = isDraggingOver ? 0.94 : (isHovering ? 0.78 : 0.55)
        let background = accent.withAlphaComponent(backgroundAlpha)
        let path = NSBezierPath(
            roundedRect: bounds.insetBy(dx: 2, dy: 2),
            xRadius: 9,
            yRadius: 9
        )
        background.setFill()
        path.fill()

        let markSize = min(bounds.width, bounds.height) * 0.72
        let markRect = NSRect(
            x: bounds.midX - markSize / 2,
            y: bounds.midY - markSize / 2,
            width: markSize,
            height: markSize
        )
        let image = TransferBoxMarkImage.image(size: markSize, style: .color)
        image.draw(in: markRect)
    }

    private func finishTargeting() {
        isDraggingOver = false
        onTargetChange?(false)
        needsDisplay = true
    }

}
