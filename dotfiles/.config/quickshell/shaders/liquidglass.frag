#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float blurRadius;
    float saturation;
    float brightness;
    float glassOpacity;
    vec4 tint;
    float time;
};

layout(binding = 1) uniform sampler2D source;

const float PI = 3.14159265359;

// Optimized Gaussian blur with weighted samples
vec4 gaussianBlur(sampler2D tex, vec2 uv, float radius) {
    vec4 color = vec4(0.0);
    vec2 pixelSize = vec2(0.001) * radius;

    // Gaussian weights for 9 samples (3x3 with optimized pattern)
    float weights[9] = float[](
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    );

    int idx = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixelSize;
            color += texture(tex, uv + offset) * weights[idx];
            idx++;
        }
    }

    return color;
}

// Refraction distortion - bends light through the glass
vec2 applyRefraction(vec2 uv, float strength) {
    // Distance from center creates refraction effect
    vec2 center = vec2(0.5);
    vec2 fromCenter = uv - center;
    float dist = length(fromCenter);

    // Subtle distortion based on distance and time
    vec2 distortion = fromCenter * sin(dist * 8.0 - time * 0.3) * strength * 0.015;

    return uv + distortion;
}

// Chromatic dispersion - separates RGB channels at edges (like a prism)
vec4 chromaticDispersion(sampler2D tex, vec2 uv, float strength) {
    vec2 center = vec2(0.5);
    vec2 direction = normalize(uv - center);
    float dist = length(uv - center);

    // Stronger dispersion at edges
    float dispersionAmount = dist * strength * 0.003;

    // Sample each color channel with slight offset
    float r = texture(tex, uv + direction * dispersionAmount).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - direction * dispersionAmount).b;

    return vec4(r, g, b, 1.0);
}

// Fresnel effect - more reflection at edges, more transparency at center
float fresnelEffect(vec2 uv) {
    vec2 center = vec2(0.5);
    float dist = length(uv - center) * 2.0;  // 0 at center, ~1.4 at corners

    // Fresnel approximation: F = F0 + (1 - F0) * (1 - cos(θ))^5
    float fresnel = pow(dist, 2.5);
    return clamp(fresnel, 0.0, 1.0);
}

// Specular highlight for "wet" glass look
float specularHighlight(vec2 uv, float time) {
    vec2 center = vec2(0.5);
    vec2 lightPos = vec2(0.3 + sin(time * 0.5) * 0.1, 0.2);

    float dist = length(uv - lightPos);
    float highlight = exp(-dist * 15.0);  // Sharp falloff

    return highlight * 0.3;
}

// Enhanced saturation
vec3 adjustSaturation(vec3 color, float sat) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, sat);
}

void main() {
    vec2 uv = qt_TexCoord0;

    // Apply refraction distortion
    vec2 refractedUV = applyRefraction(uv, 1.0);

    // Multi-pass blur for smooth glass effect
    vec4 blur1 = gaussianBlur(source, refractedUV, blurRadius);
    vec4 blur2 = gaussianBlur(source, refractedUV, blurRadius * 1.5);
    vec4 blurred = mix(blur1, blur2, 0.3);  // Blend multiple blur passes

    // Apply chromatic dispersion at edges
    vec4 dispersed = chromaticDispersion(source, refractedUV, blurRadius * 0.5);

    // Mix blurred and dispersed based on edge distance
    float edgeFactor = length(uv - vec2(0.5)) * 2.0;
    vec4 combined = mix(blurred, dispersed, edgeFactor * 0.4);

    // Color adjustments
    vec3 color = adjustSaturation(combined.rgb, saturation);
    color *= brightness;

    // Apply tint
    color = mix(color, tint.rgb, tint.a);

    // Fresnel effect - edges more opaque/reflective
    float fresnel = fresnelEffect(uv);
    float alpha = mix(glassOpacity, glassOpacity + 0.25, fresnel);

    // Add specular highlight for wet glass appearance
    float specular = specularHighlight(uv, time);
    color += specular;

    // Very subtle animated shimmer
    float shimmer = sin(uv.x * 50.0 + time * 2.0) * sin(uv.y * 50.0 + time * 2.0);
    color += shimmer * 0.01;

    // Clamp and output
    color = clamp(color, 0.0, 1.0);
    fragColor = vec4(color, alpha) * qt_Opacity;
}
