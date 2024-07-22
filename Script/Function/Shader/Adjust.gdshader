shader_type canvas_item;
uniform float contrast : hint_range(0.0, 5.0, 0.1);
uniform float brightness : hint_range(0.0, 5.0, 0.1);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	vec3 color = texture(TEXTURE,UV,0.0).rgb;
	color.rgb = mix(vec3(0.5),color.rgb,contrast);
	color.rgb = mix(vec3(0.0),color.rgb,brightness);
	vec4 screen = texture(screen_texture,SCREEN_UV);
	COLOR.rgb = screen.rgb * color;
}
