shader_type canvas_item;
uniform float glitch_x: hint_range(0.0, 1.0, 0.01);
uniform float glitch_y: hint_range(0.0, 1.0, 0.01);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	COLOR.r = texture(screen_texture,SCREEN_UV - vec2(glitch_x/100.0,glitch_y/100.0)).r;
	COLOR.g = texture(screen_texture,SCREEN_UV).g;
	COLOR.b = texture(screen_texture,SCREEN_UV + vec2(glitch_x/100.0,glitch_y/100.0)).b;
}
