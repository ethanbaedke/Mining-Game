shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 player_pos;
uniform float intensity;

void fragment() {
	
	vec2 uv = SCREEN_UV;
	float time = TIME;
	
	// Time gets offset by our uv.y to create a smooth horizontal shake up and down the screen.
	// Time also needs to be offset based on the player characters y-position in the world so the shake of a
	//  certain row of pixels is not changed as the viewport moves with the camera.
	// Without this, shake speed appears to increase or decrease as the player walks up and down.
	// To do this, we modify the uv.y by the y-size of a pixel in uv coordinates for each pixel the player
	//  has moved down the screen vertically, offsetting our movement.
	time += (uv.y + (SCREEN_PIXEL_SIZE.y * player_pos.y));
	
	// The amount our uv should be modified by on the x-axis for this fragment.
	float delta_x = sin(time * 3.0) * 0.01f * intensity;
	
	// We should ensure that fragments near the edges of the screen don't move at all since fragments outside
	//  the bounds of the screen are never rendered (creates straight lines)
	// Here, we make the shake approach zero as we get closer to the left and right sides of the screen.
	float edge_distance_multiplier = -pow((uv.x - 0.5f) * 2.0f, 2.0f) + 1.0f;
	uv.x += (delta_x * edge_distance_multiplier);
	
	COLOR = textureLod(screen_texture, uv, 0.0);
}
