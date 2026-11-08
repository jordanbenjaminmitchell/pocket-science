shader_type canvas_item;
// The lab floor around the table: dark hex tiles lit by the table lamp.

uniform vec2 size = vec2(1600.0, 900.0);
uniform vec2 lamp = vec2(970.0, 360.0);

float hex_edge(vec2 p) {
	vec2 s = vec2(1.0, 1.7320508);
	vec2 a = mod(p, s) - s * 0.5;
	vec2 b = mod(p + s * 0.5, s) - s * 0.5;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	g = abs(g);
	return 0.5 - max(dot(g, normalize(s)), g.x);
}

void fragment() {
	vec2 px = UV * size;
	float e = hex_edge(px / 46.0);
	float line = 1.0 - smoothstep(0.0, 0.03, e);
	float d = length((px - lamp) * vec2(0.62, 1.0)) / size.x;
	float glow = 1.0 - smoothstep(0.1, 0.62, d);
	vec3 base = vec3(0.028, 0.034, 0.045);
	vec3 col = base + vec3(0.05, 0.06, 0.05) * glow;
	col += vec3(0.09, 0.14, 0.15) * line * (0.25 + 0.75 * glow);
	COLOR = vec4(col, 1.0);
}
