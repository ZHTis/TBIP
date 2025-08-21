extends LineEdit
			 
func _ready():

	read_only = false  # 设置为只读模式
	# 设置默认文本
	text = "初始内容"

	# 设置字体大小
	add_theme_font_size_override("font_size", 24)  # 设置为你需要的字体大小
	
	# 设置文本居中对齐
	alignment = HORIZONTAL_ALIGNMENT_CENTER  # 水平居中
	# 如果需要垂直居中，可以调整 rect_min_size 并配合容器节点
	
	# 其他样式设置（可选）
	add_theme_color_override("font_color", Color(1, 1, 1))  # 文本颜色
	add_theme_color_override("bg_color", Color(0.2, 0.2, 0.2))  # 背景颜色

	# 设置默认文本
	text = "初始内容"

	read_only = true  # 设置为只读模式
	
	# 设置字体

	# 设置字体大小
	add_theme_font_size_override("font_size", 24)  # 设置为你需要的字体大小
	
	# 设置文本居中对齐
	alignment = HORIZONTAL_ALIGNMENT_CENTER  # 水平居中
	# 如果需要垂直居中，可以调整 rect_min_size 并配合容器节点
	
	# 其他样式设置（可选）
	add_theme_color_override("font_color", Color(1, 1, 1))  # 文本颜色
	add_theme_color_override("bg_color", Color(0.2, 0.2, 0.2))  # 背景颜色
