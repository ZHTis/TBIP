extends Node2D
# 节点引用
@onready var label_1 = get_node("/root/Node2D/Label" )
@onready var label_2 = get_node("/root/Node2D/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text

# 导出变量，可在编辑器中调整
@export var holding_text : String = "按住中..."
@export var result_format : String = "你按住了 %.2f 秒"

###############实验变量设置#################################
# 奖励随按住时间长度分布变量
var time_window = [0.5,1.5]
var inter_trial_interval = 0.8
var step = 0.1
var mean = 0.9
var variance = 9 
var total_reward_chance = 0.9
var number_of_trials = 10
var min_hold_reward = 1
var max_hold_reward = 10
var min_opt_out_reward = 1
var max_opt_out_reward = 10
###########################################################
## 函数变量
var trial_count
# 计时器变量    
var start_time : float = 0.0
var is_holding : bool = false
var has_been_pressed : bool = false
var duration 
# 财富变量
var hold_reward
var opt_out_reward 
var wealth 
var hold_reward_template
var opt_out_reward_template 
# 存储原始状态，用于恢复（处理可能的初始隐藏元素）
var original_states = {}
var exclude_nodes_for_refresh

func _ready():
	wealth = 0  # 初始化财富
	trial_count = 0
	init_task(min_hold_reward, max_hold_reward, min_opt_out_reward, max_opt_out_reward)  # 初始化任务
	init_ui()  # 初始化UI
	# 连接按钮信号
	hold_button.button_down.connect(_on_hold_button_down)
	hold_button.button_up.connect(_on_hold_button_up)
	hold_button.mouse_exited.connect(_on_hold_button_up)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)
	
func init_task(a,b,c,d): # 初始化任务, BLK design
	if mean == null:
		mean = time_window[0] + (time_window[1] - time_window[0]) / 2  # 均值
	else:
		print("奖励随时间分布的参数mean已设置为: ", mean)
	# 生成奖励模板	
	hold_reward_template = []
	opt_out_reward_template = []
	for i in range(number_of_trials):
		var random_h = generate_ramdom(a,b)  # 按住奖励
		var random_o = generate_ramdom(c,d)  # 选择退出奖励
		hold_reward_template.append(random_h)  # 按住奖励
		opt_out_reward_template.append(random_o)  # 选择退出奖励
	# Start 1st Trial
	init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])

	
func init_trial(hold_reward_for_this_trial,opt_out_reward_for_this_trial):
	# 初始化试验状态
	has_been_pressed = false
	is_holding = false
	start_time = 0.0
	duration = 0.0
	# 初始化奖励
	hold_reward = hold_reward_for_this_trial 
	opt_out_reward = opt_out_reward_for_this_trial 

func init_ui():
	# 初始化UI状态
	label_1.text = ""
	label_2.text = " 你的财富: " + str(wealth)
	hold_button_label.text = str(hold_reward) 
	opt_out_button_label.text = str(opt_out_reward) 
	exclude_nodes_for_refresh = [label_1.name,label_2.name]
	
func reset_scene():
	# 重置场景
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	trial_count += 1
	if trial_count < number_of_trials:
		init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])
		restore_all_children()
		# 重置状态
		init_ui()
	else:
		label_1.text = "End of Trials"
		# 结束实验
		print("实验结束")

# 生成奖励的方式：常量， 随机（分布）
func generate_hold_reward():
	return hold_reward_template  # 按住奖励

func generate_opt_out_reward():
	return opt_out_reward_template

# 计算并显示按住时长
func calculate_wealth_for_holding():
	var end_time = Time.get_ticks_msec() / 1000.0  # 获取结束时间（秒）
	duration = end_time - start_time  # 计算时长
	if duration > time_window[0] and duration < time_window[1]:
		# 在时间窗口内，增加奖励
		wealth += hold_reward
	else:
		pass  # 不在时间窗口内，不增加奖励

# 按钮按下时
func _on_hold_button_down():
	if not has_been_pressed:
		is_holding = true
		start_time = Time.get_ticks_msec() / 1000.0  # 记录开始时间（秒）
		label_1.text = holding_text
		has_been_pressed = true
	else:
		reset_scene()

# 按钮松开时
func _on_hold_button_up():
	if is_holding:
		is_holding = false
		calculate_wealth_for_holding()
		_label_refresh(wealth,duration,false)
		reset_scene()

func _label_refresh(wealth,duration,opt_out):
	# 更新UI
	label_2.text = " 你的财富: " + str(wealth)
	if opt_out:
		label_1.text = "Opt Out!"
	else:
		# 显示按住时长
		label_1.text = result_format % duration

func _on_opt_out_button_pressed():
	calculate_wealth_for_opt_out()
	_label_refresh(wealth, 0.0,true)
	has_been_pressed = true
	reset_scene()
		
func calculate_wealth_for_opt_out():
	# 计算并返回选择退出的奖励
	wealth += opt_out_reward


# 隐藏所有子节点并停用互动元素
func hide_all_children():
	# 先保存所有子节点的原始状态
	original_states.clear()
	for child in get_children():
		if child.name in exclude_nodes_for_refresh:
			continue  # 跳过不需要隐藏的节点
	
		original_states[child] = {
			"visible": child.visible,
			"disabled": child.disabled if "disabled" in child else null
		}
		
		# 隐藏子节点
		child.visible = false
		
		# 停用互动元素
		if "disabled" in child:
			child.disabled = true

# 恢复所有子节点到原始状态
func restore_all_children():
	for child in original_states:
		# 恢复可见性
		child.visible = original_states[child]["visible"]
		
		# 恢复互动状态
		if original_states[child]["disabled"] != null:
			child.disabled = original_states[child]["disabled"]
	
	original_states.clear()


func calculate_discrete_normal(
	min_value: float, 
	max_value: float, 
	step:float,
	mean: float, 
	variance: float, 
	aoc: float) -> Array:

	var x_values = []

	# 验证输入参数
	if min_value <= 0 or max_value <= 0 or min_value > max_value:
		push_error("区间必须包含正整数且min_value <= max_value")
		return []
	if variance <= 0:
		push_error("方差必须为正数")
		return []
	if aoc <= 0 or aoc > 1:
		push_error("目标面积必须在(0, 1]范围内")
		return []
	if step <= 0:
		push_error("步长必须为正数")
		return x_values
	
	var current = min_value
	# 使用while循环生成小数区间，考虑浮点数精度问题
	while current <= max_value + 1e-9:  # 增加微小值处理浮点数精度误差
		x_values.append(current)
		current += step

	# 计算未归一化的概率密度
	var densities = []
	var sum_original: float = 0.0  # 原始面积（区间内的概率密度总和）
	
	for x in x_values:
		var exponent: float = -0.5 * pow(x - mean, 2) / variance
		var density: float = exp(exponent) / sqrt(2 * PI * variance)
		densities.append(density)
		sum_original += density
	
	# 防止除以零
	if sum_original <= 0:
		push_error("计算的原始面积为0，无法调整到目标面积")
		return []
	
	# 计算缩放因子以达到目标面积
	var scale_factor = aoc / sum_original
	
	# 应用缩放因子
	var probabilities = []
	for density in densities:
		probabilities.append(density * scale_factor)
	
	# 计算实际得到的面积
	var actual_area: float = 0.0
	for p in probabilities:
		actual_area += p
	
	# 返回结果：概率列表、x值列表、实际面积
	return [probabilities, x_values, actual_area]

func generate_ramdom(start,stop,type = "float"):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if type == "int":
		var random_int = rng.randi_range(start, stop)
		return random_int
	else:
		var random_float = rng.randf_range(start, stop)
		return random_float
