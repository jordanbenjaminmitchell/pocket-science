shader_type canvas_item;
// Renders a lit, rolling pool ball on a quad. The orientation matrix maps ball
// space to view space (X right, Y up, Z toward the viewer).

uniform vec4 base_color : source_color = vec4(1.0, 0.8, 0.1, 1.0);
uniform float stripe = 0.0;     // 1 = striped ball
uniform float is_cue = 0.0;
uniform mat3 orient = mat3(1.0);
uniform float radius_uv = 0.86; // ball radius as a fraction of the half-quad
uniform vec4 glow_color : source_color = vec4(0.0);
uniform float fade = 1.0;       // used for pocketing

void fragment() {
	vec2 q = (UV * 2.0 - 1.0) / radius_uv;
	float r2 = dot(q, q);
	float edge = fwidth(sqrt(r2)) * 1.4;
	float alpha = 1.0 - smoothstep(1.0 - edge, 1.0, sqrt(r2));
	// Isotope glow ring outside the ball.
	float gd = sqrt(r2);
	float ring = glow_color.a * smoothstep(1.16, 1.0, gd) * smoothstep(0.92, 1.02, gd);
	if (r2 > 1.0) {
		COLOR = vec4(glow_color.rgb, ring * fade);
	} else {
		vec3 n = vec3(q.x, -q.y, sqrt(max(0.0, 1.0 - r2)));
		vec3 l = transpose(orient) * n;   // ball-local normal
		vec3 white = vec3(0.97, 0.95, 0.9);
		vec3 col = base_color.rgb;
		if (stripe > 0.5) {
			float band = smoothstep(0.56, 0.52, abs(l.z));
			col = mix(white, base_color.rgb, band);
		}
		if (is_cue > 0.5) {
			col = white;
			// Tiny red measle spots so the cue's spin is readable.
			float s1 = smoothstep(0.985, 0.99, abs(dot(l, normalize(vec3(1.0, 1.0, 1.0)))));
			float s2 = smoothstep(0.985, 0.99, abs(dot(l, normalize(vec3(-1.0, 1.0, -1.0)))));
			col = mix(col, vec3(0.8, 0.1, 0.12), max(s1, s2));
		} else {
			// Number discs on +X and -X.
			float disc = smoothstep(0.80, 0.83, abs(l.x));
			col = mix(col, white, disc);
		}
		vec3 L = normalize(vec3(-0.35, 0.45, 0.82));
		float diff = max(dot(n, L), 0.0);
		vec3 h = normalize(L + vec3(0.0, 0.0, 1.0));
		float spec = pow(max(dot(n, h), 0.0), 70.0) * 0.9;
		// Soft overhead lamp reflection (a stretched highlight).
		float lamp = smoothstep(0.17, 0.0, length((q - vec2(-0.32, -0.36)) * vec2(1.0, 1.6))) * 0.45;
		float rim = pow(1.0 - n.z, 2.2);
		vec3 shade = col * (0.28 + 0.78 * diff) * (1.0 - rim * 0.45);
		shade += vec3(spec + lamp);
		shade += vec3(0.05, 0.12, 0.08) * rim * 0.6; // felt bounce light
		COLOR = vec4(shade, alpha * fade);
		COLOR.rgb = mix(COLOR.rgb, glow_color.rgb, ring * 0.0);
	}
}
