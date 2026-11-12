shader_type canvas_item;

// Animated stylised water overlay. Tiles are drawn slightly above the seabed
// layer. Instance COLOR carries the shallow->deep depth tint (see
// ChunkBuilder). Cheap by design: two sine bands + one pow, mobile-safe,
// animated via TIME.

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

	// Two slow wave bands -> stylised moving reflections/highlights.
	float wave_a = sin(tile_uv.x * 16.0 + tile_uv.y * 8.0 + TIME * 1.1) * 0.5 + 0.5;
	float wave_b = sin(tile_uv.x * 27.0 - tile_uv.y * 15.0 - TIME * 0.7) * 0.5 + 0.5;
	float shimmer = pow(wave_a * 0.6 + wave_b * 0.4, 3.0);

	vec3 depth = COLOR.rgb;                    // per-instance depth tint
	vec3 reflection = vec3(0.72, 0.90, 0.92); // cool sky reflection
	vec3 color = mix(depth, reflection, 0.12 + shimmer * 0.28);
	color = mix(color, color * 1.18, wave_a * 0.30); // moving glints
	color += vec3(0.10, 0.16, 0.18) * shimmer;

	// Gentle depth shading: slightly darker toward the lower tile edge.
	float depth_shade = smoothstep(-0.2, 1.0, p.y) * 0.12;
	color *= 1.0 - depth_shade;

	// Shore foam: brighten the diamond rim where water meets land, with a
	// wave-driven pulse so the edge is not a static outline.
	float edge = smoothstep(0.82, 1.0, diamond);
	vec3 foam = vec3(0.85, 0.96, 0.93);
	color = mix(color, foam, edge * (0.35 + wave_b * 0.25));

	COLOR = vec4(color, COLOR.a);
}
