import SwiftUI

struct Brick: Identifiable {
    let id = UUID()
    let rect: CGRect
    let color: Color
    var isBroken = false
}

struct GameLayout {
    let ballSize: CGFloat = 16
    let paddleWidth: CGFloat = 110
    let paddleHeight: CGFloat = 14
    let horizontalInset: CGFloat = 12
    let topInset: CGFloat = 90
    let paddleBottomOffset: CGFloat = 40
    let brickRows = 10
    let brickColumns = 6
    let minBallSpeed: CGFloat = 1.2
    let maxBallSpeed: CGFloat = 4.8
    let passiveAccelerationPerTick: CGFloat = 0.0035
    let flickVelocityWeightOld: CGFloat = 0.65
    let flickVelocityWeightNew: CGFloat = 0.35
    let flickHorizontalMultiplier: CGFloat = 0.0032
    let flickSpeedMultiplier: CGFloat = 0.0009
    let maxFlickSpeedBoost: CGFloat = 2.6
    let paddleBounceOffsetMultiplier: CGFloat = 1.5
}

// This file defines shared game data models and tuning constants.
