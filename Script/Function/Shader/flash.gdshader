shader_type canvas_item;
uniform vec4 color: source_color;
render_mode unshaded;
void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
	texture_color.rgb = mix(texture_color.rgb, color.rgb, 1);
    COLOR.rgb = COLOR.rgb + texture_color.rgb;
}
