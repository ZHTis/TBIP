extends Button

# 上半部分文字的配置
export var text_content : String = "按钮文字"  # 文字内容

func _ready():
    # 初始化按钮布局
    _setup_layout()
    # 初始化文字
    set_text(text_content)
    self.pressed.connect(_on_button_pressed)




func _setup_layout():
    # 设置按钮的对齐方式
    align = ALIGN_LEFT
    valign = VALIGN_TOP
    

# 对外提供修改属性的方法
func set_text(new_text: String):
    text_content = new_text
    # 更新按钮文字
    self.text = new_text    
