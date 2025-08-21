extends Button

# 上半部分文字的配置
export var text_content : String = "按钮文字"  # 文字内容

func _ready():
    pass

# 对外提供修改属性的方法
func set_text(new_text: String):
    text_content = new_text
    # 更新按钮文字
    self.text = new_text    
 