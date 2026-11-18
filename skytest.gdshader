shader_type sky;
group_uniforms sun;
uniform vec3 sunColor : source_color = vec3(0.851,0.566,0.282);
uniform float sunDiameter : hint_range(0.00001,0.00010,0.00001) = 0.00008;
uniform vec3 sunHaloColor : source_color = vec3(0.851);
uniform float sunHaloFalloff : hint_range(128,2048,0.00001) = 1048;
uniform float sunHaloMult : hint_range(0,1,0.05) = 0.5;
group_uniforms moon;
uniform vec3 moonColor : source_color = vec3(1.0);
uniform float moonDiameter : hint_range(0.00001,0.00010,0.00001)= 0.00007;
uniform vec3 moonHaloColor : source_color = vec3(0.851);
uniform float moonHaloFalloff :  hint_range(128,2048,0.00001) = 512;
uniform float moonHaloMult : hint_range(0,1,0.05) = 0.5;
group_uniforms horizon;
uniform float horizonThreshold : hint_range(0.05, 0.2, 0.01) = 0.2;
uniform float horizonFalloff : hint_range(1.0, 8.0, 0.05) = 4.0;

group_uniforms sky_colors;
uniform vec3 dayColor : source_color = vec3(0.3,0.59,0.79);
uniform vec3 nightColor : source_color = vec3(0.658,0.658,0.658);
uniform vec3 horizonColor : source_color = vec3(0.871, 0.456, 0.18);
group_uniforms gradients;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	vec3 result = vec3(0.01);
	
	result += dayColor*step(0, LIGHT0_DIRECTION.y)*(LIGHT0_DIRECTION.y);
	result += nightColor*step(0, LIGHT1_DIRECTION.y)*(LIGHT1_DIRECTION.y)*0.01;
	result += horizonColor*pow((1.0-abs(LIGHT0_DIRECTION.y)), horizonFalloff);
	
	//Sun disk/halo
	result += sunColor*step(1.0-sunDiameter, dot(EYEDIR, LIGHT0_DIRECTION))*clamp(LIGHT0_DIRECTION.y+0.3, 0, 1);
	result += sunHaloColor*sunHaloMult*max(0,pow(dot(EYEDIR, LIGHT0_DIRECTION), sunHaloFalloff*(1.0-0.9*max(0, LIGHT0_DIRECTION.y))))*max(0, LIGHT0_DIRECTION.y+0.1);
	//Moon disk/halo
	result += moonColor*step(1.0-moonDiameter, dot(EYEDIR, LIGHT1_DIRECTION))*clamp(LIGHT1_DIRECTION.y+0.3, 0, 1);
	result += moonHaloColor*moonHaloMult*max(0,pow(dot(EYEDIR, LIGHT1_DIRECTION), moonHaloFalloff*(1.0-0.9*max(0, LIGHT1_DIRECTION.y))))*max(0, LIGHT1_DIRECTION.y+0.1);
	
	COLOR = result;
}
