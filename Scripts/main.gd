extends Control
# Node reference
@onready var label_1 = get_node("/root/Node2D/VBox/Label" )
@onready var label_2 = get_node("/root/Node2D/VBox/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text
@onready var vbox = $VBox

@onready var label_t = $VBox/TimerLabel  # 用于显示倒计时的标签

var time_left : int = 900
var countdownTimer
############## Variable set in func BLKs ################
var press_num_slot 
var hold_reward_probabilities
var total_reward_chance
var inter_trial_interval 
var step # timewindow step
var mean 
var variance
var number_of_trials
var min_hold_reward 
var max_hold_reward 
var min_opt_out_reward
var max_opt_out_reward
var case
#################################################
## Function variables
var trial_count
# time variable
var start_time : float = 0.0
var num_of_press : int = 0
var reward_given_flag : bool = false
# Wealth Variable
var reward_given_timepoint
var reward
var opt_out_reward
var reward_given_timepoint_template 
var hold_reward_template
var opt_out_reward_template 
# Store the original state for recovery (processing possible initial hidden elements)
var original_states = {}
var exclude_nodes_for_refresh



func _ready():
	ifrelease()
	get_tree().auto_accept_quit = false	
	set_countdownTimer(true)
	Global.init_write() # Initialize storage directory
	init_ui() # Initialize UI
	init_task() # Initialize the task
	

func ifrelease():
	# 判断是否从上一个特定场景跳转过来
	if Global.iftextEditHasAppear:
		return  # 退出函数，不执行剩余部分
	
	# 如果不是从特定场景过来，执行后续逻辑
	if OS.has_feature("release"):
	# 加载发布场景
		Global.iftextEditHasAppear = true
		get_tree().change_scene_to_file("res://textEdit.tsc")
	else:print("debug skip textEdit.tscn")
	# 加载调试场景



# MARK: TASK
func init_task(): # Initialize task, BLK design
	Global.press_history = [] # Clear press history
	Global.wealth = 0 # Initialize Global.wealth
	trial_count = 0
	number_of_trials = 0
	generate_all_trials(1) # Generate a block of trials
	# Start 1st Trial
	init_trial()
	_label_refresh(Global.wealth, num_of_press, "init")
	# Connect button signal
	hold_button.pressed.connect(_on_hold_button_pressed)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)


func generate_all_trials(case = null):
	# Generate a block of trials, generate reward_given_timepoint and reward given tremplate here
	match case:
		
		1: # unfinished
			print("=======Case 2: Random reward chance/value//distribution/tr_num =======")
			inter_trial_interval = 0.8

			reward_given_timepoint_template = []
			hold_reward_template=[]
			opt_out_reward_template =[]
			blk_("full", "norm", 1, 2,20,-2,5, 120,120,  8, 20) 
			blk_("random", "flat", 2,  2,20,-2,5, 100,200,  3,100)
	
			# set blk switch
		_: # Case _: Easy mode
			print("Case _: Easy mode")
			number_of_trials = 10 # Default number of trials
			Global.num_of_trials = number_of_trials
			inter_trial_interval = 0.8
			reward_given_timepoint = 3 # Default time point to give reward
			hold_reward_template= []
			hold_reward_template.resize(number_of_trials)
			hold_reward_template.fill(20)
			opt_out_reward_template =[]
			opt_out_reward_template.resize(number_of_trials)
			opt_out_reward_template.fill(2)


func blk_(_reward_chance_mode, distribution_type, save_loc,
		# rwd value: a,b,hold; c,d,opt-out
		a,b,c,d,
		# tr_num range:
		tr_num1, tr_num2,
		 #	reward_given_timepoint press:
		_min=0,_max=0):
			
	var dice
	var timepoint
	var reward_given_timepoint_template_this_blk = []
	# rnd tr_num
	number_of_trials += MathUtils.generate_random(tr_num1, tr_num2,"int")

	print("number_of_trials: ", number_of_trials)
	Global.num_of_trials = number_of_trials

	match _reward_chance_mode:
		"full":
			total_reward_chance = 1
		"random":
			total_reward_chance = MathUtils.generate_random(0.5,1,"float") # set total reward chance


	# data generated, depend on distribution type
	for i in range(number_of_trials):
		dice = MathUtils.generate_random(0,1,"float") # set total reward chance 
		if dice <= total_reward_chance:
			match distribution_type:
				"norm": # Normal distribution
					var mu=MathUtils.generate_random(_min, _max,"int")
					var variance=MathUtils.generate_random(0, 0.5* mu,"float")
					while true: # Avoid generating negative numbers
						timepoint = MathUtils.normrnd(mu, variance)
						if timepoint > 0:
							break 
					timepoint = roundi(timepoint)

				"flat": # flat distribution
					timepoint = MathUtils.generate_random(_min, _max,"int")
			
			reward_given_timepoint_template.append(timepoint)
			reward_given_timepoint_template_this_blk.append(timepoint)
		else:
			reward_given_timepoint_template.append(null)
			reward_given_timepoint_template_this_blk.append(null)
	# rnd rwd value for each trial
	
	for i in range(number_of_trials):
		var random_h = MathUtils.generate_random(a,b)  # Press and hold reward
		var random_o = MathUtils.generate_random(c,d) # Opt-out reward
		hold_reward_template.append(random_h) # Hold reward
		opt_out_reward_template.append(random_o) # Opt-out reward
	

	var text1 = "reward_given_timepoint_template_this_blk : %s" % str(reward_given_timepoint_template_this_blk)
	var text2 = "hold_reward_template : %s" % str(hold_reward_template)
	var text3 = "opt_out_reward_template : %s" % str(opt_out_reward_template)
	var text4 = "total_reward_chance: %s" % str(total_reward_chance)
	var text5 = "number_of_trials: %s" % str(number_of_trials)
	var text = text1 + "\n" + text2 + "\n" + text3 + "\n" + text4 + "\n" + text5
	print(text)
	match save_loc:
		2: # Save to file			
			Global.text2 = text
		1: # Print to console
			Global.text1 = text
	

#  unfinished
func init_trial():
	if trial_count >=number_of_trials:
		hide_all_children()
		trial_count += 1
		return 
	trial_count += 1
	# Initialize the test status
	reward_given_flag = false
	start_time = 0.0
	num_of_press = 0.0
	# Initialization rewards
	reward = hold_reward_template[trial_count-1]
	opt_out_reward = opt_out_reward_template[trial_count-1]
	reward_given_timepoint = reward_given_timepoint_template[trial_count-1]
	print("trial", trial_count, "\nreward: ", reward,"\t" ,opt_out_reward, "\treward_given_timepoint: ", reward_given_timepoint)
	
func reset_scene():
	# Reset the scene
	hide_all_children()
	await get_tree().create_timer(inter_trial_interval).timeout
	if trial_count <= number_of_trials:
		init_trial()
		restore_all_children()
		# Reset status
		_label_refresh(Global.wealth,num_of_press,"init")
	if trial_count > number_of_trials:
		_label_refresh(Global.wealth,num_of_press,"finish")
		end()


# MARK: Buttons Response

func _input(event):
	if event.is_action_released("press_optout_button"):
		if not opt_out_button.disabled:
			opt_out_button.emit_signal("pressed")
	if event.is_action_released("press_hold_button"):
		if not hold_button.disabled:
			hold_button.emit_signal("pressed")

# When the button is released
func _on_hold_button_pressed():
	# Get the current timestamp (seconds)
	var current_time = Time.get_ticks_msec() 
	# Handle invalid behavior
	if reward_given_timepoint == null:
		num_of_press += 1
		_label_refresh(Global.wealth,num_of_press,"pressing...")
		record_press_data(current_time, trial_count, reward_given_flag, PressData.BtnType.HOLD)
		
	elif reward_given_flag == false:
		num_of_press += 1
		_label_refresh(Global.wealth,num_of_press,"pressing...")
		if num_of_press < reward_given_timepoint:
			record_press_data(current_time, trial_count, reward_given_flag, PressData.BtnType.HOLD)
		if num_of_press == reward_given_timepoint:
			Global.wealth+= reward
			reward_given_flag = true
			print("hold-reward_given_flag  ",reward_given_flag)
			_label_refresh(Global.wealth,num_of_press,"reward_given")
			record_press_data(current_time, trial_count, true, PressData.BtnType.HOLD)
			reset_scene()


func _on_opt_out_button_pressed():
	# 获取当前时间戳（秒）
	var current_time = Time.get_ticks_msec() 
	Global.wealth += opt_out_reward
	reward_given_flag = true
	_label_refresh(Global.wealth, num_of_press, "opt_out")
	record_press_data(current_time,trial_count, reward_given_flag, PressData.BtnType.OPT_OUT)
	reset_scene()

# 封装记录按键数据的函数
func record_press_data(current_time, _tr_count, _reward_given_flag, btn_type: PressData.BtnType) -> void:
	# 创建PressData实例
	var new_press = PressData.new(current_time, _tr_count, _reward_given_flag, btn_type)
	# 添加到全局历史记录
	Global.press_history.append(new_press)
	#print("Recorded PressData: ", new_press)


# MARK: UI
func init_ui():
	# 获取窗口尺寸
	var window_size = get_viewport_rect().size
	var root = get_node("/root/Node2D" )
	root.set_anchors_and_offsets_preset( PRESET_FULL_RECT, PRESET_MODE_KEEP_SIZE)# this is important!
	LayoutManager.setup(vbox, PRESET_CENTER, 0.5, 0.85, window_size)
	LayoutManager.setup($MenuButton, PRESET_CENTER, 0.35, 0.4, window_size)
	LayoutManager.setup($MenuButton2, PRESET_CENTER, 0.65, 0.4, window_size)
	exclude_nodes_for_refresh = [vbox.name]
	


# MARK: Label Refresh
func _label_refresh(wealth,num_of_press,case):
	# 更新UI
	var hold_reward = reward
	var opt_out_reward = opt_out_reward
	hold_button_label.text = "$" + str(hold_reward) 
	opt_out_button_label.text = "$" + str(opt_out_reward) 
	label_2.text = " Your wealth: " + str(wealth)
	match case:
		"opt_out":
			label_1.text = "Opt Out!"
		"pressing...":
			label_1.text = str(num_of_press)
		"reward_given":
			label_1.text = "Reward given!"
			reward_given_flag = false
		"init":
			label_1.text = "Press the button to earn rewards"
		"finish":
			label_1.text = "Finished!\n Close the window to exit"	
		_:
			label_1.text = ""


# Hide all child nodes and deactivate interactive elements
func hide_all_children():
	# 先保存所有子节点的原始状态
	original_states.clear()
	for child in get_children():
		if child.name in exclude_nodes_for_refresh:
			continue  # 跳过不需要隐藏的节点
	
		original_states[child] = {
			"visible": child.visible,
			"disabled": child.disabled if "disabled" in child else null
		}
		
		# 隐藏子节点
		child.visible = false
		
		# 停用互动元素
		if "disabled" in child:
			child.disabled = true
	hold_button.disabled = true
	opt_out_button.disabled = true

# Restore all child nodes to their original state
func restore_all_children():
	for child in original_states:
		# 恢复可见性
		child.visible = original_states[child]["visible"]
		
		# 恢复互动状态
		if original_states[child]["disabled"] != null:
			child.disabled = original_states[child]["disabled"]
	hold_button.disabled = false
	opt_out_button.disabled = false
	
	original_states.clear()

# MARK: Timer
func set_countdownTimer(ifset:bool):
	if ifset == true:
		countdownTimer = Timer.new()
		label_t.text = "Time Left: " + str(time_left) + " s"
		countdownTimer.autostart = false
		countdownTimer.one_shot = false
		vbox.add_child(countdownTimer) 
		countdownTimer.start(1)
		countdownTimer.timeout.connect(_on_timer_timeout)
	else:
		label_t.text = "" 


func _on_timer_timeout():
	time_left -= 1
	
	if time_left >= 0:
		label_t.text = "Time Left: " + str(time_left) +" s"
	else:
		label_t.text = "Time's Up!"
		countdownTimer.stop()  
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func end():
	print("Exiting the experiment, saving data...")
	Global.write_subject_data_to_file(Global.filename) # Save data before exiting
	print("Data saved. Goodbye!") 

func _notification(what:int)->void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Global.saved_flag == false:
			end() 
		get_tree().quit()
