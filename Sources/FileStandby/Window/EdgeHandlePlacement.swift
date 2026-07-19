import Foundation

enum EdgeHandleDock: String, Equatable {
    case free
    case top
    case bottom
    case left
    case right

    var isHorizontal: Bool {
        self == .top || self == .bottom
    }
}

enum EdgeHandlePointerEnd: Equatable {
    case click
    case moved
    case inactive
}

struct EdgeHandleScreen: Equatable {
    let frame: CGRect
    let visibleFrame: CGRect
}

struct EdgeHandleDragUpdate: Equatable {
    let screenLocation: CGPoint
    let normalizedAnchor: CGPoint
}

struct EdgeHandleLayout: Equatable {
    let origin: CGPoint
    let size: CGSize
    let dock: EdgeHandleDock
}

struct EdgeHandleSavedPlacement: Equatable {
    let origin: CGPoint
    let dock: EdgeHandleDock
}

struct EdgeHandlePointerInteraction {
    private var startScreenLocation: CGPoint?
    private var normalizedAnchor: CGPoint?
    private var didMove = false

    mutating func begin(
        screenLocation: CGPoint,
        pointerOffsetInWindow: CGPoint,
        windowSize: CGSize
    ) {
        startScreenLocation = screenLocation
        normalizedAnchor = CGPoint(
            x: Self.normalized(pointerOffsetInWindow.x, extent: windowSize.width),
            y: Self.normalized(pointerOffsetInWindow.y, extent: windowSize.height)
        )
        didMove = false
    }

    mutating func dragUpdate(
        at currentScreenLocation: CGPoint,
        movementThreshold: CGFloat = 3
    ) -> EdgeHandleDragUpdate? {
        guard let startScreenLocation,
              let normalizedAnchor
        else { return nil }

        if !didMove {
            let deltaX = currentScreenLocation.x - startScreenLocation.x
            let deltaY = currentScreenLocation.y - startScreenLocation.y
            guard hypot(deltaX, deltaY) > movementThreshold else { return nil }
            didMove = true
        }

        return EdgeHandleDragUpdate(
            screenLocation: currentScreenLocation,
            normalizedAnchor: normalizedAnchor
        )
    }

    mutating func endResult() -> EdgeHandlePointerEnd {
        let result: EdgeHandlePointerEnd
        if startScreenLocation == nil {
            result = .inactive
        } else if didMove {
            result = .moved
        } else {
            result = .click
        }
        cancel()
        return result
    }

    mutating func endShouldOpen() -> Bool {
        endResult() == .click
    }

    mutating func cancel() {
        startScreenLocation = nil
        normalizedAnchor = nil
        didMove = false
    }

    private static func normalized(_ value: CGFloat, extent: CGFloat) -> CGFloat {
        guard value.isFinite, extent.isFinite, extent > 0 else { return 0.5 }
        return min(max(value / extent, 0), 1)
    }
}

struct EdgeHandlePlacement {
    static let handleThickness: CGFloat = 26
    static let handleLength: CGFloat = 112
    static let verticalSize = CGSize(width: handleThickness, height: handleLength)
    static let horizontalSize = CGSize(width: handleLength, height: handleThickness)
    static let screenMargin: CGFloat = 2

    static func dragLayout(
        for update: EdgeHandleDragUpdate,
        currentDock: EdgeHandleDock,
        screens: [EdgeHandleScreen],
        margin: CGFloat = screenMargin
    ) -> EdgeHandleLayout {
        let validScreens = validScreens(screens)
        let safeLocation = finitePoint(update.screenLocation)
            ?? validScreens.first.map { center(of: $0.visibleFrame) }
            ?? .zero
        let anchor = CGPoint(
            x: finiteUnitCoordinate(update.normalizedAnchor.x),
            y: finiteUnitCoordinate(update.normalizedAnchor.y)
        )

        guard let screen = screen(containingOrNearestTo: safeLocation, among: validScreens) else {
            let size = size(for: currentDock)
            return EdgeHandleLayout(
                origin: origin(for: safeLocation, anchor: anchor, size: size),
                size: size,
                dock: currentDock
            )
        }

        let dock = resolvedDock(
            for: safeLocation,
            currentDock: currentDock,
            visibleFrame: screen.visibleFrame
        )
        let size = size(for: dock)
        let requestedOrigin = origin(for: safeLocation, anchor: anchor, size: size)
        var placedOrigin = clampedOrigin(
            requestedOrigin,
            panelSize: size,
            visibleFrames: [screen.visibleFrame],
            margin: margin
        )

        switch dock {
        case .free:
            break
        case .top:
            placedOrigin.y = screen.visibleFrame.maxY - size.height - margin
        case .bottom:
            placedOrigin.y = screen.visibleFrame.minY + margin
        case .left:
            placedOrigin.x = screen.visibleFrame.minX + margin
        case .right:
            placedOrigin.x = screen.visibleFrame.maxX - size.width - margin
        }

        return EdgeHandleLayout(origin: placedOrigin, size: size, dock: dock)
    }

    static func restoredLayout(
        for placement: EdgeHandleSavedPlacement,
        screens: [EdgeHandleScreen],
        margin: CGFloat = screenMargin
    ) -> EdgeHandleLayout {
        let initialSize = size(for: placement.dock)
        let validScreens = validScreens(screens)
        let visibleFrames = validScreens.map(\.visibleFrame)
        let initialOrigin = clampedOrigin(
            placement.origin,
            panelSize: initialSize,
            visibleFrames: visibleFrames,
            margin: margin
        )

        guard let screen = screen(
                overlappingOrNearestTo: CGRect(origin: initialOrigin, size: initialSize),
                among: validScreens
              )
        else {
            return EdgeHandleLayout(
                origin: initialOrigin,
                size: initialSize,
                dock: placement.dock == .free ? .right : placement.dock
            )
        }

        let initialCenter = CGPoint(
            x: initialOrigin.x + initialSize.width / 2,
            y: initialOrigin.y + initialSize.height / 2
        )
        let dock = placement.dock == .free
            ? resolvedDock(
                for: initialCenter,
                currentDock: .free,
                visibleFrame: screen.visibleFrame
              )
            : placement.dock
        let size = size(for: dock)
        var origin = clampedOrigin(
            CGPoint(
                x: initialCenter.x - size.width / 2,
                y: initialCenter.y - size.height / 2
            ),
            panelSize: size,
            visibleFrames: [screen.visibleFrame],
            margin: margin
        )
        switch dock {
        case .free:
            break
        case .top:
            origin.y = screen.visibleFrame.maxY - size.height - margin
        case .bottom:
            origin.y = screen.visibleFrame.minY + margin
        case .left:
            origin.x = screen.visibleFrame.minX + margin
        case .right:
            origin.x = screen.visibleFrame.maxX - size.width - margin
        }

        return EdgeHandleLayout(origin: origin, size: size, dock: dock)
    }

    static func clampedOrigin(
        _ origin: CGPoint,
        panelSize: CGSize,
        visibleFrames: [CGRect],
        margin: CGFloat = screenMargin
    ) -> CGPoint {
        let validFrames = visibleFrames.filter(isValidRect)
        guard panelSize.width.isFinite,
              panelSize.height.isFinite,
              panelSize.width > 0,
              panelSize.height > 0,
              let firstFrame = validFrames.first
        else {
            return origin
        }

        let safeOrigin = finitePoint(origin) ?? CGPoint(
            x: firstFrame.minX + margin,
            y: firstFrame.midY - panelSize.height / 2
        )

        guard let targetFrame = targetFrame(
            for: CGRect(origin: safeOrigin, size: panelSize),
            among: validFrames
        ) else {
            return safeOrigin
        }

        return CGPoint(
            x: clamp(
                safeOrigin.x,
                lowerBound: targetFrame.minX + margin,
                upperBound: targetFrame.maxX - panelSize.width - margin
            ),
            y: clamp(
                safeOrigin.y,
                lowerBound: targetFrame.minY + margin,
                upperBound: targetFrame.maxY - panelSize.height - margin
            )
        )
    }

    private static func size(for dock: EdgeHandleDock) -> CGSize {
        dock.isHorizontal ? horizontalSize : verticalSize
    }

    private static func origin(
        for screenLocation: CGPoint,
        anchor: CGPoint,
        size: CGSize
    ) -> CGPoint {
        CGPoint(
            x: screenLocation.x - anchor.x * size.width,
            y: screenLocation.y - anchor.y * size.height
        )
    }

    private static func resolvedDock(
        for location: CGPoint,
        currentDock: EdgeHandleDock,
        visibleFrame: CGRect
    ) -> EdgeHandleDock {
        let candidates: [(dock: EdgeHandleDock, distance: CGFloat)] = [
            (.top, max(visibleFrame.maxY - location.y, 0)),
            (.bottom, max(location.y - visibleFrame.minY, 0)),
            (.left, max(location.x - visibleFrame.minX, 0)),
            (.right, max(visibleFrame.maxX - location.x, 0))
        ]
        let closestCandidate = candidates.min(by: { $0.distance < $1.distance })
        guard let closestCandidate else { return .right }

        let currentDistance: CGFloat
        switch currentDock {
        case .top:
            currentDistance = max(visibleFrame.maxY - location.y, 0)
        case .bottom:
            currentDistance = max(location.y - visibleFrame.minY, 0)
        case .left:
            currentDistance = max(location.x - visibleFrame.minX, 0)
        case .right:
            currentDistance = max(visibleFrame.maxX - location.x, 0)
        case .free:
            return closestCandidate.dock
        }

        let edgeSwitchBias: CGFloat = 4
        if closestCandidate.dock != currentDock,
           closestCandidate.distance + edgeSwitchBias < currentDistance {
            return closestCandidate.dock
        }
        return currentDock
    }

    private static func validScreens(_ screens: [EdgeHandleScreen]) -> [EdgeHandleScreen] {
        screens.filter { isValidRect($0.frame) && isValidRect($0.visibleFrame) }
    }

    private static func screen(
        containingOrNearestTo point: CGPoint,
        among screens: [EdgeHandleScreen]
    ) -> EdgeHandleScreen? {
        screens.first(where: { $0.frame.contains(point) })
            ?? screens.min {
                squaredDistance(from: point, to: $0.frame)
                    < squaredDistance(from: point, to: $1.frame)
            }
    }

    private static func screen(
        overlappingOrNearestTo panelFrame: CGRect,
        among screens: [EdgeHandleScreen]
    ) -> EdgeHandleScreen? {
        guard !screens.isEmpty else { return nil }

        let overlaps = screens.map { screen in
            (screen: screen, area: intersectionArea(panelFrame, screen.visibleFrame))
        }
        if let overlappingScreen = overlaps.max(by: { $0.area < $1.area }),
           overlappingScreen.area > 0 {
            return overlappingScreen.screen
        }

        let panelCenter = center(of: panelFrame)
        return screens.min {
            squaredDistance(from: panelCenter, to: $0.visibleFrame)
                < squaredDistance(from: panelCenter, to: $1.visibleFrame)
        }
    }

    private static func targetFrame(for panelFrame: CGRect, among frames: [CGRect]) -> CGRect? {
        guard !frames.isEmpty else { return nil }

        let intersections = frames.map { frame in
            (frame: frame, area: intersectionArea(panelFrame, frame))
        }
        if let overlappingFrame = intersections.max(by: { $0.area < $1.area }),
           overlappingFrame.area > 0 {
            return overlappingFrame.frame
        }

        let panelCenter = center(of: panelFrame)
        return frames.min {
            squaredDistance(from: panelCenter, to: $0)
                < squaredDistance(from: panelCenter, to: $1)
        }
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        return intersection.width * intersection.height
    }

    private static func center(of rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let xDistance = max(max(rect.minX - point.x, 0), point.x - rect.maxX)
        let yDistance = max(max(rect.minY - point.y, 0), point.y - rect.maxY)
        return xDistance * xDistance + yDistance * yDistance
    }

    private static func finitePoint(_ point: CGPoint) -> CGPoint? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        return point
    }

    private static func finiteUnitCoordinate(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0.5 }
        return min(max(value, 0), 1)
    }

    private static func isValidRect(_ rect: CGRect) -> Bool {
        rect.origin.x.isFinite
            && rect.origin.y.isFinite
            && rect.width.isFinite
            && rect.height.isFinite
            && rect.width > 0
            && rect.height > 0
    }

    private static func clamp(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        guard upperBound >= lowerBound else { return lowerBound }
        return min(max(value, lowerBound), upperBound)
    }
}

@MainActor
final class EdgeHandlePositionStore {
    private enum Key {
        static let hasSavedPosition = "FileStandby.EdgeHandle.HasSavedPosition"
        static let originX = "FileStandby.EdgeHandle.OriginX"
        static let originY = "FileStandby.EdgeHandle.OriginY"
        static let dock = "FileStandby.EdgeHandle.Dock"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> EdgeHandleSavedPlacement? {
        guard defaults.bool(forKey: Key.hasSavedPosition) else { return nil }
        let x = defaults.double(forKey: Key.originX)
        let y = defaults.double(forKey: Key.originY)
        guard x.isFinite, y.isFinite else { return nil }
        let dock = defaults.string(forKey: Key.dock)
            .flatMap(EdgeHandleDock.init(rawValue:))
            ?? .free
        return EdgeHandleSavedPlacement(origin: CGPoint(x: x, y: y), dock: dock)
    }

    func save(_ placement: EdgeHandleSavedPlacement) {
        guard placement.origin.x.isFinite, placement.origin.y.isFinite else { return }
        defaults.set(Double(placement.origin.x), forKey: Key.originX)
        defaults.set(Double(placement.origin.y), forKey: Key.originY)
        defaults.set(placement.dock.rawValue, forKey: Key.dock)
        defaults.set(true, forKey: Key.hasSavedPosition)
    }
}
