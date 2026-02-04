---
name: apple-swift-swiftui-metal
description: Apple Swift, SwiftUI, and Metal development guidance using only official Apple Developer Documentation and API references. Use when tasks involve Swift language/APIs, SwiftUI UI composition, Metal GPU rendering/compute, or Apple platform API usage that must be grounded in Apple docs.
---

# Apple Swift SwiftUI Metal

## Overview
Provide Swift, SwiftUI, and Metal guidance grounded exclusively in Apple Developer Documentation and Apple-hosted API/spec references.

## Source Policy (strict)
- Use only Apple Developer Documentation and Apple-hosted API/spec references listed in `references/apple-developer-docs.md`.
- Do not use third-party blogs, forums, or non-Apple references. If the user requests external sources, ask for permission before proceeding.

## Workflow
1. Identify the domain: Swift language/API, SwiftUI UI, or Metal rendering/compute.
2. Confirm platform targets and OS versions (iOS, macOS, tvOS, watchOS, visionOS) because availability matters.
3. Open `references/apple-developer-docs.md` and navigate to the relevant Apple docs entry point.
4. Answer using the official API names, availability, and behavior described in the Apple docs.
5. If documentation is unclear or missing, say so explicitly and ask the user for more context.

## Output Expectations
- Prefer concise, API-accurate explanations with examples that reflect Apple’s documented patterns.
- When providing code, keep it minimal and aligned to Apple’s documented idioms (SwiftUI modifiers, Metal command encoding, etc.).

## Resources
### references/
- `references/apple-developer-docs.md`: Apple-only entry points for Swift, SwiftUI, Metal, and Metal shading language docs.
