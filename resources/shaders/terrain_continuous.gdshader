shader_type canvas_item;
// Continuous chunk-sized isometric ground surface (prototype).
// Draws one seamless quad covering a whole chunk and samples a generated per-tile
// color texture so there are no per-tile diamond boundaries. Subtle variation is
// added in-shader. Render-only: does not affect grid, collision, navigation,
// streaming, or gameplay.

uniform sampler2D tile_colors : filter_linear, repeat_disable;
uniform vec2 chunk_origin_grid; // grid coord of tile (0,0) in chunk
uniform vec2 chunk_size;        // tiles in x,y
uniform float tile_w = 64.0;
uniform float tile_h = 32.0;

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
	world_xy = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Inverse isometric projection: world -> continuous grid coords.
	float gx = (world_xy.x / (tile_w * 0.5) + world_xy.y / (tile_h * 0.5)) * 0.5;
	float gy = (world_xy.y / (tile_h * 0.5) - world_xy.x / (tile_w * 0.5)) * 0.5;
	vec2 local = vec2(gx, gy) - chunk_origin_grid;
	// Sample base color from generated per-tile texture (tile centers).
	vec2 uv = (local + vec2(0.5)) / chunk_size;
	vec4 tex = texture(tile_colors, clamp(uv, vec2(0.001), vec2(0.999)));
	if (tex.a <= 0.001) {
		discard;
	}
	vec3 base = tex.rgb;

	// Subtle, continuous natural variation (no tile edges).
	vec2 world = world_xy * 0.018;
	float broad = value_noise(world * 1.35);
	float fine = value_noise(world * 5.1 + local * 0.08);
	float micro = hash21(floor(world_xy * 0.52));
	float mottling = broad * 0.64 + fine * 0.27 + micro * 0.09;
	float damp_patch = smoothstep(0.30, 0.78, mottling);
	float dry_patch = smoothstep(0.74, 0.96, 1.0 - mottling);
	base = mix(base, base * vec3(0.82, 0.89, 0.78), damp_patch * 0.14);
	base = mix(base, base * vec3(1.05, 1.015, 0.92), dry_patch * 0.06);
	float upper_light = 0.985 + 0.03 * clamp(1.0 - gy * 0.01, 0.0, 1.0);
	base *= upper_light;

	COLOR = vec4(base, tex.a);
}
