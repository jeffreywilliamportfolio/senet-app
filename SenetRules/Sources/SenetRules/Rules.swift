import Foundation

public enum SenetRules {
    public static let boardSize = 30
    public static let gateSquare = 26
    public static let waterSquare = 27
    public static let rebirthSquare = 15
    public static let offboardSquare = 31
    public static let safeSquares: Set<Int> = [15, 26, 27, 28, 29]

    public static func newGame() -> GameState {
        var pieces: [PieceState] = []
        pieces.reserveCapacity(10)

        // Human starts on square 1, AI on square 2, then alternate across 1–10.
        var nextHumanID = 0
        var nextComputerID = 0
        for square in 1...10 {
            let owner: PlayerID = (square % 2 == 1) ? .human : .computer
            let pieceID: PieceID
            if owner == .human {
                pieceID = PieceID(nextHumanID)
                nextHumanID += 1
            } else {
                pieceID = PieceID(100 + nextComputerID)
                nextComputerID += 1
            }
            pieces.append(PieceState(id: pieceID, owner: owner, position: square, hasVisitedGate: false))
        }

        return GameState(currentPlayer: .human, lastThrow: nil, pieces: pieces, status: .inProgress)
    }

    public static func reduce(state: GameState, action: Action) -> (GameState, [Event]) {
        switch action {
        case .newGame:
            return (newGame(), [])
        case .applyThrow(let value, let pieceID):
            return applyThrow(state: state, value: value, pieceID: pieceID)
        case .forfeitTurn(let value):
            return forfeitTurn(state: state, value: value)
        }
    }

    public static func legalMoves(state: GameState, throwValue: Int, for player: PlayerID) -> [Move] {
        guard (1...5).contains(throwValue) else { return [] }
        guard state.status == .inProgress else { return [] }

        var moves: [Move] = []
        let opponent = player.opponent

        for piece in state.pieces where piece.owner == player {
            guard let from = piece.position else { continue }

            let target = from + throwValue

            // Gate rule: must land on 26 before moving beyond it or offboard.
            if !piece.hasVisitedGate && target > gateSquare { continue }

            if target > boardSize {
                if isExactBearOff(from: from, throwValue: throwValue) {
                    if isBlockedByOpponentBlockade(state: state, mover: player, from: from, to: boardSize) { continue }
                    moves.append(Move(pieceID: piece.id, from: from, to: offboardSquare))
                }
                continue
            }

            if isBlockedByOpponentBlockade(state: state, mover: player, from: from, to: target) { continue }
            if isOccupied(by: player, at: target, in: state) { continue }

            if let opponentPiece = pieceAt(position: target, in: state), opponentPiece.owner == opponent {
                if safeSquares.contains(target) { continue }
                if isProtected(piece: opponentPiece, in: state) { continue }
            }

            moves.append(Move(pieceID: piece.id, from: from, to: target))
        }

        return moves
    }

    // MARK: - Helpers

    static func applyThrow(state: GameState, value: Int, pieceID: PieceID) -> (GameState, [Event]) {
        guard state.status == .inProgress else { return (state, []) }
        guard (1...5).contains(value) else { return (state, []) }

        var events: [Event] = []
        var next = state
        next.lastThrow = value
        events.append(.turnStarted(player: state.currentPlayer, throwValue: value))

        let legal = legalMoves(state: state, throwValue: value, for: state.currentPlayer)
        guard let move = legal.first(where: { $0.pieceID == pieceID }) else {
            return (next, events)
        }

        guard let movingIndex = indexOfPiece(id: pieceID, in: next) else { return (next, events) }

        // Resolve capture swap if needed.
        var swappedPieceID: PieceID?
        if let defender = pieceAt(position: move.to, in: next) {
            swappedPieceID = defender.id
            if let defenderIndex = indexOfPiece(id: defender.id, in: next) {
                next.pieces[defenderIndex].position = move.from
            }
        }

        // Apply move.
        if move.to == offboardSquare {
            next.pieces[movingIndex].position = nil
        } else {
            next.pieces[movingIndex].position = move.to
        }

        if move.to == gateSquare {
            next.pieces[movingIndex].hasVisitedGate = true
        }

        events.append(.pieceMoved(move))

        if let swapped = swappedPieceID {
            events.append(.swapCaptured(attacker: pieceID, defender: swapped))
        }

        // Water penalty resolution.
        if move.to == waterSquare {
            let resolved = resolveWaterPenalty(state: next, movingIndex: movingIndex)
            next = resolved.state
            events.append(.waterPenalty(pieceID: pieceID, from: waterSquare, to: resolved.finalPosition))
        }

        if let winner = checkWinner(state: next) {
            next.status = .won(winner)
            events.append(.gameWon(player: winner))
            return (next, events)
        }

        if grantsExtraTurn(throwValue: value) {
            events.append(.extraTurnGranted(player: next.currentPlayer))
        } else {
            next.currentPlayer = next.currentPlayer.opponent
        }

        return (next, events)
    }

    static func forfeitTurn(state: GameState, value: Int) -> (GameState, [Event]) {
        guard state.status == .inProgress else { return (state, []) }
        guard (1...5).contains(value) else { return (state, []) }

        var next = state
        next.lastThrow = value
        var events: [Event] = [.turnPassed(player: state.currentPlayer)]

        if grantsExtraTurn(throwValue: value) {
            events.append(.extraTurnGranted(player: state.currentPlayer))
        } else {
            next.currentPlayer = state.currentPlayer.opponent
        }

        return (next, events)
    }

    static func grantsExtraTurn(throwValue: Int) -> Bool {
        return throwValue == 1 || throwValue == 4 || throwValue == 5
    }

    static func isExactBearOff(from: Int, throwValue: Int) -> Bool {
        switch from {
        case 28: return throwValue == 3
        case 29: return throwValue == 2
        case 30: return throwValue == 1
        default: return false
        }
    }

    static func resolveWaterPenalty(state: GameState, movingIndex: Int) -> (state: GameState, finalPosition: Int) {
        var next = state

        if !isOccupied(at: rebirthSquare, in: next) {
            next.pieces[movingIndex].position = rebirthSquare
            return (next, rebirthSquare)
        }

        var candidate = rebirthSquare - 1
        while candidate >= 1 {
            if !isOccupied(at: candidate, in: next) {
                next.pieces[movingIndex].position = candidate
                return (next, candidate)
            }
            candidate -= 1
        }

        // Fallback: if all previous squares are filled (should not happen), keep on rebirth.
        next.pieces[movingIndex].position = rebirthSquare
        return (next, rebirthSquare)
    }

    static func checkWinner(state: GameState) -> PlayerID? {
        let humanRemaining = state.pieces.contains { $0.owner == .human && $0.position != nil }
        let computerRemaining = state.pieces.contains { $0.owner == .computer && $0.position != nil }

        if !humanRemaining { return .human }
        if !computerRemaining { return .computer }
        return nil
    }

    static func isProtected(piece: PieceState, in state: GameState) -> Bool {
        guard let position = piece.position else { return false }
        let neighbors = [position - 1, position + 1]
        for neighbor in neighbors {
            if let adjacent = pieceAt(position: neighbor, in: state), adjacent.owner == piece.owner {
                return true
            }
        }
        return false
    }

    static func isBlockedByOpponentBlockade(state: GameState, mover: PlayerID, from: Int, to: Int) -> Bool {
        let opponent = mover.opponent
        let opponentPositions = state.pieces.compactMap { piece -> Int? in
            guard piece.owner == opponent else { return nil }
            return piece.position
        }
        let positionSet = Set(opponentPositions)

        guard to > from else { return false }
        for square in (from + 1)...to {
            if positionSet.contains(square),
               positionSet.contains(square + 1),
               positionSet.contains(square + 2) {
                return true
            }
        }
        return false
    }

    static func isOccupied(at position: Int, in state: GameState) -> Bool {
        return pieceAt(position: position, in: state) != nil
    }

    static func isOccupied(by player: PlayerID, at position: Int, in state: GameState) -> Bool {
        guard let piece = pieceAt(position: position, in: state) else { return false }
        return piece.owner == player
    }

    static func pieceAt(position: Int, in state: GameState) -> PieceState? {
        return state.pieces.first(where: { $0.position == position })
    }

    static func indexOfPiece(id: PieceID, in state: GameState) -> Int? {
        return state.pieces.firstIndex(where: { $0.id == id })
    }
}
