shader_type canvas_item;

// Cheap GPU wind sway for foliage sprites. The top of the sprite moves more
// than the base (base-anchored), the phase is derived from world position so a
// whole forest never sways in lockstep, and a subtle secondary shimmer adds a
// faint lightness pulse. Vertex-only on purpose: the default fragment still
// samples the sprite texture, so foliage keeps its artwork.

uniform float sway_strength = 2.4;
uniform float sway_speed = 1.15;

void vertex() {
	vec4 world = MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0);
	float height_weight = pow(clamp(1.0 - UV.y, 0.0, 1.0), 2.0);

	// Per-instance phase from world position (each prop sits at a different
	// world coordinate, so no two sway in sync).
	float phase = world.x * 0.013 + world.y * 0.017 + TIME * sway_speed;

	float primary = sin(phase);
	// Subtle, faster secondary shimmer (small amplitude, different frequency).
	float secondary = sin(phase * 2.3 + 1.7) * 0.25;

	VERTEX.x += (primary + secondary) * height_weight * sway_strength;
	VERTEX.y += cos(phase * 0.7) * height_weight * sway_strength * 0.25;

	// Faint lightness pulse, still vertex-only: COLOR is passed to the default
	// fragment which multiplies it with the sprite texture.
	COLOR.rgb *= 1.0 + (secondary * 0.5 + 0.5) * 0.06 * height_weight;
}
