extends Node2D
# 节点引用
@onready var label_1 = get_node("/root/Node2D/Label" )
@onready var label_2 = get_node("/root/Node2D/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var giveup_button = $MenuButton2/GiveUpButton

# 导出变量，可在编辑器中调整
@export var holding_text : String = "按住中..."
@export var result_format : String = "你按住了 %.2f 秒"


var wealth = 0
# 计时器变量
var start_time : float = 0.0
var is_holding : bool = false
var duration 

func _ready():
	label_1.text = "松开后将显示按住的时长..."
	label_2.text = " 你的财富: " + str(wealth)
	# 连接按钮信号
	hold_button.button_down.connect(_on_hold_button_down)
	hold_button.button_up.connect(_on_hold_button_up)
	hold_button.mouse_exited.connect(_on_hold_button_up)
	giveup_button.pressed.connect(_on_giveup_button_pressed)



func _label_refresh(wealth,duration):
	# 更新UI
	label_2.text = " 你的财富: " + str(wealth)
	label_1.text = result_format % duration


# 按钮按下时
func _on_hold_button_down():
	is_holding = true
	start_time = Time.get_ticks_msec() / 1000.0  # 记录开始时间（秒）
	label_1.text = holding_text

# 按钮松开时
func _on_hold_button_up():
	if is_holding:
		calculate_wealth()
		_label_refresh(wealth,duration)


# 计算并显示按住时长
func calculate_wealth():
	is_holding = false
	var end_time = Time.get_ticks_msec() / 1000.0  # 获取结束时间（秒）
	duration = end_time - start_time  # 计算时长
	wealth += duration

func _on_giveup_button_pressed():
	# 尝试切换场景
	get_tree().change_scene_to_file("res://noreward.tscn")
   
