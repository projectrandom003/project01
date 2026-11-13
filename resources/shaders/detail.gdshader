shader_type canvas_item;

// A single batched ground-cover layer. Each instance reads as a small tuft of
// blades and leaves rather than a soft circular blob.

varying vec2 detail_uv;

void vertex() {
    detail_uv = UV;
}

float blade(vec2 p, vec2 center, vec2 radius, float lean) {
    vec2 q = p - center;
    q.x -= q.y * lean;
    float d = length(q / radius);
    return 1.0 - smoothstep(0.72, 1.08, d);
}

void fragment() {
    vec2 p = detail_uv * 2.0 - 1.0;

    float blades = 0.0;
    blades = max(blades, blade(p, vec2(-0.48, 0.12), vec2(0.18, 0.66), -0.20));
    blades = max(blades, blade(p, vec2(-0.18, -0.02), vec2(0.16, 0.82), -0.08));
    blades = max(blades, blade(p, vec2(0.14, 0.04), vec2(0.17, 0.74), 0.10));
    blades = max(blades, blade(p, vec2(0.43, 0.16), vec2(0.16, 0.58), 0.22));

    float leaf_a = blade(p, vec2(-0.38, 0.48), vec2(0.34, 0.20), 0.18);
    float leaf_b = blade(p, vec2(0.34, 0.50), vec2(0.32, 0.18), -0.16);
    float base = 1.0 - smoothstep(0.08, 0.42, length(vec2(p.x * 0.72, (p.y - 0.55) * 1.25)));
    float mask = max(max(blades, leaf_a * 0.82), max(leaf_b * 0.82, base * 0.68));
    if (mask <= 0.012) {
        discard;
    }

    float vein = (1.0 - smoothstep(0.0, 0.035, abs(p.x + p.y * 0.10))) * (1.0 - smoothstep(0.1, 0.9, p.y));
    vec3 lit = COLOR.rgb * (0.92 + vein * 0.16);
    COLOR = vec4(lit, COLOR.a * mask * 0.92);
}
