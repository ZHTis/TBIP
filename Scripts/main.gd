extends Control
# Node reference
@onready var label_1 = $VBox/Label
@onready var label_2 = get_node("/root/Node2D/VBox/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/Text
@onready var opt_out_button_label = $MenuButton2/Text
@onready var vbox = $VBox
@onready var vboxstart = $VBoxSTART
@onready var vboxbottom = $VBoxBottom
@onready var quitButton = $VBoxBottom/QuitButton
@onready var startButton = $VBoxSTART/StartButton
@onready var label_startbtn = $VBoxBottom/Label
@onready var label_t = $VBox/TimerLabel  # 用于显示倒计时的标签

var time_left : int = 900
var countdownTimer
############## Variable set in func BLKs ################
var press_num_slot 
var hold_reward_probabilities
var total_reward_chance
var _interval 
var step # timewindow step
var mean 
var variance
var number_of_trials
var min_hold_reward 
var max_hold_reward 
var min_opt_out_reward
var max_opt_out_reward
var if_opt_left
#################################################
## Function variables
var trial_count
var initialized_flag : bool = false
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
var original_states_2 = {}
var exclude_nodes_for_hide_cards
var exclude_nodes_for_srart_menu



func _ready():
	ifrelease()
	get_tree().auto_accept_quit = false	
	set_countdownTimer(false)
	Global.init_write() # Initialize storage directory
	exclude_nodes_for_hide_cards = [vbox.name, vboxstart.name, vboxbottom.name]
	exclude_nodes_for_srart_menu = [vboxstart.name, vboxbottom.name]
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
	if_opt_left = MathUtils.generate_random(0,1,"float")
	Global.press_history = [] # Clear press history
	Global.wealth = 0 # Initialize Global.wealth
	trial_count = 0
	number_of_trials = 0
	initialized_flag = false
	generate_all_trials(1) # Generate a block of trials
	# Start 1st Trial
	init_trial()
	_label_refresh(Global.wealth, num_of_press, "init")
	# Connect button signal
	hold_button.pressed.connect(_on_hold_button_pressed)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)
	startButton.pressed.connect(_on_start_button_pressed)
	quitButton.pressed.connect(_on_quit_button_pressed)


func generate_all_trials(case_ = null):
	# Generate a block of trials, generate reward_given_timepoint and reward given tremplate here
	match case_:
		
		1: # unfinished
			print("=======Case 2: Random reward chance/value//distribution/tr_num =======")
			_interval = 0.5

			reward_given_timepoint_template = []
			hold_reward_template=[]
			opt_out_reward_template =[]
			blk_("random", "norm", 1, 2,20,-2,5, 60,150,  8,40) 
			blk_("random", "norm", 2,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 3,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 4,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 5,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 6,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 7,  2,20,-2,5, 60,150,  8,40)
			blk_("random", "norm", 8,  2,20,-2,5, 60,150,  8,40)

			# set blk switch
		_: # Case _: Easy mode
			print("Case _: Easy mode")
			number_of_trials = 10 # Default number of trials
			Global.num_of_trials = number_of_trials
			_interval = 0.8
			reward_given_timepoint = 3 # Default time point to give reward
			hold_reward_template= []
			hold_reward_template.resize(number_of_trials)
			hold_reward_template.fill(20)
			opt_out_reward_template =[]
			opt_out_reward_template.resize(number_of_trials)
			opt_out_reward_template.fill(2)

# MARK: BLK
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
	var hold_reward_template_this_blk = []
	var opt_out_reward_template_this_blk = []
	# rnd tr_num
	var number_of_trials_this_blk = MathUtils.generate_random(tr_num1, tr_num2,"int")
	number_of_trials += number_of_trials_this_blk

	print("number_of_trials: ", number_of_trials)
	Global.num_of_trials = number_of_trials

	match _reward_chance_mode:
		"full":
			total_reward_chance = 1
		"random":
			var total_reward_chance_structure = [0.5,0.6,0.7,0.8,0.9,1]
			var _dice = MathUtils.generate_random(0,5,"int")
			total_reward_chance = total_reward_chance_structure[_dice] # set total reward chance
	var mu
	var variance
	# data generated, depend on distribution type
	for i in range(number_of_trials_this_blk):
		dice = MathUtils.generate_random(0,1,"float") # set total reward chance 
		if dice <= total_reward_chance:
			match distribution_type:
				"norm": # Normal distribution
					mu  =MathUtils.generate_random(_min, _max,"int")
					variance = MathUtils.generate_random(0, 0.5* mu,"float")
					variance = roundf(variance *1000) /100
					variance = variance /10
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
	
	for i in range(number_of_trials_this_blk):
		var random_h = MathUtils.generate_random(a,b)  # Press and hold reward
		var random_o = MathUtils.generate_random(c,d) # Opt-out reward
		hold_reward_template.append(random_h) # Hold reward
		opt_out_reward_template.append(random_o) # Opt-out reward
		hold_reward_template_this_blk.append(random_h) # Hold reward
		opt_out_reward_template_this_blk.append(random_o) # Opt-out reward
	

	var text1 = "reward_given_timepoint_template_this_blk : %s" % str(reward_given_timepoint_template_this_blk)
	var text2 = "hold_reward_template_this_blk : %s" % str(hold_reward_template_this_blk)
	var text3 = "opt_out_reward_template_this_blk : %s" % str(opt_out_reward_template_this_blk)
	var text4 = "total_reward_chance: %s" % str(total_reward_chance)
	var text5 = "number_of_trials_accumulated: %s" % str(number_of_trials)
	var text8 = "number_of_trials_this_blk: %s" % str(number_of_trials_this_blk)
	var text6 = "distribution_type: %s" % str(distribution_type)
	var text7 = "mu, variance: %s, %s" % [str(mu) , str(variance)]
	var text = text1 + "\n" + text2 + "\n" + text3 + "\n" + text4 + "\n" + text5 + "\n" + text8 + "\n" + text6 + "\n" + text7 + "\n"
	
	match save_loc:
		2: Global.text2 = text
		1: Global.text1 = text
		3: Global.text3 = text
		4: Global.text4 = text
		5: Global.text5 = text
		6: Global.text6 = text
		7: Global.text7 = text
		8: Global.text8 = text


#MARK: Reset
func init_trial():
	if trial_count >=number_of_trials:
		hide_nodes(exclude_nodes_for_hide_cards,original_states)
		trial_count += 1
		return 
	if initialized_flag == false:
		reset_scene_to_start_button()
		initialized_flag = true
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
	if_opt_left = MathUtils.generate_random(0,1,"float")
	init_trial_ui()


func reset_scene_to_start_button():
	# Reset the scene
	if trial_count > 1:
		original_states = hide_nodes(exclude_nodes_for_hide_cards,original_states)
		await get_tree().create_timer(_interval).timeout
	original_states_2 = hide_nodes([],original_states_2)
	await get_tree().create_timer(_interval).timeout
	quitButton.disabled = false
	startButton.disabled = false
	vboxstart.visible = true
	vboxbottom.visible = true
	

func reset_to_start_next_trial():
	if trial_count <= number_of_trials:
		init_trial()
		restore_nodes(original_states_2)
		restore_nodes(original_states)
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
			reset_scene_to_start_button()


func _on_opt_out_button_pressed():
	# 获取当前时间戳（秒）
	var current_time = Time.get_ticks_msec() 
	Global.wealth += opt_out_reward
	reward_given_flag = true
	_label_refresh(Global.wealth, num_of_press, "opt_out")
	record_press_data(current_time,trial_count, reward_given_flag, PressData.BtnType.OPT_OUT)
	reset_scene_to_start_button()

func _on_quit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _on_start_button_pressed():
	reset_to_start_next_trial()

# 封装记录按键数据的函数
func record_press_data(current_time, _tr_count, _reward_given_flag, btn_type: PressData.BtnType) -> void:
	# 创建PressData实例
	var new_press = PressData.new(current_time, _tr_count, _reward_given_flag, btn_type)
	# 添加到全局历史记录
	Global.press_history.append(new_press)
	#print("Recorded PressData: ", new_press)


# MARK: UI
func place_button(if_opt_left):
	# 获取窗口尺寸
	var window_size = get_viewport_rect().size
	var root = get_node("/root/Node2D" )
	root.set_anchors_and_offsets_preset( PRESET_FULL_RECT, PRESET_MODE_KEEP_SIZE)# this is important!
	LayoutManager.setup(vbox, PRESET_CENTER, 0.5, 0.25, window_size)
	LayoutManager.setup(vboxstart, PRESET_CENTER, 0.5, 0.5, window_size)
	LayoutManager.setup(vboxbottom, PRESET_CENTER, 0.5, 0.85, window_size)
	match if_opt_left:
		"left":
			LayoutManager.setup($MenuButton, PRESET_CENTER, 0.35, 0.6, window_size)
			LayoutManager.setup($MenuButton2, PRESET_CENTER, 0.65, 0.6, window_size)
		"right":
			LayoutManager.setup($MenuButton2, PRESET_CENTER, 0.35, 0.6, window_size)
			LayoutManager.setup($MenuButton, PRESET_CENTER, 0.65, 0.6, window_size)
	

func init_trial_ui():
	if if_opt_left >=0.5:
		place_button("left") # Initialize UI
	else:
		place_button("right") # Initialize UI with optout on the right


func _process(delta):
	init_trial_ui()


# MARK: Label Refresh
func _label_refresh(wealth,num_of_press,case_text):
	# 更新UI
	var hold_reward = reward
	var opt_out_reward = opt_out_reward
	hold_button_label.text = "" + str(hold_reward) 
	opt_out_button_label.text = "" + str(opt_out_reward) 
	label_2.text = " Your Tokens: " + str(wealth)
	match case_text:
		"opt_out":
			if opt_out_reward >= 0:
				label_1.text = "Opt Out! +" +str(opt_out_reward)
			else:	
				label_1.text = "Opt Out! "+str(opt_out_reward)
		"pressing...":
			label_1.text = str(num_of_press)
		"reward_given":
			label_1.text = "Tokens added! +" +str(reward)
			reward_given_flag = false
		"init":
			if trial_count <= 1:
				label_startbtn.text = "Press the Disk to Start"
				label_1.text = "Press any of the buttons to earn tokens"
			else:
				label_startbtn.text = ""
				label_1.text = ""
			quitButton.disabled = true
			startButton.disabled = true
			vboxstart.visible = false
			vboxbottom.visible = false
		"finish":
			label_1.text = "Finished!\n Close the window to exit"	
		_:
			pass
			


# Hide all child nodes and deactivate interactive elements
func hide_nodes(_list,_original_states):
	# 先保存所有子节点的原始状态
	_original_states.clear()
	for child in get_children():
		if child.name in _list:
			continue  # 跳过不需要隐藏的节点
	
		_original_states[child] = {
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
	return _original_states

# Restore all child nodes to their original state
func restore_nodes(states):
	for child in states:
		# 恢复可见性
		child.visible = states[child]["visible"]
		
		# 恢复互动状态
		if states[child]["disabled"] != null:
			child.disabled = states[child]["disabled"]
	hold_button.disabled = false
	opt_out_button.disabled = false
	
	states.clear()

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
