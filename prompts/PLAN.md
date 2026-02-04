# Plan

We’re building the Senet iOS app specified in `prompts/senet_prompt.md`, with a deterministic `SenetRules` engine, SwiftUI UI, and a Metal-rendered board material. The first playable version is user vs computer only, with a player setup screen (name + color) and the human always starting on square 1.

## Scope
- In: Deterministic rules engine, SwiftUI UI with legal-move highlights and undo, Metal board material renderer, player setup (name + color), user vs computer flow, full rules test suite, optional asset integration.
- Out: Mythology/narrative, human vs human mode, online multiplayer, non-iOS platforms, rules beyond the specified ruleset.

## Action items
[x] Scaffold the Xcode project with a `SenetApp` target and a `SenetRules` Swift Package.
[x] Set the iOS deployment target to 26.1 in the Xcode project.
[x] Create the `AppIcon` asset catalog from a provided 1024×1024 source image (no imagegen).
[x] Define core engine models (`GameState`, `Action`, `Event`, serpentine path mapping) and initial setup that places the human player’s piece on square 1 with alternating pieces.
[x] Implement legal move generation and constraints (serpentine adjacency, two-piece blockades, protected pieces, safe squares, gate 26, water 27 → 15 fallback, exact bearing off and overshoot illegality).
[x] Implement state transitions for swap captures, water penalty resolution, exact bearing off, and extra-turn logic.
[x] Add a player setup screen for name + color selection and wire it to the game view model and piece rendering.
[x] Implement a simple computer opponent turn flow (automated throw, random throw values, random legal move selection) with injected throws outside the rules engine.
[x] Build SwiftUI board/pieces UI with selection, legal-move highlights, throw button, and HUD for the human turn.
[x] Add undo stack for the human turn (snapshot-based).
[x] Implement `MetalBoardView` material shader and pass minimal render-state from the view model.
[x] Add unit tests for pathing, legality, protection, blockades, special squares, extra turns, bearing off, win detection, and deterministic replay including the square-1 start rule.
[ ] Run `xcodebuild test` and fix any build/test failures.

## Open questions
- None. Decisions: automated throw; random throws.
