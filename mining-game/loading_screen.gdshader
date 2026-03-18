shader_type canvas_item;

uniform float mask_coverage; // Relative to the screen size, 1.0f takes up the whole screen, 0.0f removes mask.
uniform vec2 screen_size;
uniform vec2 player_screen_pos;

void fragment() {
	
	// Find the furthest corner from the player and make that the radius of the mask.
	float radius = 0.0f;
	radius = max(radius, length(player_screen_pos));
	radius = max(radius, distance(player_screen_pos, vec2(screen_size.x, 0.0f)));
	radius = max(radius, distance(player_screen_pos, vec2(0.0f, screen_size.y)));
	radius = max(radius, distance(player_screen_pos, screen_size));
	
	// Apply coverage.
	radius *= mask_coverage;
	
	float alpha = step(radius, distance(player_screen_pos, FRAGCOORD.xy));
	
	COLOR = vec4(0.0f, 0.0f, 0.0f, alpha);
}
