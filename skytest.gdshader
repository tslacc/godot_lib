shader_type sky;
uniform vec3 dayColor : source_color = vec3(0.3,0.59,0.79);
uniform vec3 nightColor : source_color = vec3(0.31,0.28,0.28);
void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	//COLOR = dayColor;
	COLOR = dayColor*(0.5+EYEDIR.y)+nightColor;
	const float threshold = cos(PI/180.0*1.0);
	COLOR += step(threshold, dot(EYEDIR, LIGHT0_DIRECTION));
	const float th = 0.1;
	//COLOR.r = EYEDIR.y;
	//COLOR.r = SKY_COORDS.x;
	//COLOR.g = SKY_COORDS.y;
}
