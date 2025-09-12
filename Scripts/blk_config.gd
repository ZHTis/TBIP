extends Control

@onready var save_btn = get_node("/root/Control/VBox/Button")
@onready var vbox = $VBox
@onready var hbox = $HBox
@onready var blk_num_OptionButton = $VBox/OptionButton


var blk_num
var BLKs_para_nodes

func _ready():
	save_btn.pressed.connect(_save_and_start)
	blk_num_OptionButton.allow_reselect = true
	blk_num_OptionButton.item_selected.connect(_update_blk_num)
	BLKs_para_nodes = []
	for i in range(1, 21):
		var blk_node_name = "/root/Control/HBox/paraContainer/HBox_BLK%s" % i
		var blk_node = get_node(blk_node_name)
		BLKs_para_nodes.append(blk_node)
		if i > 1:
			BLKs_para_nodes[i - 1].visible = false


func _save_and_start():
	if blk_num == null:
		print("blk_num is null")
		return
	for i in range(0, blk_num):
		var blk_para_node = BLKs_para_nodes[i].get_child(1).get_child(1)
		print(blk_para_node.name)
		var blk_para = BLKPara.new()


func _update_blk_num(_index):
	var a = []
	a.append(MathUtils.generate_random(3, 5, "int"))
	a.append(MathUtils.generate_random(6, 8, "int"))
	a.append(MathUtils.generate_random(9, 20, "int"))
	match _index:
		0: # 2
			blk_num = 2
		1: # 3-5
			blk_num = a[0]
		2: # 6-8
			blk_num = a[1]
		3: # 9-20
			blk_num = a[2]
	print("blk num reset to: ", blk_num)
	for i in range(blk_num, 21):
		BLKs_para_nodes[i - 1].visible = false
	for i in range(0, blk_num):
		BLKs_para_nodes[i].visible = true
