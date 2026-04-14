shader_type canvas_item;

const float TEST_ASPECT = 1920.0 / 1080.0; // For correct visualization in the editor.

uniform float mask_coverage; // Relative to the screen size, 1.0f takes up the whole screen, 0.0f removes mask.
uniform vec2 player_uv;

void fragment() {
	
	// OLD
	/*
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
	*/
	
	// NEW
	//float aspect = TEST_ASPECT;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 uv_scaled = vec2(UV.x * aspect, UV.y);
	vec2 player_uv_scaled = vec2(player_uv.x * aspect, player_uv.y);
	
	// Find the furthest corner from the player and make that the radius of the mask.
	float radius = 0.0f;
	radius = max(radius, length(player_uv_scaled));
	radius = max(radius, distance(player_uv_scaled, vec2(aspect, 0.0)));
	radius = max(radius, distance(player_uv_scaled, vec2(0.0, 1.0)));
	radius = max(radius, distance(player_uv_scaled, vec2(aspect, 1.0)));
	
	// Apply coverage.
	radius *= mask_coverage;
	
	float alpha = step(radius, distance(player_uv_scaled, uv_scaled));
	
	COLOR = vec4(0.0f, 0.0f, 0.0f, alpha);
}
