extends RefCounted  # 继承 RefCounted 使其可被安全引用和传递

# 定义属性（默认公开，可被其他类访问）
var tr_num: int  # 示例：整数类型，可根据需求修改为 float/String 等
var t: Array = []  # 一维数组，初始为空
var h: Array = []  # 一维数组
var o: Array = []  # 一维数组


# 构造函数：初始化 tr_num
func _init(init_tr_num: int,_t, _h, _o) -> void:
    tr_num = init_tr_num
    t = _t
    h = _h
    o = _o


# 为 t 数组添加元素的方法
func append_t(value: Variant) -> void:
    t.append(value)  # 使用 Godot 内置的 Array.append 方法


# 为 h 数组添加元素的方法
func append_h(value: Variant) -> void:
    h.append(value)


# 为 o 数组添加元素的方法
func append_o(value: Variant) -> void:
    o.append(value)


# 可选：批量添加元素（扩展方法）
func extend_t(values: Array) -> void:
    t.append_array(values)  # 批量添加数组元素


func extend_h(values: Array) -> void:
    h.append_array(values)


func extend_o(values: Array) -> void:
    o.append_array(values)