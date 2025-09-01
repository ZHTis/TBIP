extends Node

# 跨场景共享变量
var subject_name: String = ""  # 被试者名称
var press_history: Array[PressData] = []  # 按键历史记录
var text1: String = ""  # 文本1
var text2: String = ""  # 文本2
var text3: String = ""  # 文本3
var text4: String = ""  # 文本4
var text5: String = ""  # 文本5
var text6: String = ""  # 文本6

# 获取基于被试者名称的CSV文件路径
func gen_file_name() -> String:
	var base_dir = "user://save_data"
	
	# 处理被试者名称（过滤特殊字符）
	var safe_subject_name = subject_name.strip_edges()
	if safe_subject_name=="":
		safe_subject_name = "unknown_subject"
	
	# 移除文件名中不允许的特殊字符
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for char in invalid_chars:
		safe_subject_name = safe_subject_name.replace(char, "_")
	
	# 生成带时间戳的文件名（CSV格式）
	var timestamp = Time.get_datetime_string_from_system()
	timestamp = timestamp.replace(":", "_")
	var file_path = "%s/%s_%s.txt" % [base_dir, safe_subject_name, timestamp]
	
	return file_path


# 初始化存储目录
func init_write() -> void:
	var base_dir = "user://save_data"
	var dir = DirAccess.open(base_dir.get_base_dir())
	
	if not dir:
		print("无法访问父目录: ", base_dir.get_base_dir())
		print("错误: ", DirAccess.get_open_error())
		return
	
	# 创建目录（包括任何必要的父目录）
	var result = dir.make_dir_recursive(base_dir)
	if result == OK:
		print("存储目录已准备: ", base_dir)
	else:
		print("无法创建目录: ", base_dir)
		print("错误代码: ", result)
	


# 将数据写入文件（头部说明 + CSV格式数据）
func write_subject_data_to_file() -> void:
	var file_path = gen_file_name()
	var user_path = ProjectSettings.globalize_path("user://")
	# 尝试打开文件以确认路径有效，但立即关闭
	var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	if file:
		file.close()  # 确保关闭文件句柄
	else:
		print("错误: ", FileAccess.get_open_error())
		return

	print("文件路径: ", user_path,"\t",file_path)
	file = FileAccess.open(file_path, FileAccess.WRITE)
	# 第一部分：文件头部说明（用#开头标记为注释，不影响CSV解析）
	file.store_line("# === 被试者数据记录 ===")
	file.store_line("# 被试者名称: %s" % subject_name)
	file.store_line("# 记录时间: %s" % Time.get_datetime_string_from_system())
	file.store_line("# 总记录数: %d" % press_history.size())
	file.store_line(text1)
	file.store_line(text2)
	file.store_line(text3)
	file.store_line(text6)
	file.store_line(text4)
	file.store_line(text5)
	
	file.store_line("# ------------------------")
	file.store_line("# 以下为CSV格式数据, 每行一条记录")
	file.store_line("# 格式说明: 序号,时间戳(ms),奖励标记,按键类型")
	file.store_line("# 案件类型：0:hold ; 1：opt-out")
	
	# 第二部分：CSV数据（首行为列标题，后续为数据）
	file.store_line("index,timestamp_seconds,reward_flag,button_type")  # CSV列标题
	
	# 写入每条按键数据（CSV格式）
	for i in range(press_history.size()):
		var press = press_history[i]
		# CSV格式：用逗号分隔字段，字符串包含逗号时需用引号包裹
		var csv_line = "%d,%d,%s,%s" % [
			i + 1,  # 序号
			press.timestamp,  # 时间戳
			str(press.rwd_marker).to_lower(),  # 奖励标记（转为小写，如true/false）
			press.btn_type_marker  # 按键类型
		]
		file.store_line(csv_line)
	
	file.close()


# 清空历史记录
func clear_press_history() -> void:
	press_history.clear()
	print("已清空当前被试者的按键记录")
