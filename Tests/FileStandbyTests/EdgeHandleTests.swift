import AppKit
import Foundation
import Testing
@testable import FileStandby

@Suite("Edge handle placement")
struct EdgeHandlePlacementTests {
    private let handleSize = EdgeHandlePlacement.verticalSize
    private let mainFrame = CGRect(x: 0, y: 0, width: 1_440, height: 900)

    private var mainScreen: EdgeHandleScreen {
        EdgeHandleScreen(frame: mainFrame, visibleFrame: mainFrame)
    }

    @Test("keeps a visible position unchanged")
    func keepsVisiblePosition() {
        let origin = CGPoint(x: 420, y: 300)
        let result = EdgeHandlePlacement.clampedOrigin(
            origin,
            panelSize: handleSize,
            visibleFrames: [mainFrame]
        )

        #expect(result == origin)
    }

    @Test("keeps the complete handle inside all four screen edges")
    func clampsToScreenEdges() {
        let result = EdgeHandlePlacement.clampedOrigin(
            CGPoint(x: 2_000, y: 1_200),
            panelSize: handleSize,
            visibleFrames: [mainFrame]
        )
        #expect(result == CGPoint(x: 1_412, y: 786))

        let negativeResult = EdgeHandlePlacement.clampedOrigin(
            CGPoint(x: -500, y: -500),
            panelSize: handleSize,
            visibleFrames: [mainFrame]
        )
        #expect(negativeResult == CGPoint(x: 2, y: 2))
    }

    @Test("supports displays with negative global coordinates")
    func supportsNegativeDisplayCoordinates() {
        let leftDisplay = CGRect(x: -1_280, y: -100, width: 1_280, height: 1_024)
        let origin = CGPoint(x: -900, y: 240)
        let result = EdgeHandlePlacement.clampedOrigin(
            origin,
            panelSize: handleSize,
            visibleFrames: [mainFrame, leftDisplay]
        )

        #expect(result == origin)
    }

    @Test("recovers an offscreen saved position to the nearest display")
    func recoversOffscreenPosition() {
        let leftDisplay = CGRect(x: -1_280, y: 0, width: 1_280, height: 900)
        let result = EdgeHandlePlacement.clampedOrigin(
            CGPoint(x: -2_000, y: 400),
            panelSize: handleSize,
            visibleFrames: [mainFrame, leftDisplay]
        )

        #expect(result == CGPoint(x: -1_278, y: 400))
    }

    @Test("repairs non-finite saved coordinates")
    func repairsInvalidCoordinates() {
        let result = EdgeHandlePlacement.clampedOrigin(
            CGPoint(x: CGFloat.nan, y: CGFloat.infinity),
            panelSize: handleSize,
            visibleFrames: [mainFrame]
        )

        #expect(result.x == 2)
        #expect(result.y == 394)
    }

    @Test("receiver always snaps to the nearest of all four edges")
    func receiverNeverStaysInTheCenter() {
        let center = dragLayout(at: CGPoint(x: 500, y: 450))
        #expect(center.dock == .top)
        #expect(center.size == EdgeHandlePlacement.horizontalSize)
        #expect(center.origin == CGPoint(x: 444, y: 872))

        let left = dragLayout(at: CGPoint(x: 1, y: 450))
        #expect(left.dock == .left)
        #expect(left.size == EdgeHandlePlacement.verticalSize)
        #expect(left.origin.x == 2)

        let right = dragLayout(at: CGPoint(x: 1_439, y: 450))
        #expect(right.dock == .right)
        #expect(right.size == EdgeHandlePlacement.verticalSize)
        #expect(right.origin.x == 1_412)
    }

    @Test("top and bottom edges switch to a horizontal receiver")
    func topAndBottomBecomeHorizontal() {
        #expect(EdgeHandlePlacement.verticalSize.width == EdgeHandlePlacement.handleThickness)
        #expect(EdgeHandlePlacement.verticalSize.height == EdgeHandlePlacement.handleLength)
        #expect(EdgeHandlePlacement.horizontalSize.width == EdgeHandlePlacement.handleLength)
        #expect(EdgeHandlePlacement.horizontalSize.height == EdgeHandlePlacement.handleThickness)

        let top = dragLayout(at: CGPoint(x: 500, y: 895))
        #expect(top.dock == .top)
        #expect(top.size == CGSize(width: 112, height: 26))
        #expect(top.origin == CGPoint(x: 444, y: 872))

        let bottom = dragLayout(at: CGPoint(x: 500, y: 5))
        #expect(bottom.dock == .bottom)
        #expect(bottom.size == CGSize(width: 112, height: 26))
        #expect(bottom.origin == CGPoint(x: 444, y: 2))
    }

    @Test("visible edges remain reachable around the menu bar and Dock")
    func respectsVisibleFrameAroundSystemUI() {
        let screen = EdgeHandleScreen(
            frame: CGRect(x: 0, y: 0, width: 1_440, height: 956),
            visibleFrame: CGRect(x: 0, y: 70, width: 1_440, height: 853)
        )

        let top = EdgeHandlePlacement.dragLayout(
            for: update(at: CGPoint(x: 700, y: 955)),
            currentDock: .free,
            screens: [screen]
        )
        #expect(top.dock == .top)
        #expect(top.origin.y == 895)

        let bottom = EdgeHandlePlacement.dragLayout(
            for: update(at: CGPoint(x: 700, y: 1)),
            currentDock: .free,
            screens: [screen]
        )
        #expect(bottom.dock == .bottom)
        #expect(bottom.origin.y == 72)
    }

    @Test("small nearest-edge bias prevents diagonal flicker")
    func nearestEdgeBias() {
        let exactCenter = CGPoint(x: mainFrame.midX, y: mainFrame.midY)
        #expect(dragLayout(at: exactCenter, currentDock: .top).dock == .top)
        #expect(dragLayout(at: exactCenter, currentDock: .bottom).dock == .bottom)

        let clearlyCloserToTop = dragLayout(
            at: CGPoint(x: mainFrame.midX, y: 600),
            currentDock: .bottom
        )
        #expect(clearlyCloserToTop.dock == .top)

        let topWinsAfterMovingAwayFromRightCorner = dragLayout(
            at: CGPoint(x: mainFrame.maxX - 10, y: mainFrame.maxY),
            currentDock: .right
        )
        #expect(topWinsAfterMovingAwayFromRightCorner.dock == .top)
    }

    @Test("normalized mouse anchor prevents jumps when dimensions swap")
    func normalizedAnchorSurvivesDimensionSwap() {
        let anchor = CGPoint(x: 0.25, y: 0.75)
        let topPointer = CGPoint(x: 500, y: 891.5)
        let horizontal = EdgeHandlePlacement.dragLayout(
            for: EdgeHandleDragUpdate(
                screenLocation: topPointer,
                normalizedAnchor: anchor
            ),
            currentDock: .free,
            screens: [mainScreen]
        )
        #expect(horizontal.dock == .top)
        #expect(horizontal.origin.x + anchor.x * horizontal.size.width == topPointer.x)
        #expect(horizontal.origin.y + anchor.y * horizontal.size.height == topPointer.y)

        let freePointer = CGPoint(x: 5, y: 700)
        let vertical = EdgeHandlePlacement.dragLayout(
            for: EdgeHandleDragUpdate(
                screenLocation: freePointer,
                normalizedAnchor: anchor
            ),
            currentDock: .top,
            screens: [mainScreen]
        )
        #expect(vertical.dock == .left)
        #expect(vertical.size == EdgeHandlePlacement.verticalSize)
        #expect(vertical.origin.y + anchor.y * vertical.size.height == freePointer.y)
    }

    @Test("negative-coordinate displays use their own top and bottom edges")
    func horizontalOnNegativeCoordinateDisplay() {
        let leftFrame = CGRect(x: -1_280, y: -100, width: 1_280, height: 1_024)
        let leftScreen = EdgeHandleScreen(frame: leftFrame, visibleFrame: leftFrame)

        let top = EdgeHandlePlacement.dragLayout(
            for: update(at: CGPoint(x: -640, y: 920)),
            currentDock: .free,
            screens: [mainScreen, leftScreen]
        )
        #expect(top.dock == .top)
        #expect(top.origin.y == 896)

        let bottom = EdgeHandlePlacement.dragLayout(
            for: update(at: CGPoint(x: -640, y: -98)),
            currentDock: .free,
            screens: [mainScreen, leftScreen]
        )
        #expect(bottom.dock == .bottom)
        #expect(bottom.origin.y == -98)
    }

    @Test("restoring and display removal preserve the horizontal edge")
    func restoreHorizontalPlacement() {
        let restored = EdgeHandlePlacement.restoredLayout(
            for: EdgeHandleSavedPlacement(
                origin: CGPoint(x: 620, y: 2_000),
                dock: .top
            ),
            screens: [mainScreen]
        )
        #expect(restored.dock == .top)
        #expect(restored.size == EdgeHandlePlacement.horizontalSize)
        #expect(restored.origin == CGPoint(x: 620, y: 872))

        let recoveredFromRemovedDisplay = EdgeHandlePlacement.restoredLayout(
            for: EdgeHandleSavedPlacement(
                origin: CGPoint(x: -900, y: 800),
                dock: .bottom
            ),
            screens: [mainScreen]
        )
        #expect(recoveredFromRemovedDisplay.dock == .bottom)
        #expect(recoveredFromRemovedDisplay.origin == CGPoint(x: 2, y: 2))
    }

    @Test("legacy free placement migrates to its nearest edge")
    func legacyFreePlacementMovesToEdge() {
        let restored = EdgeHandlePlacement.restoredLayout(
            for: EdgeHandleSavedPlacement(
                origin: CGPoint(x: 1_400, y: 400),
                dock: .free
            ),
            screens: [mainScreen]
        )

        #expect(restored.dock == .right)
        #expect(restored.size == EdgeHandlePlacement.verticalSize)
        #expect(restored.origin.x == mainFrame.maxX - EdgeHandlePlacement.handleThickness - 2)
    }

    private func dragLayout(
        at point: CGPoint,
        currentDock: EdgeHandleDock = .free
    ) -> EdgeHandleLayout {
        EdgeHandlePlacement.dragLayout(
            for: update(at: point),
            currentDock: currentDock,
            screens: [mainScreen]
        )
    }

    private func update(at point: CGPoint) -> EdgeHandleDragUpdate {
        EdgeHandleDragUpdate(
            screenLocation: point,
            normalizedAnchor: CGPoint(x: 0.5, y: 0.5)
        )
    }
}

@Suite("Edge handle pointer interaction")
struct EdgeHandlePointerInteractionTests {
    @Test("a click opens while small pointer jitter does not move")
    func clickWithJitter() {
        var interaction = EdgeHandlePointerInteraction()
        interaction.begin(
            screenLocation: CGPoint(x: 100, y: 100),
            pointerOffsetInWindow: CGPoint(x: 10, y: 20),
            windowSize: EdgeHandlePlacement.verticalSize
        )

        #expect(interaction.dragUpdate(at: CGPoint(x: 102, y: 102)) == nil)
        let shouldOpen = interaction.endShouldOpen()
        #expect(shouldOpen)
    }

    @Test("movement returns a normalized anchor without also opening")
    func moveDoesNotOpen() throws {
        var interaction = EdgeHandlePointerInteraction()
        interaction.begin(
            screenLocation: CGPoint(x: 100, y: 100),
            pointerOffsetInWindow: CGPoint(x: 13, y: 28),
            windowSize: EdgeHandlePlacement.verticalSize
        )

        let optionalUpdate = interaction.dragUpdate(at: CGPoint(x: 130, y: 145))
        let update = try #require(optionalUpdate)
        #expect(update.screenLocation == CGPoint(x: 130, y: 145))
        #expect(update.normalizedAnchor == CGPoint(x: 0.5, y: 0.25))
        let shouldOpen = interaction.endShouldOpen()
        #expect(!shouldOpen)
        #expect(interaction.dragUpdate(at: CGPoint(x: 200, y: 200)) == nil)
    }

    @Test("pointer offsets are safely normalized into the new orientation")
    func normalizesPointerOffset() throws {
        var interaction = EdgeHandlePointerInteraction()
        interaction.begin(
            screenLocation: CGPoint(x: 100, y: 100),
            pointerOffsetInWindow: CGPoint(x: 100, y: -20),
            windowSize: EdgeHandlePlacement.verticalSize
        )

        let optionalUpdate = interaction.dragUpdate(at: CGPoint(x: 110, y: 110))
        let update = try #require(optionalUpdate)
        #expect(update.normalizedAnchor == CGPoint(x: 1, y: 0))
    }
}

@Suite("Edge handle position persistence")
@MainActor
struct EdgeHandlePositionStoreTests {
    @Test("round-trips coordinates and horizontal edge state")
    func roundTrip() throws {
        let suiteName = "FileStandbyTests.EdgeHandle.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EdgeHandlePositionStore(defaults: defaults)

        #expect(store.load() == nil)
        let placement = EdgeHandleSavedPlacement(
            origin: CGPoint(x: -312.5, y: 98.25),
            dock: .bottom
        )
        store.save(placement)
        #expect(store.load() == placement)
    }

    @Test("legacy positions without an edge remain vertical")
    func loadsLegacyPosition() throws {
        let suiteName = "FileStandbyTests.EdgeHandle.Legacy.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "FileStandby.EdgeHandle.HasSavedPosition")
        defaults.set(-50.0, forKey: "FileStandby.EdgeHandle.OriginX")
        defaults.set(20.0, forKey: "FileStandby.EdgeHandle.OriginY")

        #expect(
            EdgeHandlePositionStore(defaults: defaults).load()
                == EdgeHandleSavedPlacement(origin: CGPoint(x: -50, y: 20), dock: .free)
        )
    }

    @Test("rejects damaged coordinates and repairs an unknown edge")
    func rejectsDamagedCoordinates() throws {
        let suiteName = "FileStandbyTests.EdgeHandle.Invalid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "FileStandby.EdgeHandle.HasSavedPosition")
        defaults.set(Double.nan, forKey: "FileStandby.EdgeHandle.OriginX")
        defaults.set(20.0, forKey: "FileStandby.EdgeHandle.OriginY")

        #expect(EdgeHandlePositionStore(defaults: defaults).load() == nil)

        defaults.set(10.0, forKey: "FileStandby.EdgeHandle.OriginX")
        defaults.set("sideways", forKey: "FileStandby.EdgeHandle.Dock")
        #expect(
            EdgeHandlePositionStore(defaults: defaults).load()
                == EdgeHandleSavedPlacement(origin: CGPoint(x: 10, y: 20), dock: .free)
        )
    }
}

@Suite("Shelf placement near the receiver")
struct ShelfWindowPlacementTests {
    private let screen = EdgeHandleScreen(
        frame: CGRect(x: 0, y: 0, width: 1_440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1_440, height: 900)
    )
    private let shelfSize = CGSize(width: 340, height: 470)

    @Test("places the shelf inside each edge with a matching collapse arrow")
    func placesShelfAtAllFourEdges() throws {
        let right = try layout(
            handleFrame: CGRect(x: 1_412, y: 394, width: 26, height: 112),
            dock: .right
        )
        #expect(right.origin == CGPoint(x: 1_060, y: 215))
        #expect(right.collapseDirection == .right)

        let left = try layout(
            handleFrame: CGRect(x: 2, y: 394, width: 26, height: 112),
            dock: .left
        )
        #expect(left.origin == CGPoint(x: 40, y: 215))
        #expect(left.collapseDirection == .left)

        let top = try layout(
            handleFrame: CGRect(x: 664, y: 872, width: 112, height: 26),
            dock: .top
        )
        #expect(top.origin == CGPoint(x: 550, y: 390))
        #expect(top.collapseDirection == .up)

        let bottom = try layout(
            handleFrame: CGRect(x: 664, y: 2, width: 112, height: 26),
            dock: .bottom
        )
        #expect(bottom.origin == CGPoint(x: 550, y: 40))
        #expect(bottom.collapseDirection == .down)
    }

    @Test("free receiver chooses the nearest screen edge")
    func freeReceiverUsesNearestEdge() throws {
        let nearRight = try layout(
            handleFrame: CGRect(x: 1_200, y: 300, width: 26, height: 112),
            dock: .free
        )
        #expect(nearRight.collapseDirection == .right)

        let nearBottom = try layout(
            handleFrame: CGRect(x: 600, y: 30, width: 26, height: 112),
            dock: .free
        )
        #expect(nearBottom.collapseDirection == .down)
    }

    @Test("arrow follows the receiver without moving the shelf")
    func arrowUsesActualRelativeDirectionForFreeReceiver() {
        let shelfFrame = CGRect(x: 500, y: 250, width: 340, height: 470)
        #expect(
            ShelfWindowPlacement.collapseDirection(
                shelfFrame: shelfFrame,
                handleFrame: CGRect(x: 1_200, y: 450, width: 26, height: 112),
                handleDock: .free
            ) == .right
        )
        #expect(
            ShelfWindowPlacement.collapseDirection(
                shelfFrame: shelfFrame,
                handleFrame: CGRect(x: 620, y: 800, width: 112, height: 26),
                handleDock: .top
            ) == .up
        )
    }

    private func layout(
        handleFrame: CGRect,
        dock: EdgeHandleDock
    ) throws -> ShelfWindowLayout {
        try #require(
            ShelfWindowPlacement.layout(
                shelfSize: shelfSize,
                handleFrame: handleFrame,
                handleDock: dock,
                screens: [screen]
            )
        )
    }
}

@Suite("Shelf window movement")
@MainActor
struct ShelfWindowMovementTests {
    @Test("only the explicit title drag area can move the shelf")
    func onlyTitleMovesWindow() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileStandbyWindowTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ShelfStore(
            persistence: ShelfPersistence(fileURL: directory.appendingPathComponent("shelf.json"))
        )
        let controller = ShelfPanelController(store: store)
        let window = try #require(controller.window)

        #expect(!window.isMovableByWindowBackground)
        #expect(window.contentView?.mouseDownCanMoveWindow == false)
        #expect(WindowDragNSView().mouseDownCanMoveWindow)
    }

    @Test("both receiver orientations still accept file URL drops")
    func fileDropRegistrationSurvivesOrientationChanges() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileStandbyDropRegistrationTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ShelfStore(
            persistence: ShelfPersistence(fileURL: directory.appendingPathComponent("shelf.json"))
        )
        let rootView = ShelfView(
            store: store,
            presentationState: ShelfPresentationState(),
            onHide: {},
            onQuit: {}
        )
        let shelfView = ShelfDropHostingView(rootView: rootView)
        let edgeView = EdgeDropView(
            frame: NSRect(origin: .zero, size: EdgeHandlePlacement.verticalSize)
        )

        #expect(shelfView.registeredDraggedTypes.contains(.fileURL))
        #expect(edgeView.registeredDraggedTypes.contains(.fileURL))

        edgeView.frame.size = EdgeHandlePlacement.horizontalSize
        #expect(edgeView.bounds.size == EdgeHandlePlacement.horizontalSize)
        #expect(edgeView.registeredDraggedTypes.contains(.fileURL))
    }
}
