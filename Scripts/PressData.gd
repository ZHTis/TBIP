
class_name PressData
extends RefCounted  # 使用RefCounted以便安全地传递和存储

var timestamp: float  # 按键的时间戳（秒）
var rwd_marker: bool
# 示例：用枚举限制按键类型（只能是以下值）
enum BtnType {HOLD, OPT_OUT, INVALID, WAIT }
var btn_type_marker: BtnType  
var trial_count :int
var press_count :int
var if_opt_left


# 构造函数：参数需覆盖所有要初始化的变量（新增 btn_type 参数）
func _init(new_timestamp: float, new_trial_count:int, new_rwd_marker: Variant, new_btn_type_marker: Variant, _press_count: int) -> void:
	press_count = _press_count
	timestamp = new_timestamp
	trial_count = new_trial_count
	rwd_marker = new_rwd_marker  # 对应 rwd_marker 变量
	btn_type_marker = new_btn_type_marker  # 对应 btn_type_marker 变量
 
