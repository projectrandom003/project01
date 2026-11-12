shader_type canvas_item;

// Isometric terrain tile. One MultiMesh draws an entire chunk in one call.
// Instance COLOR carries the per-tile grass / path / seabed tint.

varying vec2 tile_uv;

void vertex() {
	tile_uv = UV;
}

void fragment() {
	vec2 p = tile_uv * 2.0 - 1.0;
	float diamond = abs(p.x) + abs(p.y);
	if (diamond > 1.0) {
		discard;
	}

	vec3 base = COLOR.rgb;
	// Stable per-pixel grain, no textures required.
	float grain = fract(sin(dot(floor(tile_uv * 48.0), vec2(12.9898, 78.233))) * 43758.5453);
	base *= 0.95 + grain * 0.09;

	// Soft edge darkening gives the diamond a hand-painted bevel.
	float edge = smoothstep(0.80, 1.0, diamond);
	base = mix(base, base * 0.86, edge * 0.55);

	COLOR = vec4(base, COLOR.a);
}
