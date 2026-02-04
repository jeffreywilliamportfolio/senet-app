import Foundation

public enum PlayerID: Int, CaseIterable, Codable, Hashable {
    case human = 0
    case computer = 1

    public var opponent: PlayerID {
        switch self {
        case .human: return .computer
        case .computer: return .human
        }
    }
}

public enum GameStatus: Equatable, Codable {
    case inProgress
    case won(PlayerID)
}

public struct PieceID: Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct PieceState: Equatable, Codable {
    public let id: PieceID
    public let owner: PlayerID
    public var position: Int?
    public var hasVisitedGate: Bool

    public init(id: PieceID, owner: PlayerID, position: Int?, hasVisitedGate: Bool) {
        self.id = id
        self.owner = owner
        self.position = position
        self.hasVisitedGate = hasVisitedGate
    }
}

public struct GameState: Equatable, Codable {
    public var currentPlayer: PlayerID
    public var lastThrow: Int?
    public var pieces: [PieceState]
    public var status: GameStatus

    public init(currentPlayer: PlayerID, lastThrow: Int?, pieces: [PieceState], status: GameStatus) {
        self.currentPlayer = currentPlayer
        self.lastThrow = lastThrow
        self.pieces = pieces
        self.status = status
    }
}

public struct Move: Equatable, Codable {
    public let pieceID: PieceID
    public let from: Int
    public let to: Int

    public init(pieceID: PieceID, from: Int, to: Int) {
        self.pieceID = pieceID
        self.from = from
        self.to = to
    }
}

public enum Action: Equatable, Codable {
    case newGame
    case applyThrow(value: Int, pieceID: PieceID)
    case forfeitTurn(value: Int)
}

public enum Event: Equatable, Codable {
    case turnStarted(player: PlayerID, throwValue: Int)
    case pieceMoved(Move)
    case swapCaptured(attacker: PieceID, defender: PieceID)
    case waterPenalty(pieceID: PieceID, from: Int, to: Int)
    case extraTurnGranted(player: PlayerID)
    case turnPassed(player: PlayerID)
    case gameWon(player: PlayerID)
}
