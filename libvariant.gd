@abstract
## Defines [Variants] with default values
class_name libvariant extends RefCounted;
enum{
	INTEGER,
	FLOAT,
	BOOL
}
@abstract func restoreDefault() -> void;
@abstract func getValue() -> Variant;
@abstract func setValue(val : Variant) -> void;
@abstract func deepCopy() -> libvariant;

@abstract class RangeNumeric extends libvariant:
	var domain : Range = Range.new();
	## assign [member domain]'s properties from dictionary
	func assignDomainPropertiesFromDict(dict : Dictionary) -> void:
		for k : StringName in dict.keys():
			if k in domain:
				domain.set(k, dict.get(k));
## Defines an [int] with a default value
class RangeInteger extends RangeNumeric:
	var default : int;
	func _init(d : int)->void:
		default = d;
		domain.value = d;
	func restoreDefault() -> void:
		domain.value = default;
	func getValue() -> Variant:
		return domain.value as int;
	func setValue(val : Variant) -> void:
		domain.value = val as int;
	func deepCopy() -> RangeInteger:
		var result : RangeInteger = RangeInteger.new(default);
		libvariant.RangeMirrorProperties(result.domain, self.domain);
		result.domain.value = self.domain.value;
		return result;
		
## Defines a [float] with a default value
class RangeFloat extends RangeNumeric:
	var default : float;
	func _init(d : float)->void:
		default = d;
		domain.value = d;
	func restoreDefault() -> void:
		domain.value = default;
	func getValue() -> Variant:
		return domain.value;
	func setValue(val : Variant) -> void:
		domain.value = val;
	func deepCopy() -> RangeFloat:
		var result : RangeFloat = RangeFloat.new(default);
		libvariant.RangeMirrorProperties(result.domain, self.domain);
		result.domain.value = self.domain.value;
		return result;

## Defines a [bool] with a default value.
class Bool extends libvariant:
	var value : bool = false;
	var default : bool = false;
	func _init(d : int)->void:
		default = d;
		value = d;
	func restoreDefault() -> void:
		value = default;
	func getValue() -> Variant:
		return value;
	func setValue(val : Variant) -> void:
		value = val as bool;
		return;
	func deepCopy() -> Bool:
		var result : Bool = Bool.new(default);
		result.value = value;
		return result;
		
static func RangeMirrorProperties(dest : Range, src : Range) -> void:
	dest.allow_greater = src.allow_greater;
	dest.allow_lesser = src.allow_lesser;
	dest.exp_edit = src.exp_edit;
	dest.max_value = src.max_value;
	dest.min_value = src.min_value;
	dest.page = src.page;
	dest.ratio = src.ratio;
	dest.rounded = src.rounded;
	dest.step = src.step;
