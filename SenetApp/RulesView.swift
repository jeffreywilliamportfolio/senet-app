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
                    Text("3x10 path reference")
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
                        iconName: "special-glyph-01",
                        title: "The Path",
                        text: "Place five pieces on squares 1–10, alternating by player. The path runs left to right on the top row, right to left on the middle row, and left to right on the bottom row."
                    )

                    RuleSection(
                        iconName: "special-glyph-02",
                        title: "The Throw",
                        text: "A throw yields a value from 1 to 5. Move exactly one piece forward by that count along the path."
                    )

                    RuleSection(
                        iconName: "special-glyph-03",
                        title: "Captures and Protection",
                        text: "Landing on an opponent swaps positions unless the target square is safe (15, 26–29) or the opponent is protected by an adjacent ally."
                    )

                    RuleSection(
                        iconName: "special-glyph-04",
                        title: "Gate and Water",
                        text: "You must land on square 26 before moving beyond it. Landing on square 27 sends the piece to square 15 or the nearest open square before it."
                    )

                    RuleSection(
                        iconName: "special-glyph-05",
                        title: "Blockades",
                        text: "Three consecutive friendly pieces form a blockade. Opponents cannot pass a blockade in a single move."
                    )

                    RuleSection(
                        iconName: "selection-ring",
                        title: "Extra Turns and Victory",
                        text: "Throws of 1, 4, or 5 grant another turn. To bear off, you need an exact throw from squares 28, 29, and 30. Clear all pieces to win."
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
    let iconName: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(SenetTheme.accent.opacity(0.25))

                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .opacity(0.85)
                }
                .frame(width: 36, height: 36)

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(SenetTheme.mutedInk)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            SenetCardBackground(cornerRadius: 18, showsOrnaments: false, shadowRadius: 16, shadowY: 6)
        )
    }
}
