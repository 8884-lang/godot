shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 16.0) = 1.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;

	float a = col.a;
	float outline = 0.0;

	// 8 方向采样：周围有不透明像素就描边
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2( px.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0,  px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2( px.x, -px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x,  px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2( px.x,  px.y)).a);

	// 自己透明、旁边不透明 → 描边
	if (a < alpha_threshold && outline > alpha_threshold) {
		COLOR = outline_color;
	} else {
		COLOR = col;
	}
}
