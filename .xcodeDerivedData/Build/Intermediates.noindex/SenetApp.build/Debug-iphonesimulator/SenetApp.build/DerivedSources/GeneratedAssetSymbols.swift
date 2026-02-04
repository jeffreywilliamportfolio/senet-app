import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "ambient-dust-overlay" asset catalog image resource.
    static let ambientDustOverlay = DeveloperToolsSupport.ImageResource(name: "ambient-dust-overlay", bundle: resourceBundle)

    /// The "board-surface-texture" asset catalog image resource.
    static let boardSurfaceTexture = DeveloperToolsSupport.ImageResource(name: "board-surface-texture", bundle: resourceBundle)

    /// The "capture-swap-flash" asset catalog image resource.
    static let captureSwapFlash = DeveloperToolsSupport.ImageResource(name: "capture-swap-flash", bundle: resourceBundle)

    /// The "chevron-border-strip" asset catalog image resource.
    static let chevronBorderStrip = DeveloperToolsSupport.ImageResource(name: "chevron-border-strip", bundle: resourceBundle)

    /// The "corner-ornament" asset catalog image resource.
    static let cornerOrnament = DeveloperToolsSupport.ImageResource(name: "corner-ornament", bundle: resourceBundle)

    /// The "grid-line-ink-texture" asset catalog image resource.
    static let gridLineInkTexture = DeveloperToolsSupport.ImageResource(name: "grid-line-ink-texture", bundle: resourceBundle)

    /// The "legal-move-marker" asset catalog image resource.
    static let legalMoveMarker = DeveloperToolsSupport.ImageResource(name: "legal-move-marker", bundle: resourceBundle)

    /// The "player-token-a" asset catalog image resource.
    static let playerTokenA = DeveloperToolsSupport.ImageResource(name: "player-token-a", bundle: resourceBundle)

    /// The "player-token-b" asset catalog image resource.
    static let playerTokenB = DeveloperToolsSupport.ImageResource(name: "player-token-b", bundle: resourceBundle)

    /// The "selection-ring" asset catalog image resource.
    static let selectionRing = DeveloperToolsSupport.ImageResource(name: "selection-ring", bundle: resourceBundle)

    /// The "special-glyph-01" asset catalog image resource.
    static let specialGlyph01 = DeveloperToolsSupport.ImageResource(name: "special-glyph-01", bundle: resourceBundle)

    /// The "special-glyph-02" asset catalog image resource.
    static let specialGlyph02 = DeveloperToolsSupport.ImageResource(name: "special-glyph-02", bundle: resourceBundle)

    /// The "special-glyph-03" asset catalog image resource.
    static let specialGlyph03 = DeveloperToolsSupport.ImageResource(name: "special-glyph-03", bundle: resourceBundle)

    /// The "special-glyph-04" asset catalog image resource.
    static let specialGlyph04 = DeveloperToolsSupport.ImageResource(name: "special-glyph-04", bundle: resourceBundle)

    /// The "special-glyph-05" asset catalog image resource.
    static let specialGlyph05 = DeveloperToolsSupport.ImageResource(name: "special-glyph-05", bundle: resourceBundle)

    /// The "subtle-vignette" asset catalog image resource.
    static let subtleVignette = DeveloperToolsSupport.ImageResource(name: "subtle-vignette", bundle: resourceBundle)

    /// The "water-penalty-sweep" asset catalog image resource.
    static let waterPenaltySweep = DeveloperToolsSupport.ImageResource(name: "water-penalty-sweep", bundle: resourceBundle)

}

