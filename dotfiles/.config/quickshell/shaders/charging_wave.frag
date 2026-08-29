#version 440

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float iTime;     // 0 → 1
    float iR;
    float iG;
    float iB;
    float iAspect;   // width / height
};

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 74.27);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = qt_TexCoord0;

    // Origin: bottom-right corner
    vec2 origin = vec2(1.0, 1.0);

    // Aspect-corrected offset so rings look circular on screen
    vec2 delta = (uv - origin) * vec2(iAspect, 1.0);
    float dist  = length(delta);
    float angle = atan(delta.y, delta.x);

    // Max distance from bottom-right to top-left in aspect-corrected space
    float maxDist = length(vec2(iAspect, 1.0));

    // ── Envelope ────────────────────────────────────────────────────────────
    float env = smoothstep(0.0, 0.04, iTime)
              * (1.0 - smoothstep(0.86, 1.0, iTime));

    // ── Wave front ──────────────────────────────────────────────────────────
    float front = iTime * (maxDist + 0.15);

    // Organic wobble on ring edge using angle-based harmonics
    float wobble = 0.0;
    wobble += 0.028 * sin(angle *  5.0 + iTime *  7.0);
    wobble += 0.016 * sin(angle *  9.0 - iTime * 11.0);
    wobble += 0.010 * sin(angle * 15.0 + iTime * 16.0);
    wobble += 0.006 * sin(angle * 23.0 - iTime *  9.0);

    float ringDist = dist + wobble;

    // ── Primary ring — tight gaussian around the front ───────────────────────
    float d0       = ringDist - front;
    float mainRing = exp(-d0 * d0 * 260.0);

    // Energy dissipates as ring expands
    float dissipation = 1.0 - smoothstep(0.0, maxDist * 0.9, front);

    // ── Trailing echo rings ──────────────────────────────────────────────────
    float echo = 0.0;
    for (int i = 1; i <= 4; i++) {
        float fi      = float(i);
        float spacing = 0.06 + fi * 0.01;
        float efront  = front - fi * spacing;
        if (efront > 0.0) {
            float de = ringDist - efront;
            float strength = exp(-fi * 0.7) * 0.6;
            echo += exp(-de * de * 400.0) * strength;
        }
    }

    // ── Origin corona — bright flare at bottom-right on activation ───────────
    float corona = exp(-dist * 9.0)
                 * smoothstep(0.0, 0.12, iTime)
                 * smoothstep(0.55, 0.25, iTime)
                 * 1.2;

    // ── Sparkles riding the wave front ──────────────────────────────────────
    float sparkle = 0.0;
    for (int j = 0; j < 10; j++) {
        float fj    = float(j);
        float tick  = floor(iTime * 10.0);
        float sa    = hash(vec2(fj * 2.39, tick)) * 6.28318;  // angle
        float sr    = hash(vec2(fj * 1.61, tick + 1.0)) * 0.04 - 0.02;
        float sp    = hash(vec2(fj * 3.14, tick + 2.0));

        vec2  spos  = origin + (front + sr) * vec2(cos(sa) / iAspect, sin(sa));
        float sdist = distance(uv, spos);
        float flick = 0.4 + 0.6 * sin(iTime * 30.0 + sp * 6.28318);
        sparkle += smoothstep(0.012, 0.0, sdist) * flick * dissipation;
    }
    sparkle = clamp(sparkle, 0.0, 1.0);

    // ── Compose — no background fill, rings only ────────────────────────────
    float alpha = clamp(
        (mainRing * (0.75 + dissipation * 0.25) + echo * 0.55 + corona + sparkle * 0.5) * env,
        0.0, 1.0
    );

    vec3 col = vec3(iR, iG, iB);
    // White-hot core of the main ring and sparkles
    float whiteHot = clamp((mainRing * dissipation + sparkle) * env, 0.0, 1.0);
    col = mix(col, vec3(1.0), whiteHot * 0.55);

    fragColor = vec4(col, alpha) * qt_Opacity;
}
