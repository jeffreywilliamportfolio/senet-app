import SwiftUI

struct RulesView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rules of Senet")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(SenetTheme.ink)
                    Text("The tablets of the 3x10 path")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(SenetTheme.mutedInk)
                        .textCase(.uppercase)
                        .tracking(2)
                }

                Spacer()

                Button("Back") {
                    viewModel.exitRules()
                }
                .buttonStyle(SenetSecondaryButtonStyle())
            }

            ScrollView {
                VStack(spacing: 16) {
                    RuleSection(
                        glyph: "ANKH",
                        title: "The Path",
                        body: "O traveler, set your five stones upon squares 1 through 10, alternating with your rival. The road flows left to right on the top row, right to left on the middle row, and left to right on the bottom row."
                    )

                    RuleSection(
                        glyph: "SCARAB",
                        title: "The Throw",
                        body: "Cast the sticks to reveal a value from 1 to 5. Choose one of your stones and move it forward by that count, following the winding path."
                    )

                    RuleSection(
                        glyph: "EYE",
                        title: "Captures and Protection",
                        body: "Landing on an enemy swaps places, unless the target square is sacred or the enemy is protected by an ally beside it. Sacred squares are 15 and 26 through 29."
                    )

                    RuleSection(
                        glyph: "GATE",
                        title: "Gate and Water",
                        body: "You must land on the gate at square 26 before moving beyond it. If you land on the water at 27, your stone returns to the rebirth square 15 or the nearest open square before it."
                    )

                    RuleSection(
                        glyph: "CROOK",
                        title: "Blockades",
                        body: "Two adjacent enemy stones form a wall. You may not pass through that wall in a single move."
                    )

                    RuleSection(
                        glyph: "SUN",
                        title: "Extra Turns and Victory",
                        body: "A throw of 1, 4, or 5 grants another turn. To bear off from squares 28, 29, and 30 you must roll the exact count. The first to clear all stones from the board claims victory."
                    )
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button("How To Play") {
                    viewModel.showTutorial()
                }
                .buttonStyle(SenetSecondaryButtonStyle())

                Spacer()

                Button("Start Game") {
                    viewModel.startGame()
                }
                .buttonStyle(SenetPrimaryButtonStyle())
            }
        }
        .padding(24)
    }
}

struct RuleSection: View {
    let glyph: String
    let title: String
    let body: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(glyph)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(SenetTheme.accent.opacity(0.5))
                    )
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
            }

            Text(body)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(SenetTheme.mutedInk)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SenetTheme.cardFill)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SenetTheme.cardStroke, lineWidth: 1)
        )
    }
}
