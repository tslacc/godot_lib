class_name SystemTime extends RefCounted

const DAYSECONDS : int = 60*60*24;
## Estimated axial tilt
const AXIALTILT : float = 23.5*PI/180;
## Summer solstice
const SOLSTICE : float = 172.5;
## Number of seconds passed during the current day
static var seconds : float = 0;
static var ClockNode : ClockNodeClass;

static func global_init() -> void:
	seconds = fmod(Time.get_unix_time_from_system(), DAYSECONDS);
	ClockNode = ClockNodeClass.new();
	ClockNode.name = "SystemTimeNode";
	ClockNode.process_mode = Node.PROCESS_MODE_ALWAYS;
	GlobalControl.root.add_child.call_deferred(ClockNode);
	for i : int in 200:
		print(dayRatio(PI/180*23.5, -PI/2+PI/200*i))
	for i : int in 3:
		print(i)
static func timeAsArray() -> PackedInt32Array:
	var result : PackedInt32Array = []
	result.resize(3);
	@warning_ignore("narrowing_conversion")
	result[2] = fmod((seconds as int), 60.0);
	result[1] = floor(fmod(seconds, (60.0*60))/60.0);
	result[0] = floor(seconds/(60.0*60));
	return result;
## Return the azimuth adjustment based on the day of year.
## https://en.wikipedia.org/wiki/Position_of_the_Sun
## Approximated with a sine wave: not accurate to real life!
static func azimuthAngleAdjustByDate(dayOfYear : float)->float:
	var result : float = cos(2*PI*(dayOfYear-SOLSTICE)/365)*AXIALTILT;
	return result;
## Definitions all in radians.
## Azimuth is the longitudinal angle
## Attitude is the latitude angle
## Let a be [param axialTilt] in radians from the pole; let axial tilt of the north pole towards the sun be positive
## Let l be [param latitude] in radians from the horizon
## Let x be in the plane normal towards the sun
## Let y be in the direction towards the Sun
## Let z be the cross product of x,y
## z = sin(l)
## y = min(1, tan(a)*z)
## x = sqrt(a-y^2-z^2)
## b = atan(x/y)
## Adjust for the value by adding pi to negative values of b
## r = b/pi
## Return the ratio as 0 : full night, 1 : full day, greater than 1 = full(er)day
static func dayRatio(axialTilt: float, latitude : float)->float:
	if(abs(latitude)>=abs(PI/2-axialTilt)):
		if(sign(latitude)==sign(axialTilt)):
			return 1;
		return 0;
	var z : float= sin(latitude);
	var y : float = max(-1,min(1, tan(-axialTilt)*z));
	if(is_zero_approx(y)):
		return 0.5;
	var x : float = sqrt(1-pow(y,2)-pow(z,2));
	var b : float = atan(x/y);
	if(b<0): 
		b+=PI;
	return b/PI;

## Let [param ratio] be the amount of daylight in the day
static func dawnDuskOffset(ratio : float)->float:
	return 12-12*ratio;
## Returns the proportion of the current ?? body light
## If it is daytime, return the amount of sun
## If it is nighttime, return the amount of night 
## Let [param time] be the time as a float, i.e. 1.5 would be 01:30 AM
## Let [param ratio] be the day ratio
## As always, assume a 24-hour day.
static func getLightProportion(time : float, ratio : float)->float:
	var offset:float = dawnDuskOffset(ratio);
	if (time < 12-offset || 12+offset < time):
		if (12+offset < time):
			time = 24 - time;
		return (cos(2*PI*time/(48*(1-ratio))))
	else:
		## 0.5 magic constant to make daylight notably stronger the longer the day.
		## 12 centers the daylight on noon.
		return (ratio+0.5)*(cos(2*PI*(time-12)/(48*ratio)));

## Get the POSITION of the sun based on tilt, time, and latitude.
static func getSunPosition(axialTilt : float, latitude :float, time : float)->Vector3:
	var axisDir : Vector3 = Vector3.FORWARD.rotated(Vector3.LEFT, axialTilt)
	var result : Vector3 = Vector3.DOWN.rotated(Vector3.LEFT, axialTilt+latitude);
	return result.rotated(axisDir, fmod(-2*PI/24*time, 2*PI));
## Get the rotation of the sun. Make sure the DirectionalLight is in ZXY order (or ensure Z is processed first)
static func getSunRotation(axialTilt : float, latitude :float, time : float)->Vector3:
	var vec : Vector3 = getSunPosition(axialTilt, latitude, time);
	var result : Vector3 = Vector3(-asin(vec[1]), atan2(vec[0],vec[2]), 0)
	return result
## Directly compute light power 
##TODO Fix so that it isn't black at low angles.
static func getLightPower(angle : Vector3)->float:
	return (angle+Vector3(0,+1,0)).dot(Vector3.UP);
	
class ClockNodeClass extends Node:
	func _process(delta: float) -> void:
		SystemTime.seconds+=delta;
		while(SystemTime.seconds>SystemTime.DAYSECONDS):
			SystemTime.seconds-=SystemTime.DAYSECONDS;
