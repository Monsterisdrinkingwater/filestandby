import AppKit
import SwiftUI

@MainActor
final class ShelfPanelController: NSWindowController, NSWindowDelegate {
    private let store: ShelfStore
    private let edgePositionStore: EdgeHandlePositionStore
    private let presentationState = ShelfPresentationState()
    private var edgePanel: NSPanel!
    private var edgeDock: EdgeHandleDock = .free
    private var edgeDragStartFrame: NSRect?
    private var screenObserver: NSObjectProtocol?

    init(
        store: ShelfStore,
        edgePositionStore: EdgeHandlePositionStore = EdgeHandlePositionStore()
    ) {
        self.store = store
        self.edgePositionStore = edgePositionStore

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 470),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)

        configureShelfPanel(panel)
        configureEdgePanel()

        let rootView = ShelfView(
            store: store,
            presentationState: presentationState,
            onHide: { [weak self] in self?.hideShelf() },
            onQuit: { NSApp.terminate(nil) }
        )
        panel.contentView = ShelfDropHostingView(rootView: rootView)
        panel.delegate = self

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.positionEdgeHandle()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isShelfVisible: Bool {
        window?.isVisible == true
    }

    func showShelf() {
        showShelf(activating: true)
    }

    func revealShelfForDrag() {
        showShelf(activating: false)
    }

    private func showShelf(activating: Bool) {
        guard let panel = window else { return }
        if !UserDefaults.standard.bool(forKey: "FileStandby.DidPositionShelf") {
            positionShelf(panel)
            UserDefaults.standard.set(true, forKey: "FileStandby.DidPositionShelf")
        }
        refreshCollapseDirection()
        if activating {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            panel.orderFrontRegardless()
        }
    }

    func hideShelf() {
        store.isDropTargeted = false
        window?.orderOut(nil)
    }

    func toggleShelf() {
        isShelfVisible ? hideShelf() : showShelf()
    }

    func showEdgeHandle() {
        positionEdgeHandle()
        edgePanel.orderFrontRegardless()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideShelf()
        return false
    }

    func windowDidMove(_ notification: Notification) {
        refreshCollapseDirection()
    }

    func windowDidResize(_ notification: Notification) {
        refreshCollapseDirection()
    }

    private func configureShelfPanel(_ panel: NSPanel) {
        panel.title = "File Standby"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        // Only WindowDragArea in the header may move the shelf. If this is true,
        // dragging a file card can also move the entire window.
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 300, height: 300)
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.setFrameAutosaveName("FileStandby.Shelf")

        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func configureEdgePanel() {
        let initialSize = EdgeHandlePlacement.verticalSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        let edgeView = EdgeDropView(frame: NSRect(origin: .zero, size: initialSize))
        edgeView.autoresizingMask = [.width, .height]
        edgeView.onOpen = { [weak self] in self?.showShelf() }
        edgeView.onMove = { [weak self] update in
            self?.moveEdgeHandle(with: update)
        }
        edgeView.onMoveEnded = { [weak self] in
            self?.finishMovingEdgeHandle()
        }
        edgeView.onRevealForDrag = { [weak self] in self?.revealShelfForDrag() }
        edgeView.onDrop = { [weak self] urls in
            self?.store.add(urls: urls)
            self?.revealShelfForDrag()
        }
        edgeView.onTargetChange = { [weak self] isTargeted in
            self?.store.isDropTargeted = isTargeted
        }
        panel.contentView = edgeView
        edgePanel = panel
    }

    private func positionShelf(_ panel: NSWindow) {
        guard let visibleFrame = NSScreen.main?.visibleFrame else {
            panel.center()
            return
        }

        let size = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.maxX - size.width - 38,
            y: visibleFrame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func positionEdgeHandle() {
        guard let defaultFrame = NSScreen.main?.visibleFrame else { return }
        let savedPlacement = edgePositionStore.load()
        let placement = savedPlacement
            ?? EdgeHandleSavedPlacement(
                origin: NSPoint(
                    x: defaultFrame.maxX - EdgeHandlePlacement.verticalSize.width - 2,
                    y: defaultFrame.midY - EdgeHandlePlacement.verticalSize.height / 2
                ),
                dock: .free
            )
        let layout = EdgeHandlePlacement.restoredLayout(
            for: placement,
            screens: availableScreens
        )
        apply(layout)
        refreshCollapseDirection()

        if savedPlacement != nil {
            persist(layout)
        }
    }

    private func moveEdgeHandle(with update: EdgeHandleDragUpdate) {
        if edgeDragStartFrame == nil {
            edgeDragStartFrame = edgePanel.frame
        }
        let layout = EdgeHandlePlacement.dragLayout(
            for: update,
            currentDock: edgeDock,
            screens: availableScreens
        )
        apply(layout)
        persist(layout)
    }

    private func finishMovingEdgeHandle() {
        guard let startFrame = edgeDragStartFrame else { return }
        edgeDragStartFrame = nil

        guard !framesAreApproximatelyEqual(startFrame, edgePanel.frame) else {
            refreshCollapseDirection()
            return
        }
        positionShelfNearEdgeHandle()
    }

    private var availableScreens: [EdgeHandleScreen] {
        NSScreen.screens.map {
            EdgeHandleScreen(frame: $0.frame, visibleFrame: $0.visibleFrame)
        }
    }

    private func apply(_ layout: EdgeHandleLayout) {
        edgeDock = layout.dock
        edgePanel.setFrame(
            NSRect(origin: layout.origin, size: layout.size),
            display: true
        )
    }

    private func persist(_ layout: EdgeHandleLayout) {
        edgePositionStore.save(
            EdgeHandleSavedPlacement(origin: layout.origin, dock: layout.dock)
        )
    }

    private func positionShelfNearEdgeHandle() {
        guard let panel = window,
              let layout = ShelfWindowPlacement.layout(
                shelfSize: panel.frame.size,
                handleFrame: edgePanel.frame,
                handleDock: edgeDock,
                screens: availableScreens
              )
        else {
            refreshCollapseDirection()
            return
        }

        panel.setFrameOrigin(layout.origin)
        presentationState.collapseDirection = layout.collapseDirection
        UserDefaults.standard.set(true, forKey: "FileStandby.DidPositionShelf")
    }

    private func refreshCollapseDirection() {
        guard let panel = window, edgePanel != nil else { return }
        presentationState.collapseDirection = ShelfWindowPlacement.collapseDirection(
            shelfFrame: panel.frame,
            handleFrame: edgePanel.frame,
            handleDock: edgeDock,
            fallback: presentationState.collapseDirection
        )
    }

    private func framesAreApproximatelyEqual(_ lhs: NSRect, _ rhs: NSRect) -> Bool {
        let tolerance: CGFloat = 0.5
        return abs(lhs.origin.x - rhs.origin.x) <= tolerance
            && abs(lhs.origin.y - rhs.origin.y) <= tolerance
            && abs(lhs.size.width - rhs.size.width) <= tolerance
            && abs(lhs.size.height - rhs.size.height) <= tolerance
    }
}
