extends Control

@onready var start_btn = get_node("/root/Control/VBox/HBox/Button")
@onready var save_btn = get_node("/root/Control/VBox/HBox/Button2")
@onready var vbox = $VBox
@onready var hbox = $HBox
@onready var blk_num_OptionButton = $VBox/OptionButton
@onready var tp_checkbutton = $VBox/HBoxContainer/CheckButton

var blk_num
var BLKs_para_nodes
var configuration
var user_path = ProjectSettings.globalize_path("user://")
var path = user_path + "task_config.cfg"

func _ready():
	configuration = ConfigFile.new()
	
	start_btn.pressed.connect(_save_and_start)
	save_btn.pressed.connect(_save)
	blk_num_OptionButton.allow_reselect = true
	blk_num_OptionButton.item_selected.connect(_update_blk_num)
	tp_checkbutton.toggled.connect(_on_check)
	tp_checkbutton.toggled.emit(false)

	BLKs_para_nodes = []
	for i in range(1, 21):
		var blk_node_name = "/root/Control/HBox/paraContainer/HBox_BLK%s" % i
		var blk_node = get_node(blk_node_name)
		BLKs_para_nodes.append(blk_node)
		if i > 1:
			BLKs_para_nodes[i - 1].visible = false
	load_states()


func _on_check(_toggled):
	if _toggled == true:
		Global.inference_type = Global.InferenceFlagType.press_based
	if _toggled ==false:
		Global.inference_type = Global.InferenceFlagType.time_based
	print("inference type: ", Global.inference_type)

	
func _save():
	if blk_num == null:
		print("blk_num is null")
		return
	for i in range(0, blk_num):
		var blk_para = BLKPara.new()
		blk_para.blk = "blk" + str(i + 1)
		# process the child nodes of BLKs_para_nodes[i],
		var blk_para_node_root = BLKs_para_nodes[i]
		var node_length = blk_para_node_root.get_child_count()

		for j in range(1, node_length+1):
			if blk_para_node_root.get_children().size() > j:
				var input_cell = blk_para_node_root.get_child(j)
				if i>1 and input_cell.get_child(1) is LineEdit:
					if input_cell.get_child(1).text == "":
						input_cell.get_child(1).text = BLKs_para_nodes[i-1].get_child(j).get_child(1).text
				if i>1 and input_cell.get_child(1) is OptionButton:
					if input_cell.get_child(1).selected ==  -1:
						input_cell.get_child(1).selected = BLKs_para_nodes[i-1].get_child(j).get_child(1).selected

				input_cell_to_config(input_cell.name, input_cell.get_child(1), blk_para)
				if input_cell.name == "blkPara_change_distr_or_chance" or input_cell.name == "blkPara_distr_type":
					configuration.set_value(blk_para.blk, input_cell.name, input_cell.get_child(1).selected)
				else:
					configuration.set_value(blk_para.blk, input_cell.name, input_cell.get_child(1).text)

		# print("blk_para: ", blk_para.blk, "\t",
		# blk_para.change, "\t", blk_para.chance_list, blk_para.distr_type,
		# blk_para.distr_para_1, blk_para.distr_para_2, 
		# blk_para.h_value_list, blk_para.o_value_list, blk_para.tr_num_range)
	
	if blk_num < configuration.get_sections().size():
		for i in range(blk_num, configuration.get_sections().size()):
			var _blk = "blk" + str(i + 1)
			configuration.erase_section(_blk)
	configuration.save(path)

func _save_and_start():
	_save()
	get_tree().change_scene_to_file("res://textEdit.tscn")


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
			elif _input_cell.selected == 3:
				_blk_para.change = "chance(allow repeat)"
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



func load_states():
	print("error: 	",configuration.load(path))
	if configuration.load(path) != 0:
		return
	for blk in configuration.get_sections():
		var i = int(blk.replace("blk", "")) - 1
		var blk_para_node_root = BLKs_para_nodes[i]

		var node_length = configuration.get_section_keys(blk).size()
		for j in range(1,node_length+1):
			if blk_para_node_root.get_children().size() > j:
				var input_cell = blk_para_node_root.get_child(j)#.get_child(1)
			
				var value = configuration.get_value(blk, input_cell.name)
				var input_cell_edit = input_cell.get_child(1)
				if input_cell_edit is LineEdit:
					input_cell_edit.text = value
				elif input_cell_edit is OptionButton:
					input_cell_edit.selected = int(value)




func _update_blk_num(_index):
	var a = []
	a.append(MathUtils.generate_random(3, 5, "int"))
	a.append(MathUtils.generate_random(6, 8, "int"))
	a.append(MathUtils.generate_random(9, 20, "int"))
	match _index:
		0: # 2
			blk_num = 2
		1:
			blk_num = 4
		2:
			blk_num = 8
		3:
			blk_num = 12
		4: # 3-5
			blk_num = a[0]
		5: # 6-8
			blk_num = a[1]
		6: # 9-20
			blk_num = a[2]
	print("blk num reset to: ", blk_num)
	for i in range(blk_num, 21):
		BLKs_para_nodes[i - 1].visible = false
	for i in range(0, blk_num):
		BLKs_para_nodes[i].visible = true
