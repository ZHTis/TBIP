extends Node2D
# Node reference
@onready var label_1 = get_node("/root/Node2D/Label" )
@onready var label_2 = get_node("/root/Node2D/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text
@onready var timer= $Timer
# Export variables, which can be adjusted in the editor
@export var holding_text : String = "Holding... %.2f s"


############## Variable set in func BLKs ################
var time_window_template
var reward_given_timepoint
var reward_given_signal
var total_reward_chance
var inter_trial_interval 
var step # timewindow step
var mean 
var variance
var number_of_trials
var min_hold_reward 
var max_hold_reward 
var min_opt_out_reward
var max_opt_out_reward
var case
#################################################
## Function variables
var trial_count
# time variable
var start_time : float = 0.0
var is_holding : bool = false
var has_been_pressed : bool = false
var ui_auto_refresh: bool = false
var duration 
# Wealth Variable
var reward
var hold_reward
var opt_out_reward 
var wealth 
var hold_reward_template
var opt_out_reward_template 
# Store the original state for recovery (processing possible initial hidden elements)
var original_states = {}
var exclude_nodes_for_refresh



func _ready():
	wealth = 0 # Initialize wealth
	trial_count = 0
	init_task() # Initialize the task
	init_ui() # Initialize the UI
	# Connect button signal
	hold_button.button_down.connect(_on_hold_button_down)
	hold_button.button_up.connect(_on_hold_button_up)
	hold_button.mouse_exited.connect(_on_hold_button_up)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)

func _process(delta):
	# Update the duration if the button is being held
	if ui_auto_refresh:
		duration = Time.get_ticks_msec() / 1000.0 - start_time
		_label_refresh(wealth,duration,"is_holding")



func init_task(): # Initialize task, BLK design
	generate_block() # Generate a block of trials
	# Start 1st Trial
	init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count], reward_given_timepoint)

func generate_block(case = null):
	# Generate a block of trials
	match case:

		2:# unfinished
			pass
		_: 
			print("Case _:  Reward at some certain timepoint")
			BLK2(20,2)

func BLK2(_hold_reward, _opt_out_reward):
	number_of_trials = 10 # Default number of trials
	inter_trial_interval = 0.8
	hold_reward_template= []
	hold_reward_template.resize(number_of_trials)
	hold_reward_template.fill(_hold_reward)
	opt_out_reward_template =[]
	opt_out_reward_template.resize(number_of_trials)
	opt_out_reward_template.fill(_opt_out_reward)
	reward_given_timepoint = 1
	
			

#unfinished
func init_trial(_hold_reward_for_this_trial,opt_out_reward_for_this_trial, _reward_given_timepoint):
	# Initialize the test status
	has_been_pressed = false
	is_holding = false
	start_time = 0.0
	duration = 0.0
	reward_given_signal = false
	# Initialization rewards
	hold_reward = _hold_reward_for_this_trial 
	opt_out_reward = opt_out_reward_for_this_trial

func init_ui():
	# Initialize UI status
	label_1.text = "Hold the button to earn rewards"
	label_2.text = " Your wealth: " + str(wealth)
	hold_button_label.text = "$" + str(hold_reward) 
	opt_out_button_label.text = "$" + str(opt_out_reward) 
	exclude_nodes_for_refresh = [label_1.name,label_2.name,timer.name]
	
func reset_scene():
	timer.stop()
	# Reset the scene
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	trial_count += 1
	if trial_count < number_of_trials:
		init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count], reward_given_timepoint)
		restore_all_children()
		# Reset status
		init_ui()
	else:
		label_1.text = "End of Trials"
		# End the experiment
		print("Experiment ends")


# When the button is pressed
func _on_hold_button_down():
	is_holding = true
	start_time = Time.get_ticks_msec() / 1000.0  # Always reset start_time on press
	if not has_been_pressed:
		has_been_pressed = true
		timer.start(reward_given_timepoint)
		print("Timer started")
		ui_auto_refresh = true
		timer.timeout.connect(_on_timer_timeout)
	else:
		reset_scene()

# When the button is released
func _on_hold_button_up():
	ui_auto_refresh = false
	if is_holding:
		is_holding = false
		duration = Time.get_ticks_msec() / 1000.0 - start_time  # 计算按住时长（秒）

		reset_scene()

func _label_refresh(wealth,duration,case):
	# 更新UI
	label_2.text = " Your wealth: " + str(wealth)
	match case:
		"opt_out":
			label_1.text = "Opt Out!"
		"is_holding":
		# 显示按住时长
			label_1.text = holding_text % duration
		"reward_given":
			label_1.text = "Reward given!"
			reward_given_signal = false
		_:
			label_1.text = ""


func _on_opt_out_button_pressed():
	calculate_wealth_for_opt_out()
	_label_refresh(wealth, 0.0, "opt_out")
	has_been_pressed = true
	reset_scene()

# Calculate and return the wealth for opting out	
func calculate_wealth_for_opt_out():
	# 计算并返回选择退出的奖励
	wealth += opt_out_reward



func _on_timer_timeout():
	reward_given_signal = true
	timer.stop()
	print("Timer timeout")
	ui_auto_refresh = false
	if is_holding and reward_given_signal:
		wealth += hold_reward
		reward_given_signal = false
		_label_refresh(wealth,duration,"reward_given")
	

# Hide all child nodes and deactivate interactive elements
func hide_all_children():
	# 先保存所有子节点的原始状态
	original_states.clear()
	for child in get_children():
		if child.name in exclude_nodes_for_refresh:
			continue  # 跳过不需要隐藏的节点
	
		original_states[child] = {
			"visible": child.visible ,
			"disabled": child.disabled if "disabled" in child else null
		}

		# 隐藏节点
		child.visible = false
		# 停用互动元素
		if "disabled" in child:
			child.disabled = true

# Restore all child nodes to their original state
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

	var x_range = []
	var x_values=[]

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
	while current < max_value + 1e-9:  # 增加微小值处理浮点数精度误差
		x_range.append(current)
		current += step * 0.5
		if current < max_value + 1e-9: 
			x_values.append(current)
			current += step * 0.5
	

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
	var rounded_probs = []
	var current_sum 
	for prob in probabilities:
		# 四舍五入到两位小数
		var rounded = round(prob * 100) / 100
		rounded_probs.append(rounded)
		current_sum = 0.0
	for p in rounded_probs:
		current_sum += p

	# 返回结果：概率列表、x值列表、实际面积
	print(" rounded_probs, x_range, current_sum , x_values: " , rounded_probs, x_range, current_sum, x_values )
	return [rounded_probs, x_range, current_sum ]

func generate_ramdom(start,stop,type = "int"):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if type == "int":
		var random_int = rng.randi_range(start, stop)
		return random_int
	else:
		var random_float = rng.randf_range(start, stop)
		return random_float

# 转置二维数组的函数
func _transpose(matrix: Array) -> Array:
	# 处理空数组情况
	if matrix.size() == 0:
		return []
	
	# 获取原数组的行数和列数
	var rows = matrix.size()
	var cols = matrix[0].size()
	
	# 检查是否为不规则数组（每行长度不同）
	for row in matrix:
		if row.size() != cols:
			print("Warning: The input 2D array has inconsistent row lengths, transpose may be inaccurate")
			break
	
	# 创建转置后的数组
	var transposed = []
	for j in range(cols):
		var new_row = []
		for i in range(rows):
			new_row.append(matrix[i][j])
		transposed.append(new_row)
	
	return transposed

# 查找数字在数组中位于哪两个元素之间（优化版）
static func find_between_elements(arr: Array, num: float) -> Dictionary:
	if arr == []:
		return {
			"position": "empty array",
			"previous": null,
			"previous_index": -1,
			"next": null,
			"next_index": -1
		}
	
	# 创建排序后的数组副本并直接排序
	var sorted_arr = arr.duplicate()
	sorted_arr.sort()
	
	# 处理边界情况：数字小于等于最小元素
	if num <= sorted_arr[0]:
		return {
			"previous": null,
			"previous_index": -1,
			"next": sorted_arr[0],
			"next_index": arr.find(sorted_arr[0])
		}
	
	# 处理边界情况：数字大于等于最大元素
	if num >= sorted_arr[-1]:
		return {
			"previous": sorted_arr[-1],
			"previous_index": arr.find(sorted_arr[-1]),
			"next": null,
			"next_index": -1
		}
	
	# 查找数字所在的区间
	for i in range(sorted_arr.size() - 1):
		if num >= sorted_arr[i] && num <= sorted_arr[i + 1]:
			return {
				"previous": sorted_arr[i],
				"previous_index": arr.find(sorted_arr[i]),
				"next": sorted_arr[i + 1],
				"next_index": arr.find(sorted_arr[i + 1])
			}
	
	# 默认返回
	return {
		"previous": null,
		"previous_index": -1,
		"next": null,
		"next_index": -1
	}
