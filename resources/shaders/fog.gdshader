shader_type canvas_item;

// Soft, noise-free animated fog overlay. Intended for a full-screen quad or a
// large ColorRect above the world. UV + TIME give slow drifting bands with no
// texture lookups, so it is cheap and mobile-safe.

uniform vec4 fog_color = vec4(0.55, 0.62, 0.78, 1.0);
uniform float density = 0.25;

void fragment() {
	vec2 uv = UV;
	// Two low-frequency drifting bands (sine only).
	float band_a = sin(uv.x * 3.0 + uv.y * 2.0 + TIME * 0.05);
	float band_b = sin(uv.x * 5.0 - uv.y * 3.0 - TIME * 0.035 + 1.3);
	float veil = 0.5 + 0.25 * band_a + 0.25 * band_b;
	// Fog is a little thicker toward the bottom / horizon.
	veil *= mix(0.65, 1.0, smoothstep(0.0, 1.0, uv.y));
	float alpha = clamp(veil * density, 0.0, 1.0) * fog_color.a;
	COLOR = vec4(fog_color.rgb, alpha);
}
