extends Button


func _ready():
	self.pressed.connect(_on_button2_pressed)


# 当按钮被按下时调用
func _on_button2_pressed():
	get_tree().change_scene_to_file("res://noreward.tscn")
