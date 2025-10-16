extends Node

# Share variables across scenarios
var subject_name: String = "" # Name of subject
var inference_type
enum InferenceFlagType {time_based, press_based}
var num_of_trials: int = 0 # Number of tests
var press_history: Array[Array] = [] # Key History
var iftextEditHasAppear: bool = false
var wealth: int = 0
var saved_flag: bool = false
var filename_config
var filename_data
var config_text: Array[Dictionary] = [] # Configuration file content

# Get the CSV file path based on the subject's name
func gen_file_name() -> Array:
	var base_dir = "user://save_data"
	# Process subject names (filter special characters)
	var safe_subject_name = subject_name.strip_edges()
	if safe_subject_name=="":
		safe_subject_name = "unknown_subject"
	
	# Remove special characters not allowed in file names
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for any_char in invalid_chars:
		safe_subject_name = safe_subject_name.replace(any_char, "_")
	
	# Generate timestamped filenames (CSV format)
	var timestamp = Time.get_datetime_string_from_system()
	timestamp = timestamp.replace(":", "_")
	var data_filename = "%s/%s_%s.txt" % [base_dir, safe_subject_name, timestamp]
	var config_filename = "%s/%s_%s_config.txt" % [base_dir, safe_subject_name, timestamp]
	
	return [data_filename, config_filename]


#Initialize storage directory
func init_write() -> void:
	var base_dir = "user://save_data"
	var dir = DirAccess.open(base_dir.get_base_dir())
	
	if not dir:
		print("Unable to access the parent directory: ", base_dir.get_base_dir())
		print("mistake: ", DirAccess.get_open_error())
		return
	
	# Create the directory (including any necessary parent directories)
	var result = dir.make_dir_recursive(base_dir)
	if result == OK:
		print("Storage directory is ready: ", base_dir)
		# 生成文件名
		var files = gen_file_name()
		filename_config = files[1]
		filename_data = files[0]
		for filename in files:
		# Tried opening the file to confirm the path was valid, but it closed immediately
			var file = FileAccess.open(filename, FileAccess.WRITE_READ)
			if file:
				file.close()  # 确保关闭文件句柄
				print("File created: ", filename)
			else:
				print("mistake: ", FileAccess.get_open_error())
	else:
		print("Unable to create a directory: ", base_dir)
		print("Error code: ", result)


# Write data to file (header description + CSV format data)
func write_sessionDesign_to_file(data_filename) -> void:
	var user_path = ProjectSettings.globalize_path("user://")
	print("File path: ", user_path,"\t",data_filename)

	var file = FileAccess.open(data_filename, FileAccess.WRITE)
	if not file:
		print("Unable to open the file: ", data_filename)
		print("mistake: ", FileAccess.get_open_error())
		return
	file.store_line("Subject name: %s" % subject_name)
	file.store_line("Number of tests: %d" % num_of_trials)
	file.store_line("\n")
	for i in range(config_text.size()):
		var json_string
		for key in config_text[i].keys():
			if key !="template_t_h_o" and key!="reward_signal_timepoint":
				json_string = JSON.stringify(config_text[i].get(key)," ", false, false)
			else:
				json_string = JSON.stringify(config_text[i].get(key),"", false, false)
			file.store_line(key + ": " + json_string)
		file.store_line("# ------------------------")
	file.close()
