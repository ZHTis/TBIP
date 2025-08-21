extends Node2D

@onready var label2 = $Label2
var wealth = 0

func _ready():
	# 初始化UI
	label2.text = " 你的财富: " + str(wealth)

func _laber2_refresh(wealth):
	# 更新UI
	label2.text = " 你的财富: " + str(wealth)

func _wealth_change_signal(bool: signal):
	# send wealth change signal
    if signal:
        var wealth = 
    else:
        pass

func process(delta):
    _laber2_refresh()
