shader_type canvas_item;

uniform vec2 region_size;

void fragment() {
	
	// Attempt #1
	/*
	// Base wave to be used inside step.
	float wave = sin((TIME * 10.0) + UV.x + UV.y) + 1.0f;
	
	float edge_dist = UV.x;
	edge_dist = min(edge_dist, region_size.x - UV.x);
	edge_dist = min(edge_dist, UV.y);
	edge_dist = min(edge_dist, region_size.y - UV.y);
	
	float alpha = step(wave, edge_dist);
	*/
	
	// Attempt #2
	
	// We calculate the point on the edge of the texture that intersects the ray pointing from the center of the texture to the fragment we're on.
	// We then calculate the distance from our fragment to that edge coordinate.
	// Finally, we run the distance through a sine distance field to create a wave effect around the border of our texture.bool
	
	vec2 center = region_size * 0.5f;
	
	// UV is not 0->1 here since we're using a region on our texture. Instead, it ranges the size of the region.
	vec2 frag_coord = UV;
	
	vec2 ray = frag_coord - center;
	
	// Here, we test against all sides of our texture and find the multiplier that expands the ray to hit the edge it points towards.
	float left_edge_mult = -center.x / ray.x;
	left_edge_mult = mix(left_edge_mult, 1e20, step(left_edge_mult, 0.0));
	float right_edge_mult = (region_size.x - center.x) / ray.x;
	right_edge_mult = mix(right_edge_mult, 1e20, step(right_edge_mult, 0.0));
	float bottom_edge_mult = -center.y / ray.y;
	bottom_edge_mult = mix(bottom_edge_mult, 1e20, step(bottom_edge_mult, 0.0));
	float top_edge_mult = (region_size.y - center.y) / ray.y;
	top_edge_mult = mix(top_edge_mult, 1e20, step(top_edge_mult, 0.0));
	float edge_mult = min(left_edge_mult, min(right_edge_mult, min(bottom_edge_mult, top_edge_mult)));
	
	vec2 edge_point = center + (ray * edge_mult);
	
	// Finally, we have the distance from our fragment to the point on the edge of the texture (which intersects the ray drawn from the center through the fragment).
	float dist = length(edge_point - frag_coord);
	
	// TODO: Take a look at this wave function later.
	float wave = (sin((TIME * 8.0f) + UV.x + UV.y) * 0.5f) + 0.5f + sin(TIME * 3.0f) + 1.0f;
	
	float alpha = step(wave, dist);
	
	COLOR = vec4(0.0f, 0.0f, 0.0f, alpha);
	
}
