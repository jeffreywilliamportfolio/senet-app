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
                              constant float *legalMask [[buffer(1)]],
                              texture2d<float> boardTex [[texture(0)]],
                              texture2d<float> inkTex [[texture(1)]],
                              texture2d<float> vignetteTex [[texture(2)]],
                              texture2d<float> dustTex [[texture(3)]]) {
    constexpr sampler sampRepeat(address::repeat, filter::linear);
    constexpr sampler sampClamp(address::clamp_to_edge, filter::linear);
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

    float3 base = boardTex.sample(sampClamp, uv).rgb;
    float dust = dustTex.sample(sampRepeat, uv * 2.0 + u.time * 0.01).r;
    base = mix(base, base + (dust - 0.5) * 0.04, 0.35);

    float2 distToEdge = min(cellFrac, 1.0 - cellFrac);
    float lineWidth = 0.03;
    float line = step(distToEdge.x, lineWidth) + step(distToEdge.y, lineWidth);
    line = clamp(line, 0.0, 1.0);

    float ink = inkTex.sample(sampRepeat, uv * 6.0).r;
    float3 gridColor = float3(0.28, 0.24, 0.2) * mix(0.8, 1.1, ink);
    float3 color = mix(base, gridColor, line * 0.75);

    float legal = legalMask[index];
    if (legal > 0.5) {
        color = mix(color, float3(0.22, 0.45, 0.75), 0.35);
    }

    if (u.selectedIndex == index) {
        color = mix(color, float3(0.85, 0.62, 0.25), 0.35);
    }

    float vignette = vignetteTex.sample(sampClamp, uv).r;
    color *= mix(1.0, vignette, 0.9);

    return float4(color, 1.0);
}
