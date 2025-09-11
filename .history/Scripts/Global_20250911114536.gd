extends Node

# 跨场景共享变量
var subject_name: String = ""  # 被试者名称
var num_of_trials: int = 0  # 试验次数
var press_history: Array[PressData] = []  # 按键历史记录
var text1: String = ""  # 文本1
var text2: String = ""  # 文本2
var text3: String = ""  # 文本3
var text4: String = ""  # 文本4
var text5: String = ""  # 文本5
var text6: String = ""  # 文本6
var text7: String = ""  # 文本7
var text8: String = ""  # 文本8
var text9: String = ""  # 文本9
var text10: String = ""  # 文本10
var text11: String = ""  # 文本11
var text12: String = ""  # 文本12
var text13: String = ""  # 文本13
var text14: String = ""  # 文本14
var text15: String = ""  # 文本15
var text16: String = ""  # 文本16
var text17: String = ""  # 文本17
var text18: String = ""  # 文本18
var text19: String = ""  # 文本19
var text20: String = ""  # 文本20

var iftextEditHasAppear: bool = false
var wealth: int = 0
var saved_flag: bool = false
var filename

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
	var _filename = "%s/%s_%s.txt" % [base_dir, safe_subject_name, timestamp]
	
	return _filename


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
		filename = gen_file_name()
		# 尝试打开文件以确认路径有效，但立即关闭
		var file = FileAccess.open(filename, FileAccess.WRITE_READ)
		if file:
			file.close()  # 确保关闭文件句柄
			print("文件已创建: ", filename)
		else:
			print("错误: ", FileAccess.get_open_error())
	else:
		print("无法创建目录: ", base_dir)
		print("错误代码: ", result)


# 将数据写入文件（头部说明 + CSV格式数据）
func write_subject_data_to_file(filename) -> void:
	var user_path = ProjectSettings.globalize_path("user://")
	print("文件路径: ", user_path,"\t",filename)

	var file = FileAccess.open(filename, FileAccess.WRITE)
	if not file:
		print("无法打开文件: ", filename)
		print("错误: ", FileAccess.get_open_error())
		return
	file.store_line("被试者名称: %s" % subject_name)
	file.store_line("试验次数: %d" % num_of_trials)
	file.store_line("按键历史记录: %d" % press_history.size())
	file.store_line("tokens: %d" % wealth)
	file.store_line("blk1: %s" % text1)
	file.store_line("blk2: %s" % text2)
	file.store_line("blk3: %s" % text3)
	file.store_line("blk4: %s" % text4)
	file.store_line("blk5: %s" % text5)
	file.store_line("blk6: %s" % text6)
	file.store_line("blk7: %s" % text7)
	file.store_line("blk8: %s" % text8)
	file.store_line("blk9: %s" % text9)
	file.store_line("blk10: %s" % text10)
	file.store_line("blk11: %s" % text11)
	file.store_line("blk12: %s" % text12)
	file.store_line("blk13: %s" % text13)
	file.store_line("blk14: %s" % text14)
	file.store_line("blk15: %s" % text15)
	file.store_line("blk16: %s" % text16)
	file.store_line("blk17: %s" % text17)
	file.store_line("blk18: %s" % text18)
	file.store_line("blk19: %s" % text19)
	file.store_line("blk20: %s" % text20)
	file.store_line("# ------------------------")
	file.store_line("# The following is CSV format data, one record per line")
	file.store_line("# Format description: serial number, timestamp (ms), reward mark, key type")
	file.store_line("# Case type: 0:hold; 1:opt-out")
	
	# 第二部分：CSV数据（首行为列标题，后续为数据）
	file.store_line("index,trail_idx,timestamp_ms,reward_flag,button_type")  # CSV列标题
	
	# 写入每条按键数据（CSV格式）
	for i in range(press_history.size()):
		var press = press_history[i]
		# CSV格式：用逗号分隔字段，字符串包含逗号时需用引号包裹
		var csv_line = "%d,%d ,%d,,%s,%s" % [
			i + 1,  # 序号
			press.trial_count,
			press.timestamp,  # 时间戳
			str(press.rwd_marker).to_lower(),  # 奖励标记（转为小写，如true/false）
			press.btn_type_marker  # 按键类型
		]
		file.store_line(csv_line)
	
	file.close()
	saved_flag = true
