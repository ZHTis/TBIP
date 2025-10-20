extends HBoxContainer

@onready var label_blkPara_distr_para_1 = $blkPara_distr_para_1/Label
@onready var label_blkPara_distr_para_2 = $blkPara_distr_para_2/Label
@onready var distrType_optionButton = $blkPara_distr_type/OptionButton
@onready var change_optionButton = $blkPara_change_distr_or_chance/OptionButton
@onready var vbox1 = $blkPara_distr_type
@onready var vbox2 = $blkPara_distr_para_1
@onready var vbox3 = $blkPara_distr_para_2
@onready var vbox4 = $blkPara_chance

var exclude_list

func _ready():#                 len as [0,0.7,0.8,0.9,0.95,0.75] 
	label_blkPara_distr_para_1.text = "                        "
	label_blkPara_distr_para_2.text = "       "
	exclude_list = [vbox1,vbox2,vbox3]
	distrType_optionButton.allow_reselect = true
	change_optionButton.allow_reselect = true
	distrType_optionButton.item_selected.connect(label_distr_para_refresh)
	change_optionButton.item_selected.connect(label_change_refresh)


func label_distr_para_refresh(_index):
	print("distr type: ",_index)
	match _index:
		0:
			label_blkPara_distr_para_1.text = "            mu change            "
			label_blkPara_distr_para_2.text = "         std/mu           "
		1:
			label_blkPara_distr_para_1.text = "     min     " 
			label_blkPara_distr_para_2.text = "     max     " 
		# 可以添加其他选项的处理
		_:
			# 处理未匹配的情况
			pass

func  label_change_refresh(_index):
	print("change type: ",_index)
	match _index:
		0:#chance
			vbox4.visible = true
			for i in exclude_list:
				i.visible = false
		1:
			vbox4.visible = false
			for i in exclude_list:
				i.visible = true
		# 可以添加其他选项的处理
		2:#rnd
			for i in exclude_list:
				i.visible = true
			vbox4.visible = true
		3:#chance(allow repeat)
			vbox4.visible = true
			for i in exclude_list:
				i.visible = false