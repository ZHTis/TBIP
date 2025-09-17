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
    _blk: String = "blk1",
    _change: String = "",
    _chance_list: Array = [],
    _distr_type: String = "",
    _distr_para_1: Array = [],
    _distr_para_2: Array = [],
    _h_value_list: Array = [],
    _o_value_list: Array = [],
    _tr_num_range: Array = []
) -> void:
    self.blk = _blk
    self.change = _change
    self.chance_list = _chance_list
    self.distr_type = _distr_type
    self.distr_para_1 = _distr_para_1
    self.distr_para_2 = _distr_para_2
    self.h_value_list = _h_value_list
    self.o_value_list = _o_value_list
    self.tr_num_range = _tr_num_range

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

