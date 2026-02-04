import MetalKit
import SwiftUI
import QuartzCore

struct MetalBoardView: UIViewRepresentable {
    var selectedSquare: Int?
    var legalDestinations: Set<Int>

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            let fallback = FallbackBoardUIView()
            fallback.backgroundColor = UIColor(red: 0.92, green: 0.86, blue: 0.76, alpha: 1.0)
            context.coordinator.fallback = fallback
            return MTKView(frame: .zero, device: nil).configuredFallbackHost(fallback)
        }

        let view = MTKView(frame: .zero, device: device)
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = true
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.92, green: 0.86, blue: 0.76, alpha: 1.0)

        guard let renderer = MetalBoardRenderer(mtkView: view) else {
            let fallback = FallbackBoardUIView()
            fallback.backgroundColor = UIColor(red: 0.92, green: 0.86, blue: 0.76, alpha: 1.0)
            context.coordinator.fallback = fallback
            return MTKView(frame: .zero, device: nil).configuredFallbackHost(fallback)
        }

        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        if let renderer = context.coordinator.renderer {
            renderer.update(selectedSquare: selectedSquare, legalDestinations: legalDestinations)
            uiView.setNeedsDisplay()
        } else if let fallback = context.coordinator.fallback {
            fallback.selectedSquare = selectedSquare
            fallback.legalDestinations = legalDestinations
            fallback.setNeedsDisplay()
        }
    }

    final class Coordinator {
        var renderer: MetalBoardRenderer?
        var fallback: FallbackBoardUIView?
    }
}

final class MetalBoardRenderer: NSObject, MTKViewDelegate {
    struct Vertex {
        var position: SIMD2<Float>
        var uv: SIMD2<Float>
    }

    struct BoardUniforms {
        var boardSize: SIMD2<Float>
        var selectedIndex: Int32
        var time: Float
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let uniformBuffer: MTLBuffer
    private let legalMaskBuffer: MTLBuffer

    private var time: Float = 0
    private var selectedIndex: Int32 = -1
    private var legalMask: [Float] = Array(repeating: 0, count: 30)
    private var lastTimestamp: CFTimeInterval?

    init?(mtkView: MTKView) {
        guard let device = mtkView.device else { return nil }
        self.device = device

        guard let commandQueue = device.makeCommandQueue() else { return nil }
        self.commandQueue = commandQueue

        let vertices: [Vertex] = [
            Vertex(position: SIMD2(-1, -1), uv: SIMD2(0, 1)),
            Vertex(position: SIMD2(1, -1), uv: SIMD2(1, 1)),
            Vertex(position: SIMD2(-1, 1), uv: SIMD2(0, 0)),
            Vertex(position: SIMD2(-1, 1), uv: SIMD2(0, 0)),
            Vertex(position: SIMD2(1, -1), uv: SIMD2(1, 1)),
            Vertex(position: SIMD2(1, 1), uv: SIMD2(1, 0))
        ]
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else { return nil }
        self.vertexBuffer = vertexBuffer

        guard let uniformBuffer = device.makeBuffer(length: MemoryLayout<BoardUniforms>.stride, options: []) else { return nil }
        self.uniformBuffer = uniformBuffer

        guard let legalMaskBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * 30, options: []) else { return nil }
        self.legalMaskBuffer = legalMaskBuffer

        guard let library = device.makeDefaultLibrary() else { return nil }
        guard let vertexFunction = library.makeFunction(name: "boardVertex") else { return nil }
        guard let fragmentFunction = library.makeFunction(name: "boardFragment") else { return nil }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "BoardPipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }

        super.init()
    }

    func update(selectedSquare: Int?, legalDestinations: Set<Int>) {
        if let square = selectedSquare, (1...30).contains(square) {
            selectedIndex = Int32(square - 1)
        } else {
            selectedIndex = -1
        }

        legalMask = Array(repeating: 0, count: 30)
        for dest in legalDestinations where (1...30).contains(dest) {
            legalMask[dest - 1] = 1
        }

        _ = legalMask.withUnsafeBytes { bytes in
            memcpy(legalMaskBuffer.contents(), bytes.baseAddress!, bytes.count)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No-op; using UV space for rendering.
    }

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        guard let drawable = view.currentDrawable else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        let now = CACurrentMediaTime()
        if let lastTimestamp {
            time += Float(now - lastTimestamp)
        }
        lastTimestamp = now
        var uniforms = BoardUniforms(boardSize: SIMD2(10, 3), selectedIndex: selectedIndex, time: time)
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<BoardUniforms>.stride)

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(legalMaskBuffer, offset: 0, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

private extension MTKView {
    func configuredFallbackHost(_ fallback: UIView) -> MTKView {
        let host = MTKView(frame: .zero, device: nil)
        host.isPaused = true
        host.enableSetNeedsDisplay = true
        host.backgroundColor = fallback.backgroundColor
        host.addSubview(fallback)
        fallback.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fallback.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            fallback.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            fallback.topAnchor.constraint(equalTo: host.topAnchor),
            fallback.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        return host
    }
}

final class FallbackBoardUIView: UIView {
    var selectedSquare: Int?
    var legalDestinations: Set<Int> = []

    override class var layerClass: AnyClass { CALayer.self }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let baseColor = UIColor(red: 0.92, green: 0.86, blue: 0.75, alpha: 1.0)
        ctx.setFillColor(baseColor.cgColor)
        ctx.fill(rect)

        let cols = 10
        let rows = 3
        let cellWidth = rect.width / CGFloat(cols)
        let cellHeight = rect.height / CGFloat(rows)

        let gridColor = UIColor(red: 0.28, green: 0.24, blue: 0.2, alpha: 1.0)
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.setLineWidth(1)

        for col in 0...cols {
            let x = rect.minX + CGFloat(col) * cellWidth
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for row in 0...rows {
            let y = rect.minY + CGFloat(row) * cellHeight
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        ctx.strokePath()

        for square in legalDestinations {
            let cell = cellRect(for: square, cellWidth: cellWidth, cellHeight: cellHeight, in: rect)
            ctx.setFillColor(UIColor(red: 0.22, green: 0.45, blue: 0.75, alpha: 0.25).cgColor)
            ctx.fill(cell.insetBy(dx: 2, dy: 2))
        }

        if let selected = selectedSquare {
            let cell = cellRect(for: selected, cellWidth: cellWidth, cellHeight: cellHeight, in: rect)
            ctx.setStrokeColor(UIColor(red: 0.85, green: 0.62, blue: 0.25, alpha: 0.9).cgColor)
            ctx.setLineWidth(3)
            ctx.stroke(cell.insetBy(dx: 3, dy: 3))
        }
    }

    private func cellRect(for square: Int, cellWidth: CGFloat, cellHeight: CGFloat, in rect: CGRect) -> CGRect {
        let index = max(0, min(29, square - 1))
        let row: Int
        let col: Int

        if index < 10 {
            row = 0
            col = index
        } else if index < 20 {
            row = 1
            col = 9 - (index - 10)
        } else {
            row = 2
            col = index - 20
        }

        let x = rect.minX + CGFloat(col) * cellWidth
        let y = rect.minY + CGFloat(row) * cellHeight
        return CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
    }
}
