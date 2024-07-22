shader_type canvas_item;
render_mode unshaded;

uniform sampler2D curve;
uniform float force;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 vecToCenter = vec2(0.5,0.5) - UV;
	float distToCenter = length(vecToCenter);
	float curveVal = texture(curve,vec2(distToCenter)).r;
	vec2 diff = normalize(vecToCenter) * 0.6 * curveVal;
	COLOR.rgb = texture(screen_texture,SCREEN_UV - diff).rgb;
}
