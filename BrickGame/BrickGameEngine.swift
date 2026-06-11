import SwiftUI
import Combine

final class BrickGameEngine: ObservableObject {
    @Published var ballPosition = CGPoint(x: 160, y: 420)
    @Published var ballVelocity = CGVector(dx: 2.0, dy: -2.2)
    @Published var paddleCenterX: CGFloat = 160
    @Published var score = 0
    @Published var bricks: [Brick] = []
    @Published var gameStarted = false
    @Published var showGameOver = false

    private let layout = GameLayout()
    private var lastDragX: CGFloat?
    private var lastDragTime: Date?
    private var paddleFlickVelocity: CGFloat = 0

    func setupGame(in size: CGSize) {
        score = 0
        gameStarted = false
        showGameOver = false
        paddleCenterX = size.width / 2
        ballPosition = CGPoint(x: size.width / 2, y: size.height - 70)
        ballVelocity = CGVector(dx: 2.0, dy: -2.2)
        lastDragX = nil
        lastDragTime = nil
        paddleFlickVelocity = 0
        bricks = makeBricks(in: size)
    }

    func handleDragChanged(locationX: CGFloat, canvasWidth: CGFloat) {
        let clampedX = min(
            max(locationX, layout.horizontalInset + layout.paddleWidth / 2),
            canvasWidth - layout.horizontalInset - layout.paddleWidth / 2
        )

        let now = Date()
        if let lastX = lastDragX, let lastTime = lastDragTime {
            let dt = CGFloat(now.timeIntervalSince(lastTime))
            if dt > 0 {
                let instantaneousVelocity = (clampedX - lastX) / dt
                paddleFlickVelocity = (paddleFlickVelocity * layout.flickVelocityWeightOld)
                    + (instantaneousVelocity * layout.flickVelocityWeightNew)
            }
        }

        paddleCenterX = clampedX
        lastDragX = clampedX
        lastDragTime = now

        if !gameStarted {
            gameStarted = true
        }
    }

    func handleDragEnded() {
        lastDragX = nil
        lastDragTime = nil
    }

    func updateBall(in size: CGSize) {
        guard gameStarted, !showGameOver else { return }

        var newPosition = CGPoint(
            x: ballPosition.x + ballVelocity.dx,
            y: ballPosition.y + ballVelocity.dy
        )
        var velocity = ballVelocity
        let radius = layout.ballSize / 2

        if newPosition.x - radius <= layout.horizontalInset
            || newPosition.x + radius >= size.width - layout.horizontalInset {
            velocity.dx *= -1
            newPosition.x = min(
                max(newPosition.x, layout.horizontalInset + radius),
                size.width - layout.horizontalInset - radius
            )
        }

        if newPosition.y - radius <= layout.horizontalInset {
            velocity.dy *= -1
            newPosition.y = layout.horizontalInset + radius
        }

        let paddleY = size.height - layout.paddleBottomOffset
        let paddleRect = CGRect(
            x: paddleCenterX - layout.paddleWidth / 2,
            y: paddleY - layout.paddleHeight / 2,
            width: layout.paddleWidth,
            height: layout.paddleHeight
        )

        let ballRect = CGRect(
            x: newPosition.x - radius,
            y: newPosition.y - radius,
            width: layout.ballSize,
            height: layout.ballSize
        )

        if ballRect.intersects(paddleRect), velocity.dy > 0 {
            let offset = (newPosition.x - paddleCenterX) / (layout.paddleWidth / 2)
            velocity.dy = -abs(velocity.dy)
            velocity.dx += offset * layout.paddleBounceOffsetMultiplier
            velocity.dx += paddleFlickVelocity * layout.flickHorizontalMultiplier

            let flickSpeedBoost = min(
                abs(paddleFlickVelocity) * layout.flickSpeedMultiplier,
                layout.maxFlickSpeedBoost
            )
            velocity = scaledVelocity(velocity, extraSpeed: flickSpeedBoost)

            newPosition.y = paddleRect.minY - radius
            paddleFlickVelocity *= 0.35
        }

        velocity = scaledVelocity(velocity, extraSpeed: layout.passiveAccelerationPerTick)

        for index in bricks.indices {
            guard !bricks[index].isBroken else { continue }
            if ballRect.intersects(bricks[index].rect) {
                bricks[index].isBroken = true
                score += 10
                velocity.dy *= -1
                break
            }
        }

        if bricks.allSatisfy(\.isBroken) {
            bricks = makeBricks(in: size)
        }

        if newPosition.y - radius > size.height {
            showGameOver = true
            gameStarted = false
        }

        ballPosition = newPosition
        ballVelocity = velocity
    }

    private func makeBricks(in size: CGSize) -> [Brick] {
        let spacing: CGFloat = 8
        let totalSpacing = CGFloat(layout.brickColumns - 1) * spacing
        let width = size.width - layout.horizontalInset * 2
        let brickWidth = (width - totalSpacing) / CGFloat(layout.brickColumns)
        let brickHeight: CGFloat = 20

        var result: [Brick] = []
        for row in 0..<layout.brickRows {
            for column in 0..<layout.brickColumns {
                let x = layout.horizontalInset + CGFloat(column) * (brickWidth + spacing)
                let y = layout.topInset + CGFloat(row) * (brickHeight + spacing)
                let rect = CGRect(x: x, y: y, width: brickWidth, height: brickHeight)
                let color = Color(
                    hue: Double(row) / Double(layout.brickRows),
                    saturation: 0.8,
                    brightness: 0.95
                )
                result.append(Brick(rect: rect, color: color))
            }
        }
        return result
    }

    private func scaledVelocity(_ velocity: CGVector, extraSpeed: CGFloat) -> CGVector {
        let dx = CGFloat(velocity.dx)
        let dy = CGFloat(velocity.dy)
        let currentSpeed = sqrt((dx * dx) + (dy * dy))
        guard currentSpeed > 0 else { return velocity }

        let targetSpeed = min(
            max(currentSpeed + extraSpeed, layout.minBallSpeed),
            layout.maxBallSpeed
        )
        let scale = targetSpeed / currentSpeed
        return CGVector(dx: dx * scale, dy: dy * scale)
    }
}

// This file owns game state, input handling, and physics updates.
