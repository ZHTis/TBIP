
class_name PressData
extends RefCounted  # Use RefCounted for safe delivery and storage

var timestamp: float  # Key press timestamp (seconds)
var btn_type_marker
var press_count :int


#Constructor: parameters must cover all variables to be initialized (new btn_type parameter)
func _init(new_timestamp: float,  new_btn_type_marker: Variant, _press_count:Variant) -> void:
	press_count = _press_count
	timestamp = new_timestamp
	btn_type_marker = new_btn_type_marker  # Corresponds to btn_type_marker variable

func to_array() -> Array:
	return [
		timestamp,
		btn_type_marker,
		press_count
		]
