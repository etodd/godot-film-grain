#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	float grain_amount;
	float time;
} params;

// Generate time-sensitive random numbers between 0 and 1.
float rand(vec2 seed, float time)
{
    float x = (seed.x / 3.14159 + 4) * (seed.y / 5.49382 + 4) * (time + 1);
    return mod((mod(x, 13) + 1) * (mod(x, 123) + 1), 0.01) - 0.005;
}

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	// Prevent reading/writing out of bounds.
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	// Read from our color buffer.
	vec4 color = imageLoad(color_image, uv);

	// Generate random noise
	float noise = rand(mod(gl_GlobalInvocationID.xy, vec2(1024.0, 1024.0)), params.time);

	// Add noise to the original color
    color.rgb += noise * params.grain_amount;

	// Write back to our color buffer.
	imageStore(color_image, uv, clamp(color, 0.0, 1.0));
}
