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
var reward_given_timepoint_template 
var hold_reward_template
var opt_out_reward_template 
# Store the original state for recovery (processing possible initial hidden elements)
var original_states = {}
var exclude_nodes_for_refresh



func _ready():
	ifrelease()
	Global.init_write() # Initialize storage directory
	init_ui() # Initialize UI
	wealth = 0 # Initialize wealth
	trial_count = 0
	exclude_nodes_for_refresh = [label_1.name, label_2.name]
	init_task() # Initialize the task
	_label_refresh(wealth, num_of_press, "init")
	# Connect button signal
	hold_button.pressed.connect(_on_hold_button_pressed)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)

func ifrelease():
	# 判断是否从上一个特定场景跳转过来
	if Global.iftextEditHasAppear:
		return  # 退出函数，不执行剩余部分
	
	# 如果不是从特定场景过来，执行后续逻辑
	if OS.has_feature("release"):
	# 加载发布场景
		Global.iftextEditHasAppear = true
		get_tree().change_scene_to_file("res://textEdit.tscn")
	else:print("debug skip textEdit.tscn")
	# 加载调试场景


func _process(delta):
	# Update the num_of_press if the button is being held
	if ui_auto_refresh == true:
		_label_refresh(wealth,num_of_press,"pressing...")

func init_task(): # Initialize task, BLK design
	Global.press_history = [] # Clear press history
	generate_block(1) # Generate a block of trials
	# Start 1st Trial
	init_trial()


func init_ui():
	DisplayServer.window_set_min_size(Vector2(400, 300))



func generate_block(case = null):
	# Generate a block of trials, generate reward_given_timepoint and reward given tremplate here
	match case:
		1: # finished
			print("=======Case 1: reward fixed, ~N( p_reward, num_of_press)=======")
			BLK1(3, 11, 1.0, 20, -2, 3, 0.8, 9, 7)
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
# MARK: BLK1
func BLK1(press_num_min, press_num_max,
	_total_reward_chance, 
	_hold_reward,_opt_out_reward,
	_number_of_trials,
	_inter_trial_interval,
	variance=null,  mean=null, _step=1):
	
	step =_step
	number_of_trials = _number_of_trials
	inter_trial_interval = _inter_trial_interval
	if mean == null:
		mean = (press_num_min + press_num_max )/2 # mean
	else: 
		Global.text6 = "The parameter mean of the reward distribution over time has been set to:"+str(mean)
		print("The parameter mean of the reward distribution over time has been set to:", mean)
	
	########## The button part logic should be associated with this ##########
	press_num_slot = generate_x_range(press_num_min, press_num_max, step)
	Global.text2 = "press_num_slot : " +str(press_num_slot)
	print(Global.text2)
	var _round = 100
	var x_values = press_num_slot
	if variance == null:
		variance = calculate_variance(x_values) # variance
	else: 
		Global.text3 = "The parameter variance of the reward distribution over time has been set to:" + str(variance)
		print(Global.text3)
	var prob_templates = calculate_discrete_normal(x_values, mean,  variance, _total_reward_chance)[0] 
	var reward_candidate_ref = prob_templates.map(func(x):return x* _round)
	reward_candidate_ref = process_array_to_int(reward_candidate_ref)
	var reward_candidate = expand_array(x_values, reward_candidate_ref)
	if reward_candidate.size() < _round:
		var length = reward_candidate.size()
		for i in range(_round-length):
			reward_candidate.append(1000)
	reward_candidate.shuffle()
	reward_given_timepoint_template = reward_candidate.slice(0, number_of_trials)
	Global.text1 = "reward_given_timepoint_template : %s" % str(reward_given_timepoint_template)
	print(Global.text1)


	########## Pre-generated reward  ##############
	opt_out_reward_template = []
	opt_out_reward_template.resize(number_of_trials)
	opt_out_reward_template.fill(_opt_out_reward) # Opt-out reward is always 2,customize this to make it flexible

	hold_reward_template = []
	hold_reward_template.resize(number_of_trials)
	hold_reward_template.fill(_hold_reward) # Hold reward is always 1,customize this to make it flexible


#  unfinished
func init_trial():
	if trial_count >=number_of_trials:
		hide_all_children()
		trial_count += 1
		return 
	trial_count += 1
	# Initialize the test status
	reward_given_flag = false
	start_time = 0.0
	num_of_press = 0.0
	# Initialization rewards
	reward = hold_reward_template[trial_count-1]
	opt_out_reward = opt_out_reward_template[trial_count-1]
	reward_given_timepoint = reward_given_timepoint_template[trial_count-1]
	print("trial", trial_count, "\nreward: ", reward,"\t" ,opt_out_reward, "\treward_given_timepoint: ", reward_given_timepoint)
	
func reset_scene():
	# Reset the scene
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	if trial_count <= number_of_trials:
		init_trial()
		restore_all_children()
		# Reset status
		_label_refresh(wealth,num_of_press,"init")
	if trial_count > number_of_trials:
		_label_refresh(wealth,num_of_press,"finish")
		end()
# MARK: Buttons Response
# When the button is released
func _on_hold_button_pressed():
	# 获取当前时间戳（秒）
	var current_time = Time.get_ticks_msec() 
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
	record_press_data(current_time, reward_given_flag, PressData.BtnType.HOLD)
	


func _on_opt_out_button_pressed():
	# 获取当前时间戳（秒）
	var current_time = Time.get_ticks_msec() 
	wealth += opt_out_reward
	reward_given_flag = true
	record_press_data(current_time, reward_given_flag, PressData.BtnType.OPT_OUT)
	_label_refresh(wealth, 0.0, "opt_out")
	reset_scene()

# 封装记录按键数据的函数
func record_press_data(current_time, reward_given_flag: Variant, btn_type: PressData.BtnType) -> void:
	# 创建PressData实例
	var new_press = PressData.new(current_time, reward_given_flag, btn_type)
	# 添加到全局历史记录
	Global.press_history.append(new_press)
	print("Recorded PressData: ", new_press)

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
		"finish":
			label_1.text = "Finished!"	
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

# MARK: Ignore Math Parts

func generate_x_range(min_value: int, max_value: int, step: int) -> Array:
	var x_values = []
	if min_value <= 0 or max_value <= 0 or min_value > max_value:
		push_error("区间必须包含正整数且min_value <= max_value")
		return x_values
	if step <= 0:
		push_error("步长必须为正数")
		return x_values

	var current = min_value
	# 使用while循环生成小数区间，考虑浮点数精度问题
	while current <= max_value + 1e-9:  # 增加微小值处理浮点数精度误差
		x_values.append(current)
		current += step 

	return x_values

func calculate_discrete_normal(x_values,
	mean, 
	variance: float, 
	aoc: float) -> Array:

	# 验证输入参数
	if variance <= 0:
		push_error("方差必须为正数")
		return []
	if aoc <= 0 or aoc > 1:
		push_error("目标面积必须在(0, 1]范围内")
		return []
	
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
	print("rounded_probs, current_sum , x_values: " , rounded_probs, current_sum, x_values )
	Global.text4 = "rounded_probs, current_sum , x_values: " + str(rounded_probs) + " " + str(current_sum) + " " + str(x_values)
	return [rounded_probs, current_sum ]

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

# 计算一组数的方差
func calculate_variance(numbers: Array) -> float:
	# 检查数组是否为空
	if numbers==[]:
		push_error("数组不能为空")
		return 0.0
	
	# 计算平均值
	var sum = 0.0
	for num in numbers:
		sum += num
	var mean = sum / numbers.size()
	
	# 计算每个数与平均值的差的平方的总和
	var squared_diff_sum = 0.0
	for num in numbers:
		var diff = num - mean
		squared_diff_sum += diff * diff
	
	# 计算方差（总体方差）
	return squared_diff_sum / numbers.size()

func expand_array(elements_array: Array, counts_array: Array) -> Array:
	# 检查两个数组长度是否相同
	if elements_array.size() != counts_array.size():
		print("错误: 两个数组长度必须相同")
		return []
	
	var result = []
	
	# 遍历数组生成新数组
	for i in range(elements_array.size()):
		var element = elements_array[i]
		var count = counts_array[i]
		
		# 检查计数是否为非负整数
		if count is not int or count < 0:
			print("错误: 计数必须是非负整数，索引: ", i)
			continue
		
		# 将元素按照指定次数添加到结果数组
		for j in range(count):
			result.append(element)
	
	return result

func convert_float_to_int(value: float) -> Variant:
  # Check whether there are decimal parts of floating point numbers
	if value == floor(value):
		return int(value)
	elif abs(value - floor(value)) <= 0.000001:
		return int(value)
	else:
		return value

# batch processing of floating point numbers in arrays
func process_array_to_int(arr: Array) -> Array:
	var result = []
	for element in arr:
		if element is float:
			result.append(convert_float_to_int(element))
		else:
			result.append(element)
	print("array to int result: ",result)
	Global.text5 = "array to int result: "+str(result)
	return result

# MARK: End Math Parts

func end():
	print("Exiting the experiment, saving data...")
	Global.write_subject_data_to_file() # Save data before exiting
	print("Data saved. Goodbye!") 
	
	
