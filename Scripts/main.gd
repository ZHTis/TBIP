extends Node2D
# Node reference
@onready var label_1 = get_node("/root/Node2D/Label" )
@onready var label_2 = get_node("/root/Node2D/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text



############## Variable set in func BLKs ################
var press_num_slot 
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
# time variable
var start_time : float = 0.0
var num_of_press : int = 0
var reward_given_flag : bool = false
var ui_auto_refresh: bool = false
# Wealth Variable
var reward_given_timepoint:int = 0
var reward
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
	exclude_nodes_for_refresh = [label_1.name, label_2.name]
	init_task() # Initialize the task
	_label_refresh(wealth, num_of_press, "init")
	# Connect button signal
	hold_button.pressed.connect(_on_hold_button_pressed)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)

func _process(delta):
	# Update the num_of_press if the button is being held
	if ui_auto_refresh == true:
		_label_refresh(wealth,num_of_press,"pressing...")

func init_task(): # Initialize task, BLK design
	generate_block() # Generate a block of trials
	# Start 1st Trial
	init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])

func generate_block(case = null):
	# Generate a block of trials
	match case:
		1: # finished, generate reward_given_timepoint and reward given tremplate here
			print("=======Case 1: Time-dependent reward distribution=======")
			BLK1(1, 35, 0.8, 20, 10, 0.8, 9)
		2: # unfinished
			print("=======Case 2: Random reward distribution=======")
			BLK2(5, 35, 1, 5) # generate reward_given_timepoint and reward given tremplate here
		_: # Case _: Easy mode
			print("Case _: Easy mode")
			number_of_trials = 10 # Default number of trials
			inter_trial_interval = 0.8
			reward_given_timepoint = 3 # Default time point to give reward
			hold_reward_template= []
			hold_reward_template.resize(number_of_trials)
			hold_reward_template.fill(20)
			opt_out_reward_template =[]
			opt_out_reward_template.resize(number_of_trials)
			opt_out_reward_template.fill(2)

func BLK2(a,b,c,d):
	# Generate rewards' templates for all trials
			for i in range(number_of_trials):
				var random_h = generate_ramdom(a,b)  # Press and hold reward
				var random_o = generate_ramdom(c,d) # Opt-out reward
				hold_reward_template.append(random_h) # Hold reward
				opt_out_reward_template.append(random_o) # Opt-out reward

func BLK1(press_num_min, press_num_max,
	_total_reward_chance, 
	_hold_reward,_opt_out_reward
	_number_of_trials,
	_inter_trial_interval,
	variance,  mean=null, _step=1):
	
	step =_step
	number_of_trials = _number_of_trials
	inter_trial_interval = _inter_trial_interval
	if mean == null:
		mean = (press_num_min + press_num_max )/2 # mean
	else: print("The parameter mean of the reward distribution over time has been set to:", mean)

	########## Pre-generated reward  ##############
	var templates = calculate_discrete_normal(press_num_min,press_num_max, 
	step, mean,  variance, _total_reward_chance)
	#
	opt_out_reward_template = []
	opt_out_reward_template.resize(number_of_trials)
	opt_out_reward_template.fill(2) # Opt-out reward is always 2,customize this to make it flexible

	hold_reward_template = []
	hold_reward_probabilities = templates[0]
	### events based on probability
	var filters = []
	#for p in hold_reward_probabilities:
		#var filter = []
		#var n=1000
		#filter.resize(n)
		#filter.fill(0)
		#var n_true = int(p * n)
		#for i in range(n_true):
			#filter[i] = 1
		#filter.shuffle()
		#filter = filter.slice(0, number_of_trials)
		#filters.append(filter)
	#filters = _transpose(filters)
		
	for i in range(number_of_trials):
		var filter_of_the_trial = filters[i]
		var reward_template_of_the_trial = filter_of_the_trial.map(func(x): return x * hold_reward)
		hold_reward_template.append(reward_template_of_the_trial)
	###############################################################

	########## The button part logic should be associated with this ##########
	press_num_slot = templates[1] 
	print("press_num_slot : ", press_num_slot )


#unfinished
func init_trial(_hold_reward_for_this_trial,opt_out_reward_for_this_trial):
	# Initialize the test status
	reward_given_flag = false
	start_time = 0.0
	num_of_press = 0.0
	# Initialization rewards
	reward = _hold_reward_for_this_trial 
	opt_out_reward = opt_out_reward_for_this_trial 
	print("trial", trial_count, "\nreward: ", reward)
	
func reset_scene():
	# Reset the scene
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	trial_count += 1
	if trial_count < number_of_trials:
		init_trial(hold_reward_template[trial_count], opt_out_reward_template[trial_count])
		restore_all_children()
		# Reset status
		_label_refresh(wealth,num_of_press,"init")
	else:
		label_1.text = "End of Trials"
		# End the experiment
		print("Experiment ends")

# When the button is released
func _on_hold_button_pressed():
	if reward_given_flag == false:
		num_of_press += 1
		_label_refresh(wealth,num_of_press,"pressing...")
		ui_auto_refresh = true
		if num_of_press == reward_given_timepoint:
			wealth+= reward
			reward_given_flag = true
			ui_auto_refresh = false
			_label_refresh(wealth,num_of_press,"reward_given")
			reset_scene()
	else:
		reset_scene()


func _on_opt_out_button_pressed():
	wealth += opt_out_reward
	_label_refresh(wealth, 0.0, "opt_out")
	reward_given_flag = true
	reset_scene()


func _label_refresh(wealth,num_of_press,case):
	# 更新UI
	var hold_reward = reward
	var opt_out_reward = opt_out_reward
	hold_button_label.text = "$" + str(hold_reward) 
	opt_out_button_label.text = "$" + str(opt_out_reward) 
	label_2.text = " Your wealth: " + str(wealth)
	match case:
		"opt_out":
			label_1.text = "Opt Out!"
		"pressing...":
			label_1.text = str(num_of_press)
		"reward_given":
			label_1.text = "Reward given!"
			reward_given_flag = false
		"init":
			label_1.text = "Press the button to earn rewards"
		_:
			label_1.text = ""


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
	min_value: int, 
	max_value: int, 
	step:int,
	mean, 
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

# 计算两个数的最大公约数
func gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a

# 计算两个数的最小公倍数
func lcm(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return abs(a * b) / gcd(a, b)

# 计算数组中所有数的最小公倍数
func array_lcm(numbers: Array) -> int:
	var result = 1
	for num in numbers:
		result = lcm(result, num)
	return result

# 将浮点数转换为最简分数的分母
func float_to_denominator(value: float) -> int:
	# 处理特殊情况
	if value == 0:
		return 1
		
	# 将浮点数转换为字符串以处理小数部分
	var str = str(value)
	var parts = str.split(".")
	
	# 如果是整数，分母为1
	if parts.size() == 1:
		return 1
		
	# 处理小数部分，获取分母
	var fractional_part = parts[1]
	# 移除可能的科学计数法部分
	fractional_part = fractional_part.split("e")[0]
	# 计算10的幂作为临时分母
	var temp_denominator = pow(10, fractional_part.length())
	
	# 计算分子
	var numerator = int(round(value * temp_denominator))
	
	# 简化分数，返回最简分母
	return temp_denominator / gcd(numerator, temp_denominator)

# 寻找数组中所有浮点数的最小整数公倍数
func find_min_integer_lcm(float_array: Array) -> int:
	# 验证输入
	for value in float_array:
		if not value is float and not value is int:
			push_error("数组必须只包含浮点数或整数")
			return 0
	
	# 获取所有浮点数对应的最简分数的分母
	var denominators = []
	for value in float_array:
		# 处理0的特殊情况（0可以被任何数整除）
		if value == 0:
			continue
		denominators.append(float_to_denominator(value))
	
	# 如果数组全是0，返回1（0的任何倍数都是0）
	if denominators.empty():
		return 1
	
	# 计算所有分母的最小公倍数
	return array_lcm(denominators)
