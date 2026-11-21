#include "res://Assets/Shader/libs/masks.gdshaderinc"
vec3 rainbowColor(float x){
	vec3 result = vec3(0);
	result.r = 1.0-RAMP((x-1.0/6.0)*6.0)+RAMP((x-4.0/6.0)*6.0);
	result.g = RAMP((x)*6.0)-RAMP((x-0.5)*6.0);
	result.b = RAMP((x-2.0/6.0)*6.0)-RAMP((x-5.0/6.0)*6.0);
	return result;
}
