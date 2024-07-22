shader_type canvas_item;

uniform vec4 color: source_color;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	vec4 screen = texture(screen_texture,SCREEN_UV);
	COLOR.rgb = screen.rgb + color.rgb;
}
