shader_type sky;
group_uniforms sun;
uniform vec3 sunColor : source_color = vec3(0.851,0.566,0.282);
uniform float sunAmplify : hint_range(1, 20, 1) = 10.0;
uniform float sunDiameter : hint_range(0.00001,0.00010,0.00001) = 0.00008;
uniform vec3 sunHaloColor : source_color = vec3(0.851);
uniform float sunHaloAmplify : hint_range(0, 20, 0.5) = 10.0;
uniform float sunHaloFalloff : hint_range(128,2048,0.00001) = 1048;
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
group_uniforms rainbow;
uniform float rainbowRadius : hint_range(0.0, 1.0, 0.1) = 0.8;
uniform float rainbowWidth : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float rainbowFalloff : hint_range(1.0, 2048, 0.1) = 128;
uniform float rainbowAmplify : hint_range(0.0, 1.0, 0.1) = 0.2;
//Arctangent threshold macro
#define ATT(INPUT,OFFSET,SHARP) (atan(##SHARP*(##INPUT-(##OFFSET)))/PI+0.5)
// f(x<=0) = 0, f(0<x<=1) = x, f(1<=x) = 1
#define RAMP(INPUT) (step(0, ##INPUT)*##INPUT - step(0, ##INPUT-1.0)*(##INPUT-1.0))
float ramp(float x){
	return (step(0, x)*x - step(0, x-1.0)*(x-1.0));
}
vec3 rainbowColor(float x){
	vec3 result = vec3(0);
	result.r = 1.0-ramp((x-1.0/6.0)*6.0)+ramp((x-4.0/6.0)*6.0);
	result.g = ramp((x)*6.0)-ramp((x-0.5)*6.0);
	result.b = ramp((x-2.0/6.0)*6.0)-ramp((x-5.0/6.0)*6.0);
	return result;
}
float atanRingMask(float input, float center, float width, float sharp){
	return ATT(input+width, center, sharp) - ATT(input-width, center, sharp);
}
void sky() {
	if (!AT_CUBEMAP_PASS){
		COLOR = texture(RADIANCE, EYEDIR).rgb;
	} else if (AT_CUBEMAP_PASS){
		vec3 result = vec3(0.00);
		if(LIGHT0_ENABLED){
			result += dayColor*clamp((LIGHT0_DIRECTION.y+0.7), 0,1);
			//Dawn/dusk color
			result += horizonColor*atanRingMask(LIGHT0_DIRECTION.y, 0, 0.1, 32)*atanRingMask(EYEDIR.y, LIGHT0_DIRECTION.y, 0.4, 8)*max(0,dot(LIGHT0_DIRECTION, EYEDIR)+0.5-EYEDIR.y);
			//Sun disk
			result += sunColor*sunAmplify*step(1.0-sunDiameter, dot(EYEDIR, LIGHT0_DIRECTION))*ATT(LIGHT0_DIRECTION.y, 0.1, 128.0);
			//Sun halo
			result += sunHaloColor*sunHaloAmplify*max(0,pow(dot(EYEDIR, LIGHT0_DIRECTION), sunHaloFalloff))*ATT(LIGHT0_DIRECTION.y, -0.1, 64.0);
			//Sun secondary halo
			result += sunHaloColor*atanRingMask(dot(LIGHT0_DIRECTION, EYEDIR), 0.95, 0.01, 8)*ATT(LIGHT0_DIRECTION.y, -0.1, 64.0);
		}
		if (LIGHT1_ENABLED){
			//Moon disk/halo
			result += nightColor*step(0, LIGHT1_DIRECTION.y)*(LIGHT1_DIRECTION.y)*0.01;
			result += moonColor*step(1.0-moonDiameter, dot(EYEDIR, LIGHT1_DIRECTION))*clamp(LIGHT1_DIRECTION.y+0.3, 0, 1);
			result += moonHaloColor*moonHaloMult*max(0,pow(dot(EYEDIR, LIGHT1_DIRECTION), moonHaloFalloff*(1.0-0.9*max(0, LIGHT1_DIRECTION.y))))*max(0, LIGHT1_DIRECTION.y+0.1);
		}
		if(rainbowAmplify>0.0 || true){
			#define rainbowPos (dot(EYEDIR, vec3(-LIGHT0_DIRECTION.x, LIGHT0_DIRECTION.y, -LIGHT0_DIRECTION.z)))
			#define rainbowMask (ATT(rainbowPos, rainbowRadius-rainbowWidth, 128.0)-ATT(rainbowPos, rainbowRadius, 128.0))
			result += rainbowAmplify*rainbowMask*rainbowColor(1.0-(rainbowRadius-rainbowPos)/rainbowWidth)*atanRingMask(LIGHT0_DIRECTION.y, 0, 0.1, 128.0);
			#undef rainbowPos
			#undef rainbowMask
		}
			
		COLOR = result;
	}
}	
