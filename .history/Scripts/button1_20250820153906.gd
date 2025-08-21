extends Control

# 导出变量，可在编辑器中调整
@export var button_text : String = "按住我"
@export var holding_text : String = "按住中..."
@export var result_format : String = "你按住了 %.2f 秒"

# 节点引用
@onready var hold_button = $Hold
@onready var result_label =  get_node("Label")

# 计时器变量
var start_time : float = 0.0
var is_holding : bool = false

func _ready():
	# 初始化UI
	hold_button.text = button_text
	result_label.text = "松开后将显示按住的时长..."
	
	# 连接按钮信号
	hold_button.button_down.connect(_on_button_down)
	hold_button.button_up.connect(_on_button_up)
	hold_button.mouse_exited.connect(_on_mouse_exited)

# 按钮按下时
func _on_button_down():
	is_holding = true
	start_time = Time.get_ticks_msec() / 1000.0  # 记录开始时间（秒）
	hold_button.text = holding_text
	result_label.text = "按住中..."

# 按钮松开时
func _on_button_up():
	if is_holding:
		calculate_and_show_duration()

# 鼠标移出按钮区域时
func _on_mouse_exited():
	if is_holding:
		calculate_and_show_duration()

# 计算并显示按住时长
func calculate_and_show_duration():
	is_holding = false
	var end_time = Time.get_ticks_msec() / 1000.0  # 获取结束时间（秒）
	var duration = end_time - start_time  # 计算时长
	
	# 更新UI
	hold_button.text = button_text
	result_label.text = result_format % duration
