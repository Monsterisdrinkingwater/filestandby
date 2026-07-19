import Foundation
import Observation

enum ShelfCollapseDirection: Equatable {
    case up
    case down
    case left
    case right

    var systemImage: String {
        switch self {
        case .up: "chevron.up"
        case .down: "chevron.down"
        case .left: "chevron.left"
        case .right: "chevron.right"
        }
    }
}

@MainActor
@Observable
final class ShelfPresentationState {
    var collapseDirection: ShelfCollapseDirection = .right
}

struct ShelfWindowLayout: Equatable {
    let origin: CGPoint
    let collapseDirection: ShelfCollapseDirection
}

struct ShelfWindowPlacement {
    static let handleGap: CGFloat = 12
    static let screenMargin: CGFloat = 12

    static func layout(
        shelfSize: CGSize,
        handleFrame: CGRect,
        handleDock: EdgeHandleDock,
        screens: [EdgeHandleScreen],
        gap: CGFloat = handleGap,
        margin: CGFloat = screenMargin
    ) -> ShelfWindowLayout? {
        guard shelfSize.width.isFinite,
              shelfSize.height.isFinite,
              shelfSize.width > 0,
              shelfSize.height > 0,
              let screen = targetScreen(for: handleFrame, among: screens)
        else { return nil }

        let direction = preferredDirection(
            for: handleFrame,
            dock: handleDock,
            visibleFrame: screen.visibleFrame
        )
        let idealOrigin = adjacentOrigin(
            shelfSize: shelfSize,
            handleFrame: handleFrame,
            direction: direction,
            gap: max(gap, 0)
        )
        let visibleFrame = screen.visibleFrame
        let origin = CGPoint(
            x: clamp(
                idealOrigin.x,
                lowerBound: visibleFrame.minX + margin,
                upperBound: visibleFrame.maxX - shelfSize.width - margin
            ),
            y: clamp(
                idealOrigin.y,
                lowerBound: visibleFrame.minY + margin,
                upperBound: visibleFrame.maxY - shelfSize.height - margin
            )
        )
        return ShelfWindowLayout(origin: origin, collapseDirection: direction)
    }

    static func collapseDirection(
        shelfFrame: CGRect,
        handleFrame: CGRect,
        handleDock: EdgeHandleDock,
        fallback: ShelfCollapseDirection = .right
    ) -> ShelfCollapseDirection {
        switch handleDock {
        case .top: return .up
        case .bottom: return .down
        case .left: return .left
        case .right: return .right
        case .free:
            let deltaX = handleFrame.midX - shelfFrame.midX
            let deltaY = handleFrame.midY - shelfFrame.midY
            guard deltaX.isFinite, deltaY.isFinite else { return fallback }
            if abs(deltaX) >= abs(deltaY), deltaX != 0 {
                return deltaX < 0 ? .left : .right
            }
            if deltaY != 0 {
                return deltaY < 0 ? .down : .up
            }
            return fallback
        }
    }

    private static func preferredDirection(
        for handleFrame: CGRect,
        dock: EdgeHandleDock,
        visibleFrame: CGRect
    ) -> ShelfCollapseDirection {
        switch dock {
        case .top: return .up
        case .bottom: return .down
        case .left: return .left
        case .right: return .right
        case .free:
            let center = CGPoint(x: handleFrame.midX, y: handleFrame.midY)
            let candidates: [(direction: ShelfCollapseDirection, distance: CGFloat)] = [
                (.right, abs(visibleFrame.maxX - center.x)),
                (.left, abs(center.x - visibleFrame.minX)),
                (.up, abs(visibleFrame.maxY - center.y)),
                (.down, abs(center.y - visibleFrame.minY))
            ]
            return candidates.min(by: { $0.distance < $1.distance })?.direction ?? .right
        }
    }

    private static func adjacentOrigin(
        shelfSize: CGSize,
        handleFrame: CGRect,
        direction: ShelfCollapseDirection,
        gap: CGFloat
    ) -> CGPoint {
        switch direction {
        case .right:
            return CGPoint(
                x: handleFrame.minX - gap - shelfSize.width,
                y: handleFrame.midY - shelfSize.height / 2
            )
        case .left:
            return CGPoint(
                x: handleFrame.maxX + gap,
                y: handleFrame.midY - shelfSize.height / 2
            )
        case .up:
            return CGPoint(
                x: handleFrame.midX - shelfSize.width / 2,
                y: handleFrame.minY - gap - shelfSize.height
            )
        case .down:
            return CGPoint(
                x: handleFrame.midX - shelfSize.width / 2,
                y: handleFrame.maxY + gap
            )
        }
    }

    private static func targetScreen(
        for handleFrame: CGRect,
        among screens: [EdgeHandleScreen]
    ) -> EdgeHandleScreen? {
        let validScreens = screens.filter {
            isValidRect($0.frame) && isValidRect($0.visibleFrame)
        }
        guard !validScreens.isEmpty else { return nil }

        let overlaps = validScreens.map { screen in
            (screen: screen, area: intersectionArea(handleFrame, screen.visibleFrame))
        }
        if let overlapping = overlaps.max(by: { $0.area < $1.area }),
           overlapping.area > 0 {
            return overlapping.screen
        }

        let handleCenter = CGPoint(x: handleFrame.midX, y: handleFrame.midY)
        return validScreens.min {
            squaredDistance(from: handleCenter, to: $0.visibleFrame)
                < squaredDistance(from: handleCenter, to: $1.visibleFrame)
        }
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        return intersection.width * intersection.height
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let xDistance = max(max(rect.minX - point.x, 0), point.x - rect.maxX)
        let yDistance = max(max(rect.minY - point.y, 0), point.y - rect.maxY)
        return xDistance * xDistance + yDistance * yDistance
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
