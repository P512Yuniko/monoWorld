shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	vec2 distortUV = SCREEN_UV + texture(TEXTURE, UV).a * 0.01;
	vec4 screen_col = texture(screen_texture,distortUV);
	COLOR.rgb = screen_col.rgb;
}