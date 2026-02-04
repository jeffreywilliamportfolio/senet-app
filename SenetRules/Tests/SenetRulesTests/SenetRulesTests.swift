import Testing
@testable import SenetRules

private func makePiece(_ id: Int, owner: PlayerID, position: Int, visitedGate: Bool = false) -> PieceState {
    PieceState(id: PieceID(id), owner: owner, position: position, hasVisitedGate: visitedGate)
}

private func makeState(pieces: [PieceState], currentPlayer: PlayerID = .human) -> GameState {
    GameState(currentPlayer: currentPlayer, lastThrow: nil, pieces: pieces, status: .inProgress)
}

private func piece(at position: Int, in state: GameState) -> PieceState? {
    state.pieces.first(where: { $0.position == position })
}

private func piece(id: Int, in state: GameState) -> PieceState? {
    state.pieces.first(where: { $0.id == PieceID(id) })
}

@Test func newGameSetupPlacesHumanOnSquareOne() {
    let state = SenetRules.newGame()
    #expect(state.currentPlayer == .human)
    #expect(state.pieces.count == 10)
    #expect(piece(at: 1, in: state)?.owner == .human)
    #expect(piece(at: 2, in: state)?.owner == .computer)
}

@Test func legalMovesBlockLandingOnOwnPiece() {
    let state = SenetRules.newGame()
    let moves = SenetRules.legalMoves(state: state, throwValue: 2, for: .human)
    let blocked = moves.contains(where: { $0.from == 1 && $0.to == 3 })
    #expect(!blocked)
}

@Test func swapCaptureMovesPieces() {
    let pieces = [
        makePiece(0, owner: .human, position: 1),
        makePiece(100, owner: .computer, position: 3)
    ]
    let state = makeState(pieces: pieces)
    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 2, pieceID: PieceID(0)))
    let next = result.0

    #expect(piece(id: 0, in: next)?.position == 3)
    #expect(piece(id: 100, in: next)?.position == 1)
}

@Test func protectedPieceCannotBeCaptured() {
    let pieces = [
        makePiece(0, owner: .human, position: 3),
        makePiece(100, owner: .computer, position: 5),
        makePiece(101, owner: .computer, position: 6)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 2, for: .human)
    let illegal = moves.contains(where: { $0.from == 3 && $0.to == 5 })
    #expect(!illegal)
}

@Test func blockadePreventsPassing() {
    let pieces = [
        makePiece(0, owner: .human, position: 1),
        makePiece(100, owner: .computer, position: 3),
        makePiece(101, owner: .computer, position: 4),
        makePiece(102, owner: .computer, position: 5)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 5, for: .human)
    let blocked = moves.contains(where: { $0.from == 1 && $0.to == 6 })
    #expect(!blocked)
}

@Test func ownBlockadeDoesNotPreventPassing() {
    let pieces = [
        makePiece(0, owner: .human, position: 1),
        makePiece(1, owner: .human, position: 3),
        makePiece(2, owner: .human, position: 4),
        makePiece(3, owner: .human, position: 5),
        makePiece(100, owner: .computer, position: 10)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 5, for: .human)
    let allowed = moves.contains(where: { $0.from == 1 && $0.to == 6 })
    #expect(allowed)
}

@Test func safeSquareBlocksCapture() {
    let pieces = [
        makePiece(0, owner: .human, position: 13),
        makePiece(100, owner: .computer, position: 15)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 2, for: .human)
    let illegal = moves.contains(where: { $0.from == 13 && $0.to == 15 })
    #expect(!illegal)
}

@Test func pathingMovesForwardAlongSerpentine() {
    let pieces = [
        makePiece(0, owner: .human, position: 10),
        makePiece(100, owner: .computer, position: 30)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 1, for: .human)
    #expect(moves.contains(where: { $0.from == 10 && $0.to == 11 }))
}

@Test func gatePreventsPassingBeyond26UntilVisited() {
    let pieces = [
        makePiece(0, owner: .human, position: 25, visitedGate: false),
        makePiece(100, owner: .computer, position: 10)
    ]
    let state = makeState(pieces: pieces)
    let moves = SenetRules.legalMoves(state: state, throwValue: 2, for: .human)
    #expect(!moves.contains(where: { $0.from == 25 && $0.to == 27 }))

    var visited = state
    if let index = visited.pieces.firstIndex(where: { $0.id == PieceID(0) }) {
        visited.pieces[index].hasVisitedGate = true
    }
    let allowed = SenetRules.legalMoves(state: visited, throwValue: 2, for: .human)
    #expect(allowed.contains(where: { $0.from == 25 && $0.to == 27 }))
}

@Test func waterPenaltyMovesToRebirth() {
    let pieces = [
        makePiece(0, owner: .human, position: 26, visitedGate: true),
        makePiece(100, owner: .computer, position: 2)
    ]
    let state = makeState(pieces: pieces)
    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 1, pieceID: PieceID(0)))
    let next = result.0
    #expect(piece(id: 0, in: next)?.position == 15)
}

@Test func waterPenaltyBacktracksToNearestEmpty() {
    let pieces = [
        makePiece(0, owner: .human, position: 26, visitedGate: true),
        makePiece(1, owner: .computer, position: 15),
        makePiece(100, owner: .computer, position: 2)
    ]
    let state = makeState(pieces: pieces)
    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 1, pieceID: PieceID(0)))
    let next = result.0
    #expect(piece(id: 0, in: next)?.position == 14)
}

@Test func exactBearingOffIsRequired() {
    let pieces = [
        makePiece(0, owner: .human, position: 28, visitedGate: true),
        makePiece(1, owner: .human, position: 1),
        makePiece(100, owner: .computer, position: 2)
    ]
    let state = makeState(pieces: pieces)
    let legal = SenetRules.legalMoves(state: state, throwValue: 3, for: .human)
    #expect(legal.contains(where: { $0.from == 28 && $0.to == SenetRules.offboardSquare }))

    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 3, pieceID: PieceID(0)))
    #expect(piece(id: 0, in: result.0)?.position == nil)

    let legalTo30 = SenetRules.legalMoves(state: state, throwValue: 2, for: .human)
    #expect(legalTo30.contains(where: { $0.from == 28 && $0.to == 30 }))

    let overshootPieces = [
        makePiece(0, owner: .human, position: 29, visitedGate: true),
        makePiece(1, owner: .human, position: 1),
        makePiece(100, owner: .computer, position: 2)
    ]
    let overshootState = makeState(pieces: overshootPieces)
    let illegal = SenetRules.legalMoves(state: overshootState, throwValue: 3, for: .human)
    #expect(!illegal.contains(where: { $0.from == 29 }))
}

@Test func bearingOffLastPieceWinsGame() {
    let pieces = [
        makePiece(0, owner: .human, position: 30, visitedGate: true),
        makePiece(100, owner: .computer, position: 1)
    ]
    let state = makeState(pieces: pieces)
    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 1, pieceID: PieceID(0)))
    #expect(result.0.status == .won(.human))
}

@Test func extraTurnRulesApply() {
    let pieces = [
        makePiece(0, owner: .human, position: 1),
        makePiece(100, owner: .computer, position: 10)
    ]
    let state = makeState(pieces: pieces)
    let result = SenetRules.reduce(state: state, action: .applyThrow(value: 4, pieceID: PieceID(0)))
    #expect(result.0.currentPlayer == .human)

    let state2 = makeState(pieces: pieces)
    let result2 = SenetRules.reduce(state: state2, action: .applyThrow(value: 2, pieceID: PieceID(0)))
    #expect(result2.0.currentPlayer == .computer)
}

@Test func deterministicReplaySequence() {
    var state = SenetRules.newGame()
    state = SenetRules.reduce(state: state, action: .applyThrow(value: 1, pieceID: PieceID(0))).0
    state = SenetRules.reduce(state: state, action: .applyThrow(value: 2, pieceID: PieceID(0))).0
    state = SenetRules.reduce(state: state, action: .applyThrow(value: 3, pieceID: PieceID(102))).0

    #expect(piece(id: 0, in: state)?.position == 4)
    #expect(piece(id: 100, in: state)?.position == 1)
    #expect(piece(id: 101, in: state)?.position == 2)
    #expect(piece(id: 102, in: state)?.position == 9)
    #expect(piece(id: 4, in: state)?.position == 6)
}
