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
	Global.blks_para = []
	if blk_num == null:
		print("blk_num is null")
		return
	for i in range(0, blk_num):
		var blk_para = BLKPara.new()
		blk_para.blk = "blk" + str(i + 1)
		# process the child nodes of BLKs_para_nodes[i],
		var blk_para_node_root = BLKs_para_nodes[i]
		var node_length = blk_para_node_root.get_child_count()
		for j in range(1, node_length):
			var input_cell = blk_para_node_root.get_child(j)
			input_cell_to_config(input_cell.name, input_cell.get_child(1), blk_para)

		# print("blk_para: ", blk_para.blk, "\t",
		# blk_para.change, "\t", blk_para.chance_list, blk_para.distr_type,
		# blk_para.distr_para_1, blk_para.distr_para_2, 
		# blk_para.h_value_list, blk_para.o_value_list, blk_para.tr_num_range)
		Global.blks_para.append(blk_para)
	
	print("blks_para: ", Global.blks_para[1].blk, "\n", Global.blks_para[1].chance_list, "\n")
		


func input_cell_to_config(input_cell_name,_input_cell,_blk_para):
	match input_cell_name:
		"blkPara_change_distr_or_chance":
			if _blk_para.blk == "blk1":
				pass
			elif _input_cell.selected == 0:
				_blk_para.change = "chance"
			elif _input_cell.selected == 1:
				_blk_para.change = "distr"
			elif _input_cell.selected == 2:
				_blk_para.change = "random"
		"blkPara_distr_type":
			if  _input_cell.selected == 0:
				_blk_para.distr_type = "NROM"
			if  _input_cell.selected == 1:
				_blk_para.distr_type = "FLAT"
		"blkPara_distr_para_1":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.distr_para_1 = Utils.parse_numeric_array(_input_cell.text) 
		"blkPara_distr_para_2":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.distr_para_2 = Utils.parse_numeric_array(_input_cell.text)
		"blkPara_chance":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.chance_list = Utils.parse_numeric_array(_input_cell.text)
		"blkPara_value_list":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.h_value_list = Utils.parse_numeric_array(_input_cell.text)
		"blkPara_value_list2":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.o_value_list = Utils.parse_numeric_array(_input_cell.text)
		"blkPara_tr_num_num_range":
			if _input_cell.text == "" or _input_cell.text == null:
				return
			else:
				_blk_para.tr_num_range = Utils.parse_numeric_array(_input_cell.text)



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
