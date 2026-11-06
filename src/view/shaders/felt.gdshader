shader_type canvas_item;
// Woven cloth with an overhead lamp pool and vignette.
uniform vec4 felt : source_color = vec4(0.06, 0.42, 0.28, 1.0);
uniform vec2 size = vec2(1100.0, 550.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 px = UV * size;
	float grain = hash(floor(px)) * 0.05 + noise(px * 0.08) * 0.05 + noise(px * 0.012) * 0.06;
	float weave = (sin(px.x * 2.1) * sin(px.y * 2.1)) * 0.012;
	vec2 c = (UV - 0.5) * vec2(2.0, 1.0);
	float lamp = 1.0 - smoothstep(0.0, 1.25, length(c * vec2(0.62, 1.0)));
	vec3 col = felt.rgb * (0.62 + 0.55 * lamp) + vec3(grain + weave) * felt.rgb * 2.0;
	// Darken toward cushions.
	float ex = min(UV.x, 1.0 - UV.x) * size.x;
	float ey = min(UV.y, 1.0 - UV.y) * size.y;
	float edge = smoothstep(0.0, 26.0, min(ex, ey));
	col *= 0.72 + 0.28 * edge;
	COLOR = vec4(col, 1.0);
}
