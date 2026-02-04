# Codex CLI Prompt — Senet
## Mechanics + SwiftUI + Metal Material Board (No Mythology)

You are in an empty folder. Create a production-grade iOS Senet app focused on **core mechanics with a premium material board rendered using Metal**.

Constraints:
- No mythology.
- No narrative text.
- No historical flavor.
- No characters.

Visuals must be clean, neutral, and **material-focused only**.

The product goal is a **fully playable, deterministic Senet game** with:
- a **Metal-rendered board surface** (material, not an image)
- **SwiftUI-driven interaction, pieces, and HUD**
- a **pure, testable rules engine**

---

## Goals

- Fully playable Senet game (human vs computer on one device)
- Correct rules and turn flow
- Deterministic, testable rules engine
- SwiftUI UI with legal-move highlighting and basic animations
- Metal used **only** to render the board surface as a material (parchment + grid + highlights)
- No mythology, symbolism, or narrative framing
- Target iOS 26.1

---

## Non-negotiable architecture

- Create a pure Swift rules engine as a Swift Package named **SenetRules** inside the repo.
- The rules engine must **not** import SwiftUI, UIKit, Metal, or any rendering frameworks.
- The rules engine must be deterministic and replayable.
- Randomness is **not** inside the engine. The throw result (1–5) is injected as part of the Action.
- Reducer signature must be:

  ```swift
  reduce(state: GameState, action: Action) -> (GameState, [Event])
  ```

- UI must be SwiftUI and must follow strict one-way data flow:

  ```text
  SwiftUI → Action → Reducer → New State + Events → SwiftUI render + animations
  ```

- The UI must not duplicate rule logic. Legal moves come from the engine (or an engine helper) only.
- Metal must be **isolated to board rendering** and must not know about game rules, turns, or legality.

---

## Game mechanics to implement (authoritative ruleset)

Use this ruleset exactly and consistently across engine, UI, and tests.

### Components

- Board of 30 squares arranged in **3 rows of 10**
- Two players
- Five pieces per player
- Movement determined by a value from **1–5** (representing casting sticks)

### Board layout and movement path

- Squares 1–10: top row, left to right
- Squares 11–20: middle row, right to left
- Squares 21–30: bottom row, left to right

All pieces move forward along this serpentine path only. Backward movement occurs only when forced by special squares.

### Setup

- All ten pieces start on squares 1–10 in alternating order
- No two adjacent squares may contain pieces from the same player
- The player whose piece occupies square 1 goes first
- The human player always starts and always occupies square 1 (AI occupies square 2)

### Turn structure

- A turn consists of one injected throw value (1–5) and one move using exactly that value.
- Only one piece may be moved per turn.
- If no legal move exists, the turn is forfeited.
- Extra turn rule: rolls of 1, 4, or 5 grant an extra turn; rolls of 2 or 3 do not.
- If a move results in a water penalty (square 27), the extra-turn rule still applies based on the original throw, after resolving the penalty movement.

### Legal movement

- Pieces must move forward exactly the throw value.
- A piece may not land on a square occupied by its own piece.
- Pieces may pass over other pieces unless blocked by a blockade.

### Capturing and swapping

- Landing on an opponent’s piece causes a **swap**.
- The moving piece occupies the destination square.
- The opponent’s piece moves to the origin square.

### Protected pieces

- A piece is protected if it has a friendly piece immediately before or after it along the path.
- Adjacency is along the serpentine path, including row transitions.
- Protected pieces cannot be captured or swapped onto.

### Blockades

- A blockade exists when two friendly pieces occupy two consecutive squares.
- Adjacency is along the serpentine path, including row transitions.
- Opponents may not jump over a blockade.
- A player may jump over their own blockade.

### Special squares

- Square 15 (Rebirth): A piece moved here (by normal movement or water penalty) is safe and remains in place until moved by a future legal throw.
- Square 26 (Gate square): A piece must land on square 26 exactly at least once before that piece may move to any square greater than 26 or off the board. Until a piece has visited square 26, any move that would take that piece beyond 26 is illegal.
- Square 27 (Water penalty): When a piece lands on square 27, it is moved immediately to square 15. If square 15 is occupied, the piece is moved backward from 15 to the nearest empty square along the path. Square 27 is safe only in the sense it cannot be landed on if occupied, but it never remains occupied after resolution.
- Squares 28–30: final squares.

### Bearing off

Pieces may exit only with an exact roll:

| Square | Exact roll to bear off |
| --- | --- |
| 28 | 3 |
| 29 | 2 |
| 30 | 1 |

Any move that would go past 30 is illegal unless it is the exact bearing-off roll.

### Safe squares

Safe squares are 15, 26, 27, 28, and 29. Square 30 is not safe. A piece on a safe square cannot be captured or swapped; an opponent’s piece may not land on an occupied safe square, but may pass over it if not otherwise blocked.

### Winning condition

- The game ends immediately when a player has borne off all five pieces.

---

## UI requirements (SwiftUI)

- Board layout is 3×10 with hit-testing aligned exactly to engine coordinates.
- Pieces are SwiftUI views (shapes or images), two colors.
- Player setup screen where the user enters a name and chooses a color.
- Tap to select a piece.
- Highlight legal destination squares.
- Tap destination to move.
- “Throw” button generates a random value in the UI layer and injects it into the engine.
- Display current player and last throw.
- Basic animations for movement and swapping.
- “Undo last move” implemented via GameState snapshot stack (no partial undo).
- “New Game” button.

---

## Metal board renderer requirements

- Implement **MetalBoardView** using `MTKView` wrapped with `UIViewRepresentable`.
- Metal renders **only** the board surface as a material.
- Required material features:
  - parchment base
  - subtle grain/noise
  - crisp procedural 3×10 grid lines
  - integrated square highlights (selection + legal moves)
  - optional vignette
- Render a single quad covering the board area.
- Pieces, markers, and HUD remain SwiftUI overlays.
- Metal receives a **small render-state struct only**: board size, selected square index, legal-move mask (30 elements), animation time.
- No game logic, rule checks, or turn handling inside Metal.
- App must compile and run with Metal enabled by default.

---

## Testing requirements (SenetRulesTests)

- Unit tests for:
  - pathing
  - legal move generation
  - swap capture
  - protected piece prevention
  - blockade prevention
  - special square behavior
  - extra turn logic
  - exact bearing off
  - win detection
- Deterministic replay test: inject a fixed sequence of throws and actions, then assert the final `GameState`.

---

## Deliverables

- Full folder structure
- Swift Package **SenetRules**
- iOS app target **SenetApp**
- Metal shader file(s)
- README explaining ruleset assumptions and architecture
- Run `xcodebuild test` at the end and fix compilation errors

---

## Build order

1. Scaffold Xcode project
2. Create SenetRules package
3. Implement rules engine + tests
4. Build SwiftUI UI with placeholder board
5. Integrate MetalBoardView
6. Wire render-state from ViewModel to Metal
7. Final test + build

---

## Asset reference (CORE mechanics visuals only)

The following assets already exist under `output/imagegen/`.

Do **not** generate them. Do **not** encode rules into them. They are **presentation-only** and must be removable without breaking gameplay.

- `output/imagegen/board-surface-texture.png`: Primary parchment material sampled by Metal.
- `output/imagegen/grid-line-ink-texture.png`: Optional ink texture for procedural grid lines.
- `output/imagegen/chevron-border-strip.png`: Optional decorative border.
- `output/imagegen/corner-ornament.png`: Optional corner decoration.
- `output/imagegen/player-token-a.png`: Player one piece asset.
- `output/imagegen/player-token-b.png`: Player two piece asset.
- `output/imagegen/selection-ring.png`: Selection indicator.
- `output/imagegen/legal-move-marker.png`: Legal destination marker.
- `output/imagegen/capture-swap-flash.png`: Swap capture visual feedback.
- `output/imagegen/water-penalty-sweep.png`: Water penalty overlay.
- `output/imagegen/subtle-vignette.png`: Board vignette.
- `output/imagegen/ambient-dust-overlay.png`: Subtle dust/grain overlay.
- `output/imagegen/special-glyph-01.png`: Optional glyph for marking special squares visually.
- `output/imagegen/special-glyph-02.png`: Optional glyph for marking special squares visually.
- `output/imagegen/special-glyph-03.png`: Optional glyph for marking special squares visually.
- `output/imagegen/special-glyph-04.png`: Optional glyph for marking special squares visually.
- `output/imagegen/special-glyph-05.png`: Optional glyph for marking special squares visually.

Square behavior must be defined **only** in the rules engine.

All assets are optional. The game must remain fully correct and playable with all assets removed.

---

End of prompt.
