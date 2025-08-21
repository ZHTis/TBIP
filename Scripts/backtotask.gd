extends Node2D

# 场景加载完成后自动开始计时
func _ready():
	# 等待1秒后执行场景切换
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://main.tscn")
	
