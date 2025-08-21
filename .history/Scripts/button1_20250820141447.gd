extends Button

# 上半部分文字的配置
export var text_content : String = "按钮文字"  # 文字内容

func _ready():
    # 初始化按钮布局
    _setup_layout()
    # 初始化文字
    self.text = $2
	self.pressed.connect(_on_button_pressed)



# 当按钮被按下时调用
func _on_button_pressed():
	# 加载并切换到目标场景
	getreward()
	
func getreward():
	get_tree().change_scene_to_file("res://reward.tscn")
extends Button



func _setup_layout():
    # 设置按钮整体大小
    rect_min_size = Vector2(150, 120)  # 宽150，高120（上半40+下半80）
    # 禁用按钮自带的文本居中，改为手动布局
    align = ALIGN_LEFT
    valign = VALIGN_TOP
    self.set_custom_minimum_size(rect_min_size)
    self.set_align(align)
    self.set_valign(valign)


# 对外提供修改属性的方法
func set_text(new_text: String):
    text_content = new_text
    self.text = new_text
