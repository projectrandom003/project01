shader_type canvas_item;

// Ground-cover detail: ONE MultiMesh draws an entire chunk's tufts, petals,
// pebbles and lily pads in a single draw call. Instance COLOR tints a tiny
// soft rounded/tufted alpha mask derived from UV. Cheap and mobile-safe.

varying vec2 detail_uv;

void vertex() {
	detail_uv = UV;
}

void fragment() {
	vec2 p = detail_uv * 2.0 - 1.0;
	// Squash toward the base so the tuft reads as grounded, then a soft round
	// falloff for the alpha mask.
	float d = length(vec2(p.x, (p.y + 0.15) * 1.3));
	float mask = 1.0 - smoothstep(0.35, 1.0, d);
	if (mask <= 0.003) {
		discard;
	}
	COLOR = vec4(COLOR.rgb, COLOR.a * mask);
}
