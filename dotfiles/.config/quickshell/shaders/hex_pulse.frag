#version 440

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float iTime;
    float iHexSize;
    float iSpeed;
    float iEdgeSoft;
    float iRandomness;
    vec2  iResolution;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hextile(inout vec2 p) {
    const vec2 s  = vec2(1.0, 1.7320508);
    const vec2 hs = s * 0.5;
    vec2 a = mod(p,      s) - hs;
    vec2 b = mod(p - hs, s) - hs;
    vec2 c = dot(a, a) < dot(b, b) ? a : b;
    vec2 id = round((c - p) / s + hs);
    p = c;
    return id;
}

float hexSDF(vec2 p, float r) {
    p = abs(p);
    return max(p.x * 0.866025 + p.y * 0.5, p.y) - r;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p  = uv - 0.5;
    p.x    *= iResolution.x / iResolution.y;

    // ── hex grid ──────────────────────────────────────────────────────────
    vec2 hp = p / iHexSize;
    vec2 id = hextile(hp);   // hp is now local coords inside cell

    // ── per-hex diagonal delay ────────────────────────────────────────────
    // delay 0 = bottom-right, delay 1 = top-left
    float delay = (1.0 - uv.x) * 0.5 + (1.0 - uv.y) * 0.5;

    // small random jitter per cell so neighbours don't pop at same frame
    float jitter = hash(id) * iRandomness;
    float t      = clamp((iTime - (delay + jitter) * 0.85) / 0.18, 0.0, 1.0);

    // ── scale curve: grow → hold → shrink → gone ─────────────────────────
    // t: 0.0 → 0.3  grow from 0 to full
    //    0.3 → 0.65 hold at full size
    //    0.65 → 1.0 shrink back to 0
    float scale;
    if (t < 0.3) {
        // ease-out grow
        float g = t / 0.3;
        scale   = g * g * (3.0 - 2.0 * g);   // smoothstep
    } else if (t < 0.65) {
        scale   = 1.0;
    } else {
        // ease-in shrink
        float s = (t - 0.65) / 0.35;
        scale   = 1.0 - s * s * (3.0 - 2.0 * s);
    }

    // if hex hasn't started or has fully shrunk, skip
    if (t <= 0.0 || scale < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    // ── border only — outer ring minus inner ring ─────────────────────────
    float maxR   = 0.86;
    float outer  = hexSDF(hp, scale * maxR);
    float inner  = hexSDF(hp, scale * (maxR - 0.10));  // border thickness = 0.10

    float border = smoothstep( iEdgeSoft, -iEdgeSoft, outer)
                 * (1.0 - smoothstep(-iEdgeSoft, iEdgeSoft, inner));

    if (border < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // ── brightness: brightest when fully open, dims when shrinking ────────
    float brightness = scale;
    // extra flash at the moment of full open (t ≈ 0.3)
    float flash = smoothstep(0.15, 0.3, t) * smoothstep(0.5, 0.3, t) * 0.4;
    brightness += flash;
    brightness  = clamp(brightness, 0.0, 1.0);

    float alpha = border * brightness;

    fragColor = vec4(1.0, 1.0, 1.0, alpha) * qt_Opacity;
}
