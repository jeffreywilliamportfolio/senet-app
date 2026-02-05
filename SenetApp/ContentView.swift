import SwiftUI
import SenetRules

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack(alignment: .top) {
            SenetBackdropView()

            switch viewModel.stage {
            case .setup:
                SetupView(viewModel: viewModel)
            case .tutorial:
                TutorialView(viewModel: viewModel)
            case .rules:
                RulesView(viewModel: viewModel)
            case .game:
                GameView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    enum Stage {
        case setup
        case tutorial
        case rules
        case game
    }

    enum PlayerColor: String, CaseIterable, Identifiable {
        case light
        case dark

        var id: String { rawValue }
    }

    struct UndoSnapshot {
        let state: GameState
        let currentThrow: Int?
        let selectedPieceID: PieceID?
        let legalMoves: [Move]
    }

    @Published var stage: Stage = .setup
    @Published var playerName: String = ""
    @Published var playerColor: PlayerColor = .light
    @Published private(set) var undoStack: [UndoSnapshot] = []

    @Published var state: GameState = SenetRules.newGame()
    @Published var currentThrow: Int?
    @Published var selectedPieceID: PieceID?
    @Published var legalMoves: [Move] = []
    @Published var captureFlashSquare: Int?
    @Published var waterSweepToken: UUID?
    @Published var isWaterSweepActive: Bool = false

    private var computerTurnToken = 0

    var humanColor: Color {
        switch playerColor {
        case .light: return Color(white: 0.92)
        case .dark: return Color(white: 0.15)
        }
    }

    var computerColor: Color {
        switch playerColor {
        case .light: return Color(white: 0.15)
        case .dark: return Color(white: 0.92)
        }
    }

    var legalDestinations: Set<Int> {
        Set(legalMoves.map { $0.to })
    }

    var visibleLegalDestinations: Set<Int> {
        guard let selectedPieceID else { return legalDestinations }
        let filtered = legalMoves.filter { $0.pieceID == selectedPieceID }.map { $0.to }
        return Set(filtered)
    }

    var movablePieceIDs: Set<PieceID> {
        Set(legalMoves.map { $0.pieceID })
    }

    func startGame() {
        state = SenetRules.newGame()
        currentThrow = nil
        selectedPieceID = nil
        legalMoves = []
        undoStack = []
        captureFlashSquare = nil
        waterSweepToken = nil
        isWaterSweepActive = false
        computerTurnToken += 1
        stage = .game
    }

    func resetToSetup() {
        computerTurnToken += 1
        stage = .setup
    }

    func showTutorial() {
        stage = .tutorial
    }

    func exitTutorial() {
        stage = .setup
    }

    func showRules() {
        stage = .rules
    }

    func exitRules() {
        stage = .setup
    }

    func undoLastMove() {
        guard let snapshot = undoStack.popLast() else { return }
        restore(snapshot)
    }

    func throwSticks() {
        guard state.status == .inProgress else { return }
        guard state.currentPlayer == .human else { return }
        guard currentThrow == nil else { return }

        let value = Int.random(in: 1...5)
        currentThrow = value
        legalMoves = SenetRules.legalMoves(state: state, throwValue: value, for: .human)

        if legalMoves.isEmpty {
            applyForfeit(throwValue: value)
        }
    }

    func handleTap(square: Int) {
        guard state.status == .inProgress else { return }
        guard state.currentPlayer == .human else { return }
        guard let throwValue = currentThrow else { return }

        if let selected = selectedPieceID {
            if let move = legalMoves.first(where: { $0.pieceID == selected && $0.to == square }) {
                applyMove(move: move, throwValue: throwValue)
            }
        } else if let piece = pieceAt(square: square), piece.owner == .human {
            if legalMoves.contains(where: { $0.pieceID == piece.id }) {
                selectedPieceID = piece.id
            }
        }
    }

    private func applyMove(move: Move, throwValue: Int) {
        pushUndoSnapshot()
        let result = SenetRules.reduce(state: state, action: .applyThrow(value: throwValue, pieceID: move.pieceID))
        state = result.0
        handleEvents(result.1)
        clearSelection()

        if state.currentPlayer == .computer && state.status == .inProgress {
            scheduleComputerTurn()
        }
    }

    private func applyForfeit(throwValue: Int) {
        pushUndoSnapshot()
        let result = SenetRules.reduce(state: state, action: .forfeitTurn(value: throwValue))
        state = result.0
        handleEvents(result.1)
        clearSelection()

        if state.currentPlayer == .computer && state.status == .inProgress {
            scheduleComputerTurn()
        }
    }

    private func scheduleComputerTurn() {
        computerTurnToken += 1
        let token = computerTurnToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.computerTurnToken == token else { return }
            self.performComputerTurn()
        }
    }

    private func performComputerTurn() {
        guard state.currentPlayer == .computer else { return }
        guard state.status == .inProgress else { return }

        let throwValue = Int.random(in: 1...5)
        let moves = SenetRules.legalMoves(state: state, throwValue: throwValue, for: .computer)

        pushUndoSnapshot()

        if let move = moves.randomElement() {
            let result = SenetRules.reduce(state: state, action: .applyThrow(value: throwValue, pieceID: move.pieceID))
            state = result.0
            handleEvents(result.1)
        } else {
            let result = SenetRules.reduce(state: state, action: .forfeitTurn(value: throwValue))
            state = result.0
            handleEvents(result.1)
        }

        clearSelection()

        if state.currentPlayer == .computer && state.status == .inProgress {
            scheduleComputerTurn()
        }
    }

    private func clearSelection() {
        currentThrow = nil
        selectedPieceID = nil
        legalMoves = []
    }

    private func handleEvents(_ events: [Event]) {
        let movedSquare: Int? = events.compactMap { event in
            if case .pieceMoved(let move) = event {
                return move.to
            }
            return nil
        }.last

        if events.contains(where: { if case .swapCaptured = $0 { return true } else { return false } }),
           let target = movedSquare, (1...30).contains(target) {
            triggerCaptureFlash(at: target)
        }

        if events.contains(where: { if case .waterPenalty = $0 { return true } else { return false } }) {
            triggerWaterSweep()
        }
    }

    private func triggerCaptureFlash(at square: Int) {
        captureFlashSquare = square
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            if self.captureFlashSquare == square {
                self.captureFlashSquare = nil
            }
        }
    }

    private func triggerWaterSweep() {
        let token = UUID()
        waterSweepToken = token
        isWaterSweepActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self, self.waterSweepToken == token else { return }
            self.isWaterSweepActive = false
            self.waterSweepToken = nil
        }
    }

    private func pushUndoSnapshot() {
        let snapshot = UndoSnapshot(
            state: state,
            currentThrow: currentThrow,
            selectedPieceID: selectedPieceID,
            legalMoves: legalMoves
        )
        undoStack.append(snapshot)
    }

    private func restore(_ snapshot: UndoSnapshot) {
        state = snapshot.state
        currentThrow = snapshot.currentThrow
        selectedPieceID = snapshot.selectedPieceID
        legalMoves = snapshot.legalMoves
        computerTurnToken += 1
    }

    private func pieceAt(square: Int) -> PieceState? {
        state.pieces.first(where: { $0.position == square })
    }
}

struct SetupView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Color.green
                    .frame(height: 12)

                Text("SENET TITLE DEBUG")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.red)
                    .padding(.top, 12)

                Text("SUBTITLE DEBUG")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.blue)

                Button("Start Game") {
                    viewModel.startGame()
                }
                .buttonStyle(SenetPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.yellow.opacity(0.2))
    }
}

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            if isLandscape {
                let insets = proxy.safeAreaInsets
                let safeSize = CGSize(
                    width: proxy.size.width - insets.leading - insets.trailing,
                    height: proxy.size.height - insets.top - insets.bottom
                )
                let boardSize = boardSize(in: safeSize)

                ZStack {
                    VStack(spacing: 16) {
                        BoardView(
                            state: viewModel.state,
                            selectedPieceID: viewModel.selectedPieceID,
                            legalDestinations: viewModel.visibleLegalDestinations,
                            movablePieceIDs: viewModel.movablePieceIDs,
                            captureFlashSquare: viewModel.captureFlashSquare,
                            waterSweepToken: viewModel.waterSweepToken,
                            isWaterSweepActive: viewModel.isWaterSweepActive,
                            humanColor: viewModel.humanColor,
                            computerColor: viewModel.computerColor,
                            onSquareTap: viewModel.handleTap
                        )
                        .frame(width: boardSize.width, height: boardSize.height)

                        GameControlsInlineView(viewModel: viewModel)

                        if case .won(let winner) = viewModel.state.status {
                            Text(winner == .human ? "You win." : "Computer wins.")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundColor(SenetTheme.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    VStack(spacing: 0) {
                        GameHeaderView(viewModel: viewModel)
                        Spacer()
                    }
                }
                .frame(width: safeSize.width, height: safeSize.height)
                // Center horizontally in the full screen while still respecting vertical safe area.
                // This avoids the layout looking left-shifted when the trailing inset is larger.
                .position(
                    x: proxy.size.width / 2,
                    y: insets.top + safeSize.height / 2
                )
            } else {
                let boardSize = boardSize(in: proxy.size)
                VStack(spacing: 16) {
                    GameHeaderView(viewModel: viewModel)

                    BoardView(
                        state: viewModel.state,
                        selectedPieceID: viewModel.selectedPieceID,
                        legalDestinations: viewModel.visibleLegalDestinations,
                        movablePieceIDs: viewModel.movablePieceIDs,
                        captureFlashSquare: viewModel.captureFlashSquare,
                        waterSweepToken: viewModel.waterSweepToken,
                        isWaterSweepActive: viewModel.isWaterSweepActive,
                        humanColor: viewModel.humanColor,
                        computerColor: viewModel.computerColor,
                        onSquareTap: viewModel.handleTap
                    )
                    .padding(.horizontal, 8)

                    GameControlsInlineView(viewModel: viewModel)

                    if case .won(let winner) = viewModel.state.status {
                        Text(winner == .human ? "You win." : "Computer wins.")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(SenetTheme.ink)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
    }

    private func boardSize(in size: CGSize) -> CGSize {
        let maxBoardWidth = size.width * 0.72
        let maxBoardWidthByHeight = size.height * 0.88 * (10.0 / 3.0)
        let boardWidth = min(maxBoardWidth, maxBoardWidthByHeight)
        return CGSize(width: boardWidth, height: boardWidth * 3.0 / 10.0)
    }
}

struct GameHeaderView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.state.currentPlayer == .human ? viewModel.playerName : "Computer")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
                Text(viewModel.state.currentPlayer == .human ? "Your turn" : "Opponent turn")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(SenetTheme.mutedInk)
            }

            Spacer()

            Button("New Game") {
                viewModel.resetToSetup()
            }
            .buttonStyle(SenetSecondaryButtonStyle())
        }
    }
}

struct GameControlsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GameHeaderView(viewModel: viewModel)

            if viewModel.state.currentPlayer == .human {
                Button("Throw") {
                    viewModel.throwSticks()
                }
                .buttonStyle(SenetPrimaryButtonStyle())
                .disabled(viewModel.currentThrow != nil)
            } else {
                Text("Computer thinking...")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(SenetTheme.mutedInk)
            }

            Button("Undo") {
                viewModel.undoLastMove()
            }
            .buttonStyle(SenetSecondaryButtonStyle())
            .disabled(viewModel.undoStack.isEmpty)

            if let currentThrow = viewModel.currentThrow {
                Text("Throw \(currentThrow)")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SenetTheme.cardFill)
                    )
                    .overlay(
                        Capsule()
                            .stroke(SenetTheme.cardStroke, lineWidth: 1)
                    )
            }

            if case .won(let winner) = viewModel.state.status {
                Text(winner == .human ? "You win." : "Computer wins.")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
            }

            Spacer()
        }
        .padding(16)
        .background(
            SenetCardBackground(cornerRadius: 18, showsOrnaments: false, shadowRadius: 16, shadowY: 6)
        )
    }
}

struct GameControlsInlineView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 16) {
            if viewModel.state.currentPlayer == .human {
                Button("Throw") {
                    viewModel.throwSticks()
                }
                .buttonStyle(SenetPrimaryButtonStyle())
                .disabled(viewModel.currentThrow != nil)
            } else {
                Text("Computer thinking...")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(SenetTheme.mutedInk)
            }

            Button("Undo") {
                viewModel.undoLastMove()
            }
            .buttonStyle(SenetSecondaryButtonStyle())
            .disabled(viewModel.undoStack.isEmpty)

            if let currentThrow = viewModel.currentThrow {
                Text("Throw \(currentThrow)")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(SenetTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SenetTheme.cardFill)
                    )
                    .overlay(
                        Capsule()
                            .stroke(SenetTheme.cardStroke, lineWidth: 1)
                    )
            }
        }
        .padding(14)
        .background(
            SenetCardBackground(cornerRadius: 16, showsOrnaments: false, shadowRadius: 14, shadowY: 6)
        )
    }
}

struct BoardView: View {
    let state: GameState
    let selectedPieceID: PieceID?
    let legalDestinations: Set<Int>
    let movablePieceIDs: Set<PieceID>
    let captureFlashSquare: Int?
    let waterSweepToken: UUID?
    let isWaterSweepActive: Bool
    let humanColor: Color
    let computerColor: Color
    let onSquareTap: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 10)

    private var displaySquares: [Int] {
        let top = Array(1...10)
        let middle = Array((11...20).reversed())
        let bottom = Array(21...30)
        return top + middle + bottom
    }

    var body: some View {
        ZStack {
            MetalBoardView(
                selectedSquare: selectedSquare,
                legalDestinations: legalDestinations
            )
            .allowsHitTesting(false)

            BoardFrameOverlay()
                .allowsHitTesting(false)

            if isWaterSweepActive, let waterSweepToken {
                WaterPenaltySweepOverlay()
                    .id(waterSweepToken)
                    .allowsHitTesting(false)
            }

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(displaySquares, id: \.self) { square in
                    SquareView(
                        square: square,
                        piece: pieceAt(square: square),
                        isSelected: isSelected(square: square),
                        isLegalDestination: legalDestinations.contains(square),
                        isMovable: isMovable(square: square),
                        captureFlashSquare: captureFlashSquare,
                        humanColor: humanColor,
                        computerColor: computerColor
                    )
                    .onTapGesture {
                        onSquareTap(square)
                    }
                }
            }
        }
        .aspectRatio(10.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SenetTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
    }

    private func pieceAt(square: Int) -> PieceState? {
        state.pieces.first(where: { $0.position == square })
    }

    private var selectedSquare: Int? {
        guard let selectedPieceID else { return nil }
        return state.pieces.first(where: { $0.id == selectedPieceID })?.position
    }

    private func isSelected(square: Int) -> Bool {
        guard let selectedPieceID else { return false }
        return state.pieces.first(where: { $0.id == selectedPieceID })?.position == square
    }

    private func isMovable(square: Int) -> Bool {
        guard let piece = pieceAt(square: square) else { return false }
        return movablePieceIDs.contains(piece.id)
    }
}

struct SquareView: View {
    let square: Int
    let piece: PieceState?
    let isSelected: Bool
    let isLegalDestination: Bool
    let isMovable: Bool
    let captureFlashSquare: Int?
    let humanColor: Color
    let computerColor: Color

    var body: some View {
        ZStack {
            Color.clear

            if let glyphName = specialGlyphName(for: square) {
                Image(glyphName)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.28)
                    .padding(14)
            }

            if isMovable && !isSelected {
                Circle()
                    .strokeBorder(SenetTheme.mutedInk.opacity(0.45), lineWidth: 2)
                    .padding(10)
            }

            if isSelected {
                Image("selection-ring")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            }

            if isLegalDestination {
                Image("legal-move-marker")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
            }

            if let piece {
                Image(piece.owner == .human ? "player-token-a" : "player-token-b")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            }

            if captureFlashSquare == square {
                Image("capture-swap-flash")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.7)
                    .padding(6)
            }

            Text("\(square)")
                .font(.caption2)
                .foregroundColor(SenetTheme.mutedInk.opacity(0.7))
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func specialGlyphName(for square: Int) -> String? {
        switch square {
        case SenetRules.rebirthSquare:
            return "special-glyph-01"
        case SenetRules.gateSquare:
            return "special-glyph-02"
        case SenetRules.waterSquare:
            return "special-glyph-03"
        case 28:
            return "special-glyph-04"
        case 29:
            return "special-glyph-05"
        default:
            return nil
        }
    }
}

struct BoardFrameOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let stripHeight = max(10, size.height * 0.08)
            let cornerSize = stripHeight * 2.1

            let strip = Image("chevron-border-strip")
                .resizable(resizingMode: .tile)

            ZStack {
                strip
                    .frame(width: size.width, height: stripHeight)
                    .position(x: size.width / 2, y: stripHeight / 2)

                strip
                    .frame(width: size.width, height: stripHeight)
                    .rotationEffect(.degrees(180))
                    .position(x: size.width / 2, y: size.height - stripHeight / 2)

                strip
                    .frame(width: size.height, height: stripHeight)
                    .rotationEffect(.degrees(90))
                    .position(x: stripHeight / 2, y: size.height / 2)

                strip
                    .frame(width: size.height, height: stripHeight)
                    .rotationEffect(.degrees(-90))
                    .position(x: size.width - stripHeight / 2, y: size.height / 2)

                Image("corner-ornament")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cornerSize, height: cornerSize)
                    .opacity(0.65)
                    .position(x: cornerSize * 0.45, y: cornerSize * 0.45)

                Image("corner-ornament")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cornerSize, height: cornerSize)
                    .rotationEffect(.degrees(90))
                    .opacity(0.65)
                    .position(x: size.width - cornerSize * 0.45, y: cornerSize * 0.45)

                Image("corner-ornament")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cornerSize, height: cornerSize)
                    .rotationEffect(.degrees(180))
                    .opacity(0.65)
                    .position(x: size.width - cornerSize * 0.45, y: size.height - cornerSize * 0.45)

                Image("corner-ornament")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cornerSize, height: cornerSize)
                    .rotationEffect(.degrees(270))
                    .opacity(0.65)
                    .position(x: cornerSize * 0.45, y: size.height - cornerSize * 0.45)
            }
        }
    }
}

struct WaterPenaltySweepOverlay: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let bandHeight = max(24, size.height * 0.35)

            Image("water-penalty-sweep")
                .resizable()
                .scaledToFill()
                .frame(width: size.width * 1.3, height: bandHeight)
                .opacity(0.55)
                .offset(x: animate ? size.width * 0.65 : -size.width * 0.65,
                        y: (size.height - bandHeight) * 0.5)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        animate = true
                    }
                }
        }
    }
}

#if DEBUG
#Preview {
    RootView()
}
#endif

struct SenetBackdropView: View {
    var body: some View {
        ZStack {
            SenetTheme.background

            Image("board-surface-texture")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .blendMode(.multiply)

            Image("ambient-dust-overlay")
                .resizable()
                .scaledToFill()
                .opacity(0.22)
                .blendMode(.softLight)

            Image("subtle-vignette")
                .resizable()
                .scaledToFill()
                .opacity(0.45)
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

struct SenetCardBackground: View {
    var cornerRadius: CGFloat = 20
    var showsOrnaments: Bool = false
    var shadowRadius: CGFloat = 18
    var shadowY: CGFloat = 8

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(SenetTheme.cardFill)

            Image("board-surface-texture")
                .resizable()
                .scaledToFill()
                .opacity(0.2)
                .blendMode(.multiply)

            Image("ambient-dust-overlay")
                .resizable()
                .scaledToFill()
                .opacity(0.2)
                .blendMode(.softLight)

            Image("subtle-vignette")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .blendMode(.multiply)

            if showsOrnaments {
                ornamentLayer
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(SenetTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: shadowRadius, x: 0, y: shadowY)
    }

    private var ornamentLayer: some View {
        ZStack {
            ornament(alignment: .topLeading, rotation: 0)
            ornament(alignment: .topTrailing, rotation: 90)
            ornament(alignment: .bottomTrailing, rotation: 180)
            ornament(alignment: .bottomLeading, rotation: 270)
        }
        .padding(10)
        .opacity(0.25)
    }

    private func ornament(alignment: Alignment, rotation: Double) -> some View {
        Image("corner-ornament")
            .resizable()
            .scaledToFit()
            .frame(width: 26, height: 26)
            .rotationEffect(.degrees(rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

enum SenetTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.97, green: 0.94, blue: 0.87),
            Color(red: 0.88, green: 0.82, blue: 0.70)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardFill = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let cardStroke = Color(red: 0.76, green: 0.68, blue: 0.56).opacity(0.6)
    static let accent = Color(red: 0.88, green: 0.76, blue: 0.52)
    static let accentBorder = Color(red: 0.78, green: 0.58, blue: 0.24)
    static let ink = Color(red: 0.20, green: 0.18, blue: 0.16)
    static let mutedInk = Color(red: 0.38, green: 0.34, blue: 0.30)
}

struct SenetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .foregroundColor(SenetTheme.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SenetTheme.accent)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SenetTheme.cardStroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SenetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .serif))
            .foregroundColor(SenetTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SenetTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(SenetTheme.cardStroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
