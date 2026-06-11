import SwiftUI
import Combine

struct GameBoardView: View {
    @StateObject private var engine = BrickGameEngine()
    private let layout = GameLayout()
    private let timer = Timer.publish(every: 1 / 120, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [.black, .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Text("Score: \(engine.score)")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        if !engine.gameStarted {
                            Text("Drag paddle to start")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    Spacer()
                }

                ForEach(engine.bricks) { brick in
                    if !brick.isBroken {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(brick.color)
                            .frame(width: brick.rect.width, height: brick.rect.height)
                            .position(x: brick.rect.midX, y: brick.rect.midY)
                    }
                }

                Circle()
                    .fill(.white)
                    .frame(width: layout.ballSize, height: layout.ballSize)
                    .position(x: engine.ballPosition.x, y: engine.ballPosition.y)

                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black, lineWidth: 2)
                    )
                    .frame(width: layout.paddleWidth, height: layout.paddleHeight)
                    .position(x: engine.paddleCenterX, y: geo.size.height - layout.paddleBottomOffset)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        engine.handleDragChanged(locationX: value.location.x, canvasWidth: geo.size.width)
                    }
                    .onEnded { _ in
                        engine.handleDragEnded()
                    }
            )
            .onAppear {
                engine.setupGame(in: geo.size)
            }
            .onReceive(timer) { _ in
                engine.updateBall(in: geo.size)
            }
            .alert("Game Over", isPresented: $engine.showGameOver) {
                Button("Play Again") {
                    engine.setupGame(in: geo.size)
                }
            } message: {
                Text("Final score: \(engine.score)")
            }
        }
    }
}

// This file renders the game scene and forwards user input to the engine.
