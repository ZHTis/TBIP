extends MenuButton


func _ready():
    # Called when the node is added to the scene.
    # Initialization here
    self.pressed.connect(_on_Button_pressed)



# 当按钮被按下时调用
func _on_Button_pressed():

    get_tree().change_scene_to_file("res://noreward.tscn")
