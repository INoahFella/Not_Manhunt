float get_noise(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float get_dither_2x2(vec2 position) {
	int x = int(mod(position.x, 2.0));
	int y = int(mod(position.y, 2.0));
	int index = x + y * 2;
	float bayer[4] = float[](0.0, 0.5, 0.75, 0.25);
	return bayer[index];
}

float get_dither_4x4(vec2 position) {
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
	int index = x + y * 4;
	float bayer[16] = float[](
		0.0 / 16.0, 8.0 / 16.0, 2.0 / 16.0, 10.0 / 16.0,
		12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0, 6.0 / 16.0,
		3.0 / 16.0, 11.0 / 16.0, 1.0 / 16.0, 9.0 / 16.0,
		15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0, 5.0 / 16.0
	);
	return bayer[index];
}

float get_grain_mask(float luminance, float threshold) {
	return pow(1.0 - clamp(luminance / threshold, 0.0, 1.0), 3.0);
}

vec3 apply_grain(vec3 color, vec2 uv, float time, float intensity, float mask) {
	float noise = get_noise(uv + vec2(time));
	return color + ((noise - 0.5) * intensity * mask);
}