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
var filename_config
var filename_data

# 获取基于被试者名称的CSV文件路径
func gen_file_name() -> Array:
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
	var data_filename = "%s/%s_%s.txt" % [base_dir, safe_subject_name, timestamp]
	var config_filename = "%s/%s_config.txt" % [base_dir, safe_subject_name]
	
	return [data_filename, config_filename]


# 初始化存储目录
func init_write() -> void:
	var base_dir = "user://save_data"
	var dir = DirAccess.open(base_dir.get_base_dir())
	
	if not dir:
		print("Unable to access the parent directory: ", base_dir.get_base_dir())
		print("mistake: ", DirAccess.get_open_error())
		return
	
	# 创建目录（包括任何必要的父目录）
	var result = dir.make_dir_recursive(base_dir)
	if result == OK:
		print("Storage directory is ready: ", base_dir)
		# 生成文件名
		var files = gen_file_name()
		filename_data = files[0]
		filename_config = files[1]
		for filename in files:
		# 尝试打开文件以确认路径有效，但立即关闭
			var file = FileAccess.open(filename, FileAccess.WRITE_READ)
			if file:
				file.close()  # 确保关闭文件句柄
				print("File created: ", filename)
			else:
				print("mistake: ", FileAccess.get_open_error())
	else:
		print("Unable to create a directory: ", base_dir)
		print("Error code: ", result)


# 将数据写入文件（头部说明 + CSV格式数据）
func write_subject_data_to_file(data_filename) -> void:
	var user_path = ProjectSettings.globalize_path("user://")
	print("File path: ", user_path,"\t",data_filename)

	var file = FileAccess.open(data_filename, FileAccess.WRITE)
	if not file:
		print("Unable to open the file: ", data_filename)
		print("mistake: ", FileAccess.get_open_error())
		return
	file.store_line("Subject name: %s" % subject_name)
	file.store_line("Number of tests: %d" % num_of_trials)
	file.store_line("Key History: %d" % press_history.size())
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
	file.close()

