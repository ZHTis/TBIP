class_name LayoutManager
extends Control


# 构造函数
func _init():
	pass

# 设置盒子的位置和布局
func setup_box_position(box, layout_preset, x_pos, y_pos, window_size,
	resize_mode: LayoutPresetMode = PRESET_MODE_KEEP_SIZE):
	# 计算盒子的中心偏移量
	var box_center = box.get_rect().get_center() - box.get_position()
	
	# 设置盒子的锚点和偏移量预设（保持大小）
	box.set_anchors_and_offsets_preset(layout_preset, resize_mode)
	
	# 设置子控件在容器中居中对齐
	if box is BoxContainer:
		box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 设置盒子的位置
	box.position = Vector2(
		window_size.x * x_pos - box_center.x,
		window_size.y * y_pos - box_center.y
	)

# 静态方法，无需实例化即可使用
static func setup(box, layout_preset, x_pos, y_pos, window_size, resize_mode = PRESET_MODE_KEEP_SIZE):
	var manager = LayoutManager.new()
	manager.setup_box_position(box, layout_preset, x_pos, y_pos, window_size, resize_mode)
	
