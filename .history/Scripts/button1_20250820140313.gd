extends Button


# 连接按钮的 pressed 信号到处理函数
func _ready():
	self.pressed.connect(_on_button_pressed)
	
# 当按钮被按下时调用
func _on_button_pressed():
	# 加载并切换到目标场景
	getreward()
	
func getreward():
	get_tree().change_scene_to_file("res://reward.tscn")
