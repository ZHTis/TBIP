class_name CountdownTimer
extends Control

# 信号定义 - 可以在任何地方连接这些信号
signal tick(remaining_time)  # 每秒触发，传递剩余时间
signal finished()           # 倒计时结束时触发

var total_time: int = 10    # 总倒计时时间（秒）
var remaining_time: int = 0
var is_running: bool = false
var timer: Timer = Timer.new()

func _init(initial_time: int = 10):
	total_time = initial_time
	remaining_time = total_time
	
	# 配置计时器
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timeout)


# 开始或继续倒计时
func start():
	if not is_running:
		is_running = true
		timer.start()

# 暂停倒计时
func pause():
	if is_running:
		is_running = false
		timer.stop()



# 直接设置剩余时间
func set_remaining_time(time: int):
	remaining_time = clamp(time, 0, total_time)
	emit_signal("tick", remaining_time)

# 内部计时处理
func _on_timeout():
	remaining_time -= 1
	emit_signal("tick", remaining_time)
	
	if remaining_time <= 0:
		finish()

# 强制结束倒计时
func finish():
	pause()
	emit_signal("finished")

# 清理
func _exit_tree():
	timer.timeout.disconnect(_on_timeout)
