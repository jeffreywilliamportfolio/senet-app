import SwiftUI
import SenetRules

struct TutorialView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selection = 0

    private let steps = TutorialStep.makeSteps()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tutorial")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)

                Spacer()

                Button("Exit") {
                    viewModel.exitTutorial()
                }
                .buttonStyle(SenetSecondaryButtonStyle())
            }

            TabView(selection: $selection) {
                ForEach(steps) { step in
                    TutorialPageView(
                        step: step,
                        humanColor: viewModel.humanColor,
                        computerColor: viewModel.computerColor
                    )
                    .tag(step.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack(spacing: 12) {
                Button("Back") {
                    withAnimation(.easeInOut) {
                        selection = max(0, selection - 1)
                    }
                }
                .buttonStyle(SenetSecondaryButtonStyle())
                .disabled(selection == 0)

                Spacer()

                if selection == steps.count - 1 {
                    Button("Start Game") {
                        viewModel.startGame()
                    }
                    .buttonStyle(SenetPrimaryButtonStyle())
                } else {
                    Button("Next") {
                        withAnimation(.easeInOut) {
                            selection = min(steps.count - 1, selection + 1)
                        }
                    }
                    .buttonStyle(SenetPrimaryButtonStyle())
                }
            }
        }
        .padding(24)
    }
}

struct TutorialPageView: View {
    let step: TutorialStep
    let humanColor: Color
    let computerColor: Color

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
                    .multilineTextAlignment(.center)

                if let board = step.board {
                    TutorialBoardCard(
                        board: board,
                        humanColor: humanColor,
                        computerColor: computerColor
                    )
                }

                Text(step.body)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(SenetTheme.mutedInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                SenetCardBackground(cornerRadius: 22, showsOrnaments: true, shadowRadius: 18, shadowY: 8)
            )
        }
    }
}

struct TutorialBoardCard: View {
    let board: TutorialBoard
    let humanColor: Color
    let computerColor: Color

    var body: some View {
        VStack(spacing: 8) {
            BoardView(
                state: board.state,
                selectedPieceID: board.selectedPieceID,
                legalDestinations: board.legalDestinations,
                movablePieceIDs: [],
                captureFlashSquare: nil,
                waterSweepToken: nil,
                isWaterSweepActive: false,
                humanColor: humanColor,
                computerColor: computerColor,
                onSquareTap: { _ in }
            )
            .aspectRatio(10.0 / 3.0, contentMode: .fit)

            if let caption = board.caption {
                Text(caption)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(SenetTheme.mutedInk)
            }
        }
    }
}

struct TutorialBoard {
    let state: GameState
    let selectedPieceID: PieceID?
    let legalDestinations: Set<Int>
    let caption: String?
}

struct TutorialStep: Identifiable {
    let id: Int
    let title: String
    let body: String
    let board: TutorialBoard?

    static func makeSteps() -> [TutorialStep] {
        let base = SenetRules.newGame()

        let startBoard = TutorialBoard(
            state: base,
            selectedPieceID: nil,
            legalDestinations: [],
            caption: "Pieces start on squares 1–10, alternating by color."
        )

        let throwBoard = TutorialBoard(
            state: base,
            selectedPieceID: PieceID(0),
            legalDestinations: [4],
            caption: "Example: a throw of 3 highlights square 4."
        )

        let captureState = adjustedState(
            base,
            updates: [
                (PieceID(0), 12, false),
                (PieceID(100), 15, false),
                (PieceID(101), 16, false)
            ]
        )

        let captureBoard = TutorialBoard(
            state: captureState,
            selectedPieceID: PieceID(0),
            legalDestinations: [],
            caption: "Safe squares (15, 26–29) and protected pairs block captures."
        )

        let gateState = adjustedState(
            base,
            updates: [
                (PieceID(0), 24, false),
                (PieceID(100), 27, false)
            ]
        )

        let gateBoard = TutorialBoard(
            state: gateState,
            selectedPieceID: PieceID(0),
            legalDestinations: [26],
            caption: "You must land on 26 before moving beyond it."
        )

        return [
            TutorialStep(
                id: 0,
                title: "Goal and Path",
                body: "Each player has 5 pieces. Move yours along the 3×10 path (top row left-to-right, middle row right-to-left, bottom row left-to-right). The first player to move all pieces off the board wins.",
                board: startBoard
            ),
            TutorialStep(
                id: 1,
                title: "Throw and Move",
                body: "Tap Throw to roll 1–5. Tap one of your pieces, then tap a highlighted destination to move.",
                board: throwBoard
            ),
            TutorialStep(
                id: 2,
                title: "Captures and Safety",
                body: "Landing on an opponent swaps positions (capture) unless the square is safe (15, 26–29) or the opponent is protected by an adjacent ally.",
                board: captureBoard
            ),
            TutorialStep(
                id: 3,
                title: "Gate and Water",
                body: "You must land on the gate at 26 before moving beyond it. Landing on water (27) sends you back to the return square (15) or the nearest open square before it.",
                board: gateBoard
            ),
            TutorialStep(
                id: 4,
                title: "Extra Turns and Finish",
                body: "Throws of 1, 4, or 5 grant an extra turn. To bear off, you need an exact throw from 28, 29, or 30. Clear all your pieces to win.",
                board: nil
            )
        ]
    }

    private static func adjustedState(_ state: GameState, updates: [(PieceID, Int?, Bool)]) -> GameState {
        var next = state
        for (id, position, visitedGate) in updates {
            if let index = next.pieces.firstIndex(where: { $0.id == id }) {
                next.pieces[index].position = position
                next.pieces[index].hasVisitedGate = visitedGate
            }
        }
        return next
    }
}
