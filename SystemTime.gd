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
## Return the ratio as 0 : full night, 1 : full day
static func dayRatio(axialTilt: float, latitude : float)->float:
	if(abs(latitude)>=abs(PI/2-axialTilt)):
		if(sign(latitude)==sign(axialTilt)):
			return 1;
		return 0;
	var z : float= sin(latitude);
	var y : float = min(1, tan(-axialTilt)*z);
	if(is_zero_approx(y)):
		return 0.5;
	var x : float = sqrt(1-pow(y,2)-pow(z,2));
	var b : float = atan(x/y);
	if(b<0): 
		b+=PI;
	return b/PI;
class ClockNodeClass extends Node:
	func _process(delta: float) -> void:
		SystemTime.seconds+=delta;
		while(SystemTime.seconds>SystemTime.DAYSECONDS):
			SystemTime.seconds-=SystemTime.DAYSECONDS;
