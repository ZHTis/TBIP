class_name MathUtils
extends Object

# MARK: Ignore Math Parts

static func generate_x_range(min_value: int, max_value: int, step: int) -> Array:
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

static func calculate_discrete_normal(x_values,
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



# 转置二维数组的函数
static func _transpose(matrix: Array) -> Array:
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
static func gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a

# 计算两个数的最小公倍数
static func lcm(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return abs(a * b) / gcd(a, b)

# 计算数组中所有数的最小公倍数
static func array_lcm(numbers: Array) -> int:
	var result = 1
	for num in numbers:
		result = lcm(result, num)
	return result

# 将浮点数转换为最简分数的分母
static func float_to_denominator(value: float) -> int:
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
static func find_min_integer_lcm(float_array: Array) -> int:
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
static func calculate_variance(numbers: Array) -> float:
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

static func expand_array(elements_array: Array, counts_array: Array) -> Array:
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

static func convert_float_to_int(value: float) -> Variant:
  # Check whether there are decimal parts of floating point numbers
	if value == floor(value):
		return int(value)
	elif abs(value - floor(value)) <= 0.000001:
		return int(value)
	else:
		return value

# batch processing of floating point numbers in arrays
static func process_array_to_int(arr: Array) -> Array:
	var result = []
	for element in arr:
		if element is float:
			result.append(convert_float_to_int(element))
		else:
			result.append(element)
	print("array to int result: ",result)
	Global.text5 = "array to int result: "+str(result)
	return result


static func generate_random(start,stop,type = "int"):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if type == "int":
		var random_int = rng.randi_range(start, stop)
		return random_int
	elif type == "float":
		var random_float = rng.randf_range(start, stop)
		return random_float


static func normrnd(mu, variance) -> float:
	if variance < 0.0:
		print("方差必须非负  当前值: %f" % variance)
		return 0.0
	# 计算标准差
	var sigma: float = sqrt(variance)
	# Box-Muller变换生成标准正态分布随机数
	var u1 = generate_random(0,1,"float")
	var u2 =  generate_random(0,1,"float")
	
	var z0: float = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	# 转换为目标分布
	return z0 * sigma + mu


# MARK: End Math Parts
