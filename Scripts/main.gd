extends Node2D
# Node reference
@onready var label_1 = get_node("/root/Node2D/Label" )
@onready var label_2 = get_node("/root/Node2D/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text

# Export variables, which can be adjusted in the editor
@export var holding_text : String = "Hold..."
@export var result_format : String = "You held down %.2f seconds"

############## Variable settings ################
# Rewards are distributed with the length of time
var time_window 
var time_window_template
var hold_reward_probabilities
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
# timer variable
var start_time : float = 0.0
var is_holding : bool = false
var has_been_pressed : bool = false
var duration 
# Wealth Variable
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
	
func init_task(): # Initialize task, BLK design
	generate_block(1) # Generate a block of trials
	# Start 1st Trial
	init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])

func generate_block(case = null):
	# Generate a block of trials
	match case:
		1: # unfinished
			print("Case 1: Time-dependent reward distribution, not finished")
			BLK1(0.5, 3.5, 0.5, 0.8, 10, 0.8, 9, null)
		2:# unfinished
			print("Case 2:  not finished")
			BLK2(10,20,1,2)
		_:
			print("Case _: Easy mode")
			number_of_trials = 10 # Default number of trials
			inter_trial_interval = 0.8
			hold_reward_template= []
			hold_reward_template.resize(number_of_trials)
			hold_reward_template.fill(20)
			opt_out_reward_template =[]
			opt_out_reward_template.resize(number_of_trials)
			opt_out_reward_template.fill(2)
			time_window = [1, 1.5] # Default time window

func BLK2(a,b,c,d):
	# Generate rewards' templates for all trials
			for i in range(number_of_trials):
				var random_h = generate_ramdom(a,b)  # Press and hold reward
				var random_o = generate_ramdom(c,d) # Opt-out reward
				hold_reward_template.append(random_h) # Hold reward
				opt_out_reward_template.append(random_o) # Opt-out reward

func BLK1(t_min,  t_max, _step,
	_total_reward_chance,
	_number_of_trials,
	_inter_trial_interval,
	variance,  mean=null):
	
	step =_step
	number_of_trials = _number_of_trials
	inter_trial_interval = _inter_trial_interval
	time_window = [t_min, t_max] # Default time window
	if mean == null:
		mean = time_window[0] + (time_window[1] -time_window[0]) /2 # mean
	else: print("The parameter mean of the reward distribution over time has been set to:", mean)

	# Generate reward templates
	var templates = calculate_discrete_normal(time_window[0], time_window[1], 
	step, mean,  variance, _total_reward_chance)

	opt_out_reward_template = []
	opt_out_reward_template.resize(number_of_trials)
	opt_out_reward_template.fill(2)

	hold_reward_template = []
	hold_reward_probabilities = templates[0]
	###################################################
	var filters = []
	for p in hold_reward_probabilities:
		var filter = []
		var n=1000
		filter.resize(n)
		filter.fill(0)
		var n_true = int(p * n)
		for i in range(n_true):
			filter[i] = 1
		filter.shuffle()
		filter = filter.slice(0, number_of_trials)
		filters.append(filter)
	filters = _transpose(filters)
		
	for i in range(number_of_trials):
		var filter_of_the_trial = filters[i]
		var reward_template_of_the_trial = filter_of_the_trial.map(func(x): return x * 20)
		hold_reward_template.append(reward_template_of_the_trial)
	###############################################################
	print("hold_reward_template·0-5: ", hold_reward_template.slice(0, 5))
	

	########## 按钮部分逻辑要跟这里关联 ##########
	time_window_template= templates[1] 


#unfinished
func init_trial(hold_reward_for_this_trial,opt_out_reward_for_this_trial):
	# Initialize the test status
	has_been_pressed = false
	is_holding = false
	start_time = 0.0
	duration = 0.0
	# Initialization rewards
	hold_reward = hold_reward_for_this_trial 
	opt_out_reward = opt_out_reward_for_this_trial 

func init_ui():
	# Initialize UI status
	label_1.text = "Hold the button to earn rewards"
	label_2.text = " Your wealth: " + str(wealth)
	hold_button_label.text = "$" + str(hold_reward) 
	opt_out_button_label.text = "$" + str(opt_out_reward) 
	exclude_nodes_for_refresh = [label_1.name,label_2.name]
	
func reset_scene():
	# Reset the scene
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	trial_count += 1
	if trial_count < number_of_trials:
		init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])
		restore_all_children()
		# Reset status
		init_ui()
	else:
		label_1.text = "End of Trials"
		# End the experiment
		print("Experiment ends")

# How to generate rewards: constant, random (distribution)
func generate_hold_reward():
	return hold_reward_template  # 按住奖励

func generate_opt_out_reward():
	return opt_out_reward_template

# When the button is pressed
func _on_hold_button_down():
	if not has_been_pressed:
		is_holding = true
		start_time = Time.get_ticks_msec() / 1000.0  # 记录开始时间（秒）
		label_1.text = holding_text
		has_been_pressed = true
	else:
		reset_scene()

# When the button is released
func _on_hold_button_up():
	if is_holding:
		is_holding = false
		calculate_wealth_for_holding()
		_label_refresh(wealth,duration,false)
		reset_scene()

func _label_refresh(wealth,duration,opt_out):
	# 更新UI
	label_2.text = " Your wealth: " + str(wealth)
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

# Calculate and return the wealth for opting out	
func calculate_wealth_for_opt_out():
	# 计算并返回选择退出的奖励
	wealth += opt_out_reward

# Calculate and display the press-hold duration
func calculate_wealth_for_holding():
	var end_time = Time.get_ticks_msec() / 1000.0  # 获取结束时间（秒）
	duration = end_time - start_time  # 计算时长
	if duration > time_window[0] and duration < time_window[1]:
		wealth += hold_reward
	else:
		pass 


# Hide all child nodes and deactivate interactive elements
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
	print(rounded_probs, x_values, current_sum )
	return [rounded_probs, x_values, current_sum ]

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
