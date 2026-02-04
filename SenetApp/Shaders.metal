#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position;
    float2 uv;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct BoardUniforms {
    float2 boardSize;
    int selectedIndex;
    float time;
};

vertex VertexOut boardVertex(uint vid [[vertex_id]], const device VertexIn *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vid].position, 0.0, 1.0);
    out.uv = vertices[vid].uv;
    return out;
}

float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fragment float4 boardFragment(VertexOut in [[stage_in]],
                              constant BoardUniforms &u [[buffer(0)]],
                              constant float *legalMask [[buffer(1)]]) {
    float2 uv = in.uv;
    float2 grid = uv * u.boardSize;
    float2 cell = floor(grid);
    float2 cellFrac = fract(grid);

    int row = clamp((int)cell.y, 0, 2);
    int col = clamp((int)cell.x, 0, 9);

    int index = 0;
    if (row == 0) {
        index = col;
    } else if (row == 1) {
        index = 10 + (9 - col);
    } else {
        index = 20 + col;
    }

    float noise = hash21(uv * 120.0 + u.time * 0.01);
    float3 base = float3(0.92, 0.86, 0.75) + (noise - 0.5) * 0.03;

    float2 distToEdge = min(cellFrac, 1.0 - cellFrac);
    float lineWidth = 0.03;
    float line = step(distToEdge.x, lineWidth) + step(distToEdge.y, lineWidth);
    line = clamp(line, 0.0, 1.0);

    float3 gridColor = float3(0.28, 0.24, 0.2);
    float3 color = mix(base, gridColor, line * 0.7);

    float legal = legalMask[index];
    if (legal > 0.5) {
        color = mix(color, float3(0.22, 0.45, 0.75), 0.35);
    }

    if (u.selectedIndex == index) {
        color = mix(color, float3(0.85, 0.62, 0.25), 0.35);
    }

    float2 centered = uv - 0.5;
    float vignette = smoothstep(0.85, 0.35, length(centered));
    color *= vignette;

    return float4(color, 1.0);
}
