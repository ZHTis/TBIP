extends Node2D

@onready var label2 = $Label2

func _ready():
	# 初始化UI
	label2.text = " 你的财富: 0"

func _laber2_refresh(wealth):
	# 更新UI
	label2.text = " 你的财富: " + str(wealth)

func _wealth_change_signal():
	# 处理信号
	wealth += 1
	_laber2_refresh()
