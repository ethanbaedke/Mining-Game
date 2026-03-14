shader_type canvas_item;

uniform float mask_coverage; // Relative to the screen size, 1.0f takes up the whole screen, 0.0f removes mask.
uniform float screen_width;
uniform float screen_height;

void fragment() {

	// nc = normalized-centered
	vec2 nc_coords = UV - vec2(0.5f, 0.5f);
	float aspect = screen_width / screen_height;
	nc_coords.x *= aspect;

	// The larger the aspect ratio (difference between width/height) the greater radius we need to cover
	//  the whole screen. Corner radius calculates this so our mask coverage can always go from 0-1.
	float corner_radius = length(vec2(aspect * 0.5f, 0.5f));
	
	float alpha = step(mask_coverage * corner_radius, length(nc_coords));

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
