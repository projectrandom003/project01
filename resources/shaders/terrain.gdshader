shader_type canvas_item;

// Layered forest floor. Tile edges are intentionally quiet: the ground should
// read as one continuous woodland floor, not a checkerboard of raised diamonds.
varying vec2 tile_uv;
varying vec2 world_xy;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
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

    vec3 base = COLOR.rgb;
    vec2 world = world_xy * 0.018;
    float broad = value_noise(world * 1.35);
    float fine = value_noise(world * 5.1 + tile_uv * 1.7);
    float micro = hash21(floor(world_xy * 0.52 + tile_uv * 23.0));
    float mottling = broad * 0.64 + fine * 0.27 + micro * 0.09;

    float damp_patch = smoothstep(0.30, 0.78, mottling);
    float dry_patch = smoothstep(0.74, 0.96, 1.0 - mottling);
    base = mix(base, base * vec3(0.80, 0.87, 0.76), damp_patch * 0.17);
    base = mix(base, base * vec3(1.06, 1.015, 0.91), dry_patch * 0.07);

    // Very soft top-left light; no darkened tile bevels. Adjacent diamonds
    // should read as continuous soil rather than a visible checkerboard.
    float upper_light = 1.0 - smoothstep(-0.25, 0.9, p.y - p.x * 0.16);
    base *= 0.97 + upper_light * 0.03;

    float fleck = step(0.992, hash21(floor(world_xy * 0.48 + tile_uv * 31.0)));
    float inner = 1.0 - smoothstep(0.58, 0.92, diamond);
    base = mix(base, base * vec3(1.10, 1.07, 0.94), fleck * inner * 0.12);

    COLOR = vec4(base, COLOR.a);
}