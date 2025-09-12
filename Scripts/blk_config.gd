extends Control

@onready var save_btn =  get_node("/root/Control/VBox/Button")
@onready var vbox = $VBox
@onready var hbox = $HBox
@onready var blk_num_OptionButton = $VBox/OptionButton


var blk_num
var blk_para

func _ready():
	save_btn.pressed.connect(_save_and_start)
	blk_num_OptionButton.item_selected.connect(_update_blk_num)
	blk_para = []
	for i in range(1,21):
		var blk_node_name = "/root/Control/HBox/paraContainer/HBox_BLK%s" % i
		var blk_node = get_node(blk_node_name)
		blk_para.append(blk_node)
	print(blk_para)


func _save_and_start():
	pass


func _update_blk_num(_index):
	var a = []
	a.append (MathUtils.generate_random(3,5,"int")) 
	a.append (MathUtils.generate_random(6,8,"int"))
	a.append (MathUtils.generate_random(9,20,"int"))
	match _index:
		0: # 2
			blk_num = 2 
		1: # 3-5
			blk_num =a[0]
		2: # 6-8
			blk_num = a[1]
		3: # 9-20
			blk_num = a[2]
	print("blk num reset to: ",blk_num)
	for i in range(blk_num,21):
		blk_para[i-1].visible = false
	for i in range(0,blk_num):
		blk_para[i].visible = true
