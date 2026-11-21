#ifndef DEF_MASKS
#define DEF_MASKS
//Arctangent threshold macro
#define ATT(INPUT,OFFSET,SHARP) (atan(##SHARP*(##INPUT-(##OFFSET)))/PI+0.5)
// f(x<=0) = 0, f(0<x<=1) = x, f(1<=x) = 1
#define RAMP(INPUT) (step(0, ##INPUT)*##INPUT - step(0, ##INPUT-1.0)*(##INPUT-1.0))

float atanRingMask(float input, float center, float width, float sharp){
	return ATT(input+width, center, sharp) - ATT(input-width, center, sharp);
}
#endif
