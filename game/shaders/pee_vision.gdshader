shader_type canvas_item;
// Everything goes yellow. Luminance kept, hue thrown away, soft vignette.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 src = texture(screen_tex, SCREEN_UV);
	float l = dot(src.rgb, vec3(0.3, 0.59, 0.11));
	l = pow(l, 0.85);
	vec3 yellow = vec3(1.0, 0.86, 0.12) * l * 1.15 + vec3(0.08, 0.06, 0.0);
	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = smoothstep(0.85, 0.35, length(d) * 1.25);
	vec3 outc = mix(yellow * 0.35, yellow, vig);
	COLOR = vec4(mix(src.rgb, outc, strength), 1.0);
}
