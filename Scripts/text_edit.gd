extends Control


@onready var input_cell = get_node("/root/Control/VBox/LineEdit")
@onready var save_btn = $Button
var subject_name

func _ready():
	Global.iftextEditHasAppear = true	
	save_btn.pressed.connect(_save_text)

func _save_text():
	# 获取文本并去空格
	var content = input_cell.text
	
	# Godot 4 正确的空字符串检查方式
	if content == '':
		subject_name = "default_name"
	else:
		subject_name = content
	
	Global.subject_name = subject_name
	get_tree().change_scene_to_file("res://main.tscn")
