shader_type canvas_item;

// Quiet, world-space water. The old tile-local sine bands repeated identically
// on every diamond and made rivers look like a bright tiled floor.
varying vec2 tile_uv;
varying vec2 world_xy;

float hash21(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
    tile_uv = UV;
    world_xy = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 p = tile_uv * 2.0 - 1.0;
    float diamond = abs(p.x) + abs(p.y);
    if (diamond > 1.0) {
        discard;
    }

    vec2 world = world_xy * 0.014;
    float slow_wave = sin(world.x * 1.7 + world.y * 0.9 + TIME * 0.28) * 0.5 + 0.5;
    float ripple = value_noise(world * 3.2 + vec2(TIME * 0.035, -TIME * 0.022));
    float shimmer = smoothstep(0.62, 0.92, slow_wave * 0.58 + ripple * 0.42);

    vec3 depth = COLOR.rgb;
    vec3 reflection = vec3(0.56, 0.72, 0.73);
    vec3 color = mix(depth, reflection, 0.035 + shimmer * 0.10);
    color += vec3(0.035, 0.065, 0.068) * shimmer;

    // Keep the water opaque at tile joins; otherwise the land below leaks
    // through as a repeating diamond grid.
    COLOR = vec4(color, COLOR.a);
}