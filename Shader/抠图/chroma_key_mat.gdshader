shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float smoothness : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	// 左边裁约 2%，底边裁约 2%（可按需要改数字）
	if (UV.x < 0.02 || UV.y > 0.98) {
		COLOR = vec4(0.0);
	} else {
		vec4 col = texture(TEXTURE, UV);
		float dist = distance(col.rgb, key_color);
		float alpha = smoothstep(threshold, threshold + smoothness, dist);
		COLOR = vec4(col.rgb, col.a * alpha);
	}
}