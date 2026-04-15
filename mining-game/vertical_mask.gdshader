shader_type canvas_item;

uniform sampler2D tex: filter_nearest;
uniform float percent;

void fragment() {
	
	vec4 col = texture(tex, UV);
	
	col.a *= step(1.0f - percent, UV.y);
	
	COLOR = col;
}
