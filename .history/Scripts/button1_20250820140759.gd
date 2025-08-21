extends Button

# 下半部分几何图形的配置
export var shape_color : Color = Color(1, 0, 0)  # 图形颜色（可在编辑器中设置）
export var shape_size : float = 30  # 图形大小（可在编辑器中设置）
export var shape_type : int = 0  # 0=圆形, 1=正方形, 2=三角形
# 上半部分文字的配置
export var text_content : String = "按钮文字"  # 文字内容

func _ready():
    # 初始化按钮布局
    _setup_layout()
    # 初始化文字
    self.text = text_content
	self.pressed.connect(_on_button_pressed)



# 当按钮被按下时调用
func _on_button_pressed():
	# 加载并切换到目标场景
	getreward()
	
func getreward():
	get_tree().change_scene_to_file("res://reward.tscn")
extends Button



func _setup_layout():
    # 设置按钮整体大小
    rect_min_size = Vector2(150, 120)  # 宽150，高120（上半40+下半80）
    # 禁用按钮自带的文本居中，改为手动布局
    align = ALIGN_LEFT
    valign = VALIGN_TOP

# 绘制下半部分几何图形（重写绘图函数）
func _draw():
    # 计算图形绘制区域（下半部分）
    var shape_y = rect_size.y / 2  # 从按钮中点开始绘制下半部分
    var shape_center_x = rect_size.x / 2  # 水平居中
    var shape_center_y = shape_y + (rect_size.y / 4)  # 垂直居中于下半部分

    # 根据形状类型绘制图形
    match shape_type:
        0:  # 圆形
            draw_circle(Vector2(shape_center_x, shape_center_y), shape_size/2, shape_color)
        1:  # 正方形
            var rect = Rect2(
                shape_center_x - shape_size/2,
                shape_center_y - shape_size/2,
                shape_size,
                shape_size
            )
            draw_rect(rect, shape_color)
        2:  # 三角形
            var points = PoolVector2Array([
                Vector2(shape_center_x, shape_center_y - shape_size/2),  # 上顶点
                Vector2(shape_center_x - shape_size/2, shape_center_y + shape_size/2),  # 左下
                Vector2(shape_center_x + shape_size/2, shape_center_y + shape_size/2)   # 右下
            ])
            draw_polygon(points, [shape_color])

# 对外提供修改属性的方法
func set_text(new_text: String):
    text_content = new_text
    self.text = new_text
