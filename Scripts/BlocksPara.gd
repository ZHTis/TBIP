extends Control
class_name BLKPara  # 定义类名，可在项目中直接引用

# 定义类的属性
var blk: String = "blk1"
var change: String = ""
var chance_list: Array = []
var distr_type: String = ""
var distr_para_1: Array = []
var distr_para_2: Array = []
var h_value_list: Array = []
var o_value_list: Array = []
var tr_num_range: Array = []

# 构造函数（可选，用于初始化时设置属性）
func _init(
    blk: String = "blk1",
    change: String = "",
    chance_list: Array = [],
    distr_type: String = "",
    distr_para_1: Array = [],
    distr_para_2: Array = [],
    h_value_list: Array = [],
    o_value_list: Array = [],
    tr_num_range: Array = []
) -> void:
    self.blk = blk
    self.change = change
    self.chance_list = chance_list
    self.distr_type = distr_type
    self.distr_para_1 = distr_para_1
    self.distr_para_2 = distr_para_2
    self.h_value_list = h_value_list
    self.o_value_list = o_value_list
    self.tr_num_range = tr_num_range

# 可选：添加一个转换为字典的方法，方便序列化
func to_dict() -> Dictionary:
    return {
        "blk": blk,
        "change": change,
        "chance_list": chance_list,
        "distr_type": distr_type,
        "distr_para_1": distr_para_1,
        "distr_para_2": distr_para_2,
        "h_value_list": h_value_list,
        "o_value_list": o_value_list,
        "tr_num_range": tr_num_range
    }

