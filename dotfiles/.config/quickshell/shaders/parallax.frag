#version 440

// Based on the DepthFlow ray marching algorithm
// (c) Adapted from DepthFlow - CC BY-SA 4.0, Tremeschin

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float offsetX;           // Mouse X offset [-1, 1]
    float offsetY;           // Mouse Y offset [-1, 1]
    float parallaxStrength;  // Parallax intensity
    float aspectRatio;       // Image aspect ratio (width/height)
    float quality;           // Ray march quality [0.0-1.0], default 0.3
};

layout(binding = 1) uniform sampler2D source;     // Original image
layout(binding = 2) uniform sampler2D depthMap;   // Depth map

// Constants
const float PI = 3.14159265359;
const float TAU = 6.28318530718;


// Triangle wave for mirrored repeat 
float triangle_wave(float x, float period) {
    return 2.0 * abs(mod(2.0 * x / period - 0.5, 2.0) - 1.0) - 1.0;
}

// GLUV mirrored repeat 
vec2 gluv_mirrored_repeat(vec2 gluv, float aspect) {
    return vec2(
        aspect * triangle_wave(gluv.x, 4.0 * aspect),
        triangle_wave(gluv.y, 4.0)
    );
}

// Convert UV to GLUV space with aspect ratio
vec2 uv2gluv(vec2 uv, float aspect) {
    return vec2(
        (uv.x * 2.0 - 1.0) * aspect,
        (uv.y * 2.0 - 1.0)
    );
}

// Convert GLUV back to UV
vec2 gluv2uv(vec2 gluv, float aspect) {
    return vec2(
        (gluv.x / aspect + 1.0) * 0.5,
        (gluv.y + 1.0) * 0.5
    );
}

// DepthFlow ray marching implementation (returns final GLUV position)
vec2 depthFlowRayMarch(vec2 gluv, vec2 offset, float aspect, float qualityParam) {
    const float height = 0.45;      // Increased for stronger 3D depth effect
    const float steady = 0.15;      // Adds perspective stability

    // Quality determines step sizes (optimized ranges for wallpaper use)
    float stepQuality = 1.0 / mix(100.0, 800.0, qualityParam);
    float stepProbe = 1.0 / mix(30.0, 80.0, qualityParam);

    // Relative steady
    float relSteady = steady * height;

    // intersect = vec3(gluv, 1.0) - vec3(offset, 0.0) * (1.0/(1.0 - rel_steady))
    vec3 rayOrigin = vec3(gluv, 0.0);
    vec3 intersect = vec3(gluv, 1.0) - vec3(offset, 0.0) * (1.0 / (1.0 - relSteady));

    // Safety: guaranteed relative distance to not hit surface
    float safe = 1.0 - height;
    float walk = 0.0;
    vec2 finalGluv = gluv;

    // Stage 1: Forward march (coarse probe to find approximate intersection)
    for (int it = 0; it < 60; it++) {
        if (walk > 1.0) break;

        walk += stepProbe;

        // Interpolate origin and intersect
        vec3 point = mix(rayOrigin, intersect, mix(safe, 1.0, walk));
        finalGluv = point.xy;

        // Sample depth with mirroring
        vec2 mirroredGluv = gluv_mirrored_repeat(finalGluv, aspect);
        vec2 sampleUV = gluv2uv(mirroredGluv, aspect);
        float depthValue = texture(depthMap, sampleUV).r;

        // Calculate surface height (white=foreground, black=background)
        float surface = height * depthValue;
        float ceiling = 1.0 - point.z;

        // Stop when ray hits surface
        if (ceiling < surface) break;
    }

    // Stage 2: Backward march (fine quality refinement)
    for (int it = 0; it < 40; it++) {
        walk -= stepQuality;
        if (walk < 0.0) break;

        vec3 point = mix(rayOrigin, intersect, mix(safe, 1.0, walk));
        finalGluv = point.xy;

        vec2 mirroredGluv = gluv_mirrored_repeat(finalGluv, aspect);
        vec2 sampleUV = gluv2uv(mirroredGluv, aspect);
        float depthValue = texture(depthMap, sampleUV).r;

        float surface = height * depthValue;
        float ceiling = 1.0 - point.z;

        // Stop when ray exits surface (precise intersection found)
        if (ceiling >= surface) break;
    }

    // Return final GLUV position 
    return finalGluv;
}

void main() {
    // Get normalized texture coordinates and convert to GLUV space
    vec2 uv = qt_TexCoord0;
    vec2 gluv = uv2gluv(uv, aspectRatio);

    // Mouse offset
    vec2 offset = vec2(offsetX, -offsetY) * parallaxStrength;

    // Perform DepthFlow ray marching
    vec2 finalGluv = depthFlowRayMarch(gluv, offset, aspectRatio, quality);

    // Sample the image with mirroring 
    vec2 mirroredGluv = gluv_mirrored_repeat(finalGluv, aspectRatio);
    vec2 finalUV = gluv2uv(mirroredGluv, aspectRatio);

    // Sample the image at the parallaxed position
    fragColor = texture(source, finalUV);
    fragColor.a *= qt_Opacity;
}
