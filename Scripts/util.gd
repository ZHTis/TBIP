class_name Utils
extends Object

static func parse_numeric_array(str: String) -> Array:
	# 检查输入是否为空
	if str == null:
		return []
	
	# 移除字符串中的方括号
	var cleaned_str = str.replace("[", "").replace("]", "")
	
	# 如果清理后为空，返回空数组
	if cleaned_str == null:
		return []
	
	# 按逗号分割字符串
	var string_parts = cleaned_str.split(",")
	var result_array = []
	
	# 遍历分割后的部分并转换为数值
	for part in string_parts:
		# 去除前后空格
		var trimmed_part = part.strip_edges()
		
		# 尝试转换为数值
		if trimmed_part.is_valid_float():
			result_array.append(trimmed_part.to_float())
		else:
			# 处理无法转换的情况，可以根据需要修改
			print("Warning: Unable to convert '", trimmed_part, "' to a value, skipped")
	
	return result_array
