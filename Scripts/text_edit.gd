extends Control


@onready var input_cell = get_node("/root/Control/VBox/LineEdit")
@onready var save_btn =  get_node("/root/Control/btnBox/Label/Button")
@onready var vbox = $VBox
@onready var btnBox = get_node("/root/Control/btnBox")
@onready var speed_up_mode_checkbox = get_node("/root/Control/VBox/HBoxContainer/CheckButton")
@onready var auto_mode_checkbox = get_node("/root/Control/VBox/HBoxContainer2/CheckButton2")
var subject_name

func _ready():
	Global.iftextEditHasAppear = true	
	init_ui()
	save_btn.pressed.connect(_save_text)
	speed_up_mode_checkbox.toggled.connect(_on_speed_up_mode_toggled)
	auto_mode_checkbox.toggled.connect(_on_auto_mode_toggled)

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

func _on_speed_up_mode_toggled(state):
	Global.speed_up_mode = state

func _on_auto_mode_toggled(state):	
	Global.auto_mode = 	state

func init_ui():
	var window_size = get_viewport_rect().size
	Utils.setup_layout(btnBox,Control.PRESET_CENTER, 0.5,0.75, window_size)
	Utils.setup_layout(vbox,PRESET_CENTER, 0.5,0.25, window_size)
