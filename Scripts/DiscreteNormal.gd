extends Node2D

# 分布参数
@export var min_value: int = 1        # 区间下限
@export var max_value: int = 20      # 区间上限
@export var mean: float = 10.0       # 均值
@export var variance: float = 9.0    # 方差

# 存储计算结果
var x_values: Array = []
var probabilities: Array = []

func _ready():
	# 计算离散正态分布
	calculate_discrete_normal()
	
	# 输出结果到控制台
	print_results()


func calculate_discrete_normal():
	# 验证输入参数
	if min_value <= 0 or max_value <= 0 or min_value > max_value:
		push_error("区间必须包含正整数且min_value <= max_value")
		return
	
	# 生成正整数区间
	x_values = []
	for x in range(min_value, max_value + 1):
		x_values.append(x)
	
	# 计算未归一化的概率密度
	var densities: Array = []
	var sum_densities: float = 0.0
	
	for x in x_values:
		var exponent: float = -0.5 * pow(x - mean, 2) / variance
		var density: float = exp(exponent) / sqrt(2 * PI * variance)
		densities.append(density)
		sum_densities += density
	
	# 归一化概率
	probabilities = []
	for density in densities:
		probabilities.append(density / sum_densities)

func print_results():
	print("正整数区间上的离散正态分布:")
	print("x值 | 概率")
	#print("-" * 20)
	
	for i in range(x_values.size()):
		print("%3d | %.6f" % [x_values[i], probabilities[i]])
	
	# 验证概率和为1
	var sum_prob: float = 0.0
	for p in probabilities:
		sum_prob += p
	print("\n概率总和: %.6f" % sum_prob)
