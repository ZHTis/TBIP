extends Node

# Share variables across scenarios
var subject_name: String = "" # Name of subject
var num_of_trials: int = 0 # Number of tests
var press_history: Array[PressData] = [] # Key History
var blk_num: int = 1
var blks_para = []

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
var text21: String = ""  # 文本21
var text22: String = ""  # 文本22
var text23: String = ""  # 文本23
var text24: String = ""  # 文本24
var text25: String = ""  # 文本25
var text26: String = ""  # 文本26
var text27: String = ""  # 文本27
var text28: String = ""  # 文本28
var text29: String = ""  # 文本29
var text30: String = ""  # 文本30
var text31: String = ""  # 文本31
var text32: String = ""  # 文本32
var text33: String = ""  # 文本33
var text34: String = ""  # 文本34
var text35: String = ""  # 文本35
var text36: String = ""  # 文本36

var iftextEditHasAppear: bool = false
var wealth: int = 0
var saved_flag: bool = false
var filename_config
var filename_data

# Get the CSV file path based on the subject's name
func gen_file_name() -> Array:
	var base_dir = "user://save_data"
	
	# 处理被试者名称（过滤特殊字符）
	var safe_subject_name = subject_name.strip_edges()
	if safe_subject_name=="":
		safe_subject_name = "unknown_subject"
	
	# 移除文件名中不允许的特殊字符
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for any_char in invalid_chars:
		safe_subject_name = safe_subject_name.replace(any_char, "_")
	
	# 生成带时间戳的文件名（CSV格式）
	var timestamp = Time.get_datetime_string_from_system()
	timestamp = timestamp.replace(":", "_")
	var data_filename = "%s/%s_%s.txt" % [base_dir, safe_subject_name, timestamp]
	var config_filename = "%s/%s_%s_config.txt" % [base_dir, safe_subject_name, timestamp]
	
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
		filename_config = files[1]
		filename_data = files[0]
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
	for i in range(1,37):
		var text_value = get("text" + str(i))
		file.store_line("blk%s: %s" % [str(i), text_value])
	file.store_line("# ------------------------")
	file.close()
