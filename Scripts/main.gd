extends Control
# Node reference
@onready var label_1 = $VBox/Label
@onready var label_2 = get_node("/root/Node2D/VBoxTop/Label2" )
@onready var hold_button = $MenuButton/HoldButton
@onready var menuButton = $MenuButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/HoldButton/Text
@onready var opt_out_button_label = $MenuButton2/OptOutButton/Text
@onready var vbox = $VBox
@onready var vboxstart = $VBoxSTART
@onready var vboxbottom = $VBoxBottom
@onready var vboxtop = $VBoxTop
@onready var quitButton = $VBoxBottom/QuitButton
@onready var startButton = $VBoxSTART/StartButton
@onready var label_startbtn = $VBoxBottom/Label
@onready var label_t = $VBox/TimerLabel  # 用于显示倒计时的标签

var time_left : int = 900
var countdownTimer
var _reusable_timer: Timer = null
var timer_case = 0
##### Global variables used in main.gd######
var total_reward_chance
var _interval : float
var mu_rwd_timepoint # mu, std results are generated from random fuctions 
var std_rwd_timepoint
var number_of_trials
var if_opt_left
var trial_count
var initialized_flag : bool = false
var num_of_press : int = 0
var reward_given_flag : bool = false
# Store the original state for recovery (processing possible initial hidden elements)
var original_states = {}
var original_states_2 = {}
var exclude_label_1
var exclude_nodes_for_srart_menu
# timer variable, timer can be disabled by "set_countdownTimer(false)"
var start_time : float = 0.0

# NORM
# refresh for each trial
var reward_given_timepoint
var hold_reward
var opt_out_reward
# refresh fro each block
var reward_given_timepoint_template 
var hold_vlaue_template
var opt_out_value_template 
# sessions settings
var total_reward_chance_structure
var mu_rwd_timepoint_change_list
var variance_rwd_timepoint_2mu_list
var h_value_list # seeds for "hold_vlaue_template"
var o_value_list # seeds for "opt_out_value_template"
# flat
var flat_min
var flat_max

##################

func _ready():
	ifrelease()
	get_tree().auto_accept_quit = false	
	set_countdownTimer(false)
	Global.init_write() # Initialize storage directory
	exclude_label_1 = [vbox.name]
	exclude_nodes_for_srart_menu = [vboxstart.name, vboxbottom.name, vboxtop.name]
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
	Global.press_history = [] # Clear new_press history
	Global.wealth = 0 # Initialize Global.wealth
	trial_count = 0
	number_of_trials = 0
	initialized_flag = false
	# Connect button signa
	hold_button.pressed.connect(_on_hold_button_pressed)
	opt_out_button.pressed.connect(_on_opt_out_button_pressed)
	startButton.pressed.connect(_on_start_button_pressed)
	quitButton.pressed.connect(_on_quit_button_pressed)
	# Generate a block of trials
	generate_all_trials(20,1) 
	save_data("head")
	# Start 1st Trial
	_reusable_timer = Timer.new()
	_reusable_timer.one_shot = true  # 单次触发模式
	add_child(_reusable_timer)  # 确保添加到场景树
	init_trial()
	_label_refresh(Global.wealth, "init")
	


func generate_all_trials(blk_num = 1, case_ = null):
	# Generate a block of trials, generate reward_given_timepoint and hold_reward given tremplate here
	
	match case_:
		
		1: # fixed for the first 2
			print("=======Case 2: Random hold_reward chance/value//distribution/tr_num =======")
			_interval = 0.5
			total_reward_chance_structure = [1, 0.95, 0.9, 0.85, 0.8, 0.75]
			reward_given_timepoint_template = []
			hold_vlaue_template=[]
			opt_out_value_template =[]
			mu_rwd_timepoint_change_list = [0, 0.25, -0.25, 0.5, -0.5]
			variance_rwd_timepoint_2mu_list = [0.5, 0.25]
			for i in range(1,blk_num+1):
				if i == 1:
					blk_("full", "norm_1st", 1, "fixed", 20,30) 
				elif i == 2:
					blk_("2nd", "norm_after_1st", 2,"fixed", 20,30)
				else:
					var dice_ = MathUtils.generate_random(0,1,"int")
					if dice_ == 0:
						blk_("random_distribution", "norm_after_1st", i, "RANDOM",20,30)
					else:
						blk_("random_chance", "norm_after_1st", i, "RANDOM",20,30)
			
			Global.write_sessionDesign_to_file(Global.filename_config)

		2: # no fixed 1 and 2
			_interval = 0.5
			total_reward_chance_structure = [1, 0.95, 0.9, 0.85, 0.8, 0.75]
			reward_given_timepoint_template = []
			hold_vlaue_template=[]
			opt_out_value_template =[]
			mu_rwd_timepoint_change_list = [0, 0.25, -0.25, 0.5, -0.5]
			variance_rwd_timepoint_2mu_list = [0.5, 0.25]
			for i in range(1,blk_num+1):
				var dice_ = MathUtils.generate_random(0,1,"int")
				if dice_ == 0:
					print("\ndistribution is goint to change")
					if i == 1:
						blk_("random_distribution", "norm_after_1st", i, "RANDOM",20,30,0.9,20,10.0)
					else:
						blk_("random_distribution", "norm_after_1st", i, "RANDOM",20,30)
				else:
					print("\nchance is going to change")
					if i == 1:
						blk_("random_chance", "norm_after_1st", i, "RANDOM",20,30, 0.9,20,10.0)
					else:
						blk_("random_chance", "norm_after_1st", i, "RANDOM",20,30)
			
			Global.write_sessionDesign_to_file(Global.filename_config)
	
		3:# Because the game will habitually crash after running for a few minutes,
		  # before solving the crash problem, you can run this mode to package each blk. 
		  # In this mode, blk_num does not represent the number of blks, but the type of blk
			_interval = 0.5
			total_reward_chance_structure = [1, 0.95, 0.9, 0.85, 0.8, 0.75]
			reward_given_timepoint_template = []
			hold_vlaue_template=[]
			opt_out_value_template =[]
			variance_rwd_timepoint_2mu_list = [0.5, 0.25]
			mu_rwd_timepoint_change_list = [0, 0.25, -0.25, 0.5, -0.5]
		  # blk(_reward_chance_mode, _distribution_type, 
		  # 	save_loc, _value_type ,
		  # 	tr_num1, tr_num2,
		  #		 _previous_total_reward_chance = 0, _previous_mu=0, _previous_std=0):
			if blk_num == 1:
				# total_reward_chance = 1, random norm,  ~ N(20,10)
				blk_("full", "norm_1st", 1, "fixed", 20,60) 
			elif blk_num == 2:
				#  fixed norm,  ~ N(20,10)
				# total_reward_chance = 0.9, no matter what " _previous_total_reward_chance" is
				blk_("2nd", "norm_after_1st", 2,"fixed", 20,60,0,20,10)
			elif blk_num == 3:
				# total_reward_chance = 0.9, random norm, EXCEPT for ~ N(20,10)
				blk_("random_distribution", "norm_after_1st", 3, "RANDOM",20,60,0.9,20,10)
			elif blk_num == 4:
				# total_reward_chance_structure = [1, 0.95, 0.9, 0.85, 0.8, 0.75]
				#  fixed norm,  ~ N(20,10)
				blk_("random_chance", "norm_after_1st", 4, "RANDOM",20,60,0.9,20,10)
			elif blk_num == 5:
				# total_reward_chance = 0.8, random norm, EXCEPT for ~ N(20,10)
				blk_("random_distribution", "norm_after_1st", 3, "RANDOM",20,60,0.8,20,10)
			elif blk_num == 6:
				# total_reward_chance = 0.75, random norm, EXCEPT for ~ N(20,10)
				blk_("random_distribution", "norm_after_1st", 3, "RANDOM",20,60,0.75,20,10)
			Global.write_sessionDesign_to_file(Global.filename_config)

		4:
			pass


# MARK: BLK
func blk_(_reward_chance_mode, _distribution_type, save_loc,
		# rwd value:
		_value_type ,
		# tr_num range:
		tr_num1, tr_num2,
		 _previous_total_reward_chance = 0.0, _previous_mu=0, _previous_std=0.0):
			
	var dice_if_rwd_given
	var timepoint
	var reward_given_timepoint_template_this_blk = []
	var hold_reward_template_this_blk = []
	var opt_out_reward_template_this_blk = []
	# rnd tr_num
	var number_of_trials_this_blk = MathUtils.generate_random(tr_num1, tr_num2,"int")
	number_of_trials += number_of_trials_this_blk

	print("number_of_trials: ", number_of_trials)
	Global.num_of_trials = number_of_trials
	var previous_total_reward_chance
	if _previous_total_reward_chance == 0:
		previous_total_reward_chance = total_reward_chance
	else:
		previous_total_reward_chance = _previous_total_reward_chance

	match _reward_chance_mode:
		"full":
			total_reward_chance = 1
			print("total_reward_chance: ",total_reward_chance)
		"random_distribution":
			total_reward_chance = previous_total_reward_chance 
			print("total_reward_chance: ",total_reward_chance)
		"random_chance":
			var _dice 
			while true:
				_dice = MathUtils.generate_random(0,total_reward_chance_structure.size()-1,"int")
				if total_reward_chance_structure[_dice] != previous_total_reward_chance:
					break
			total_reward_chance = total_reward_chance_structure[_dice] # set total hold_reward chance
			print("total_reward_chance: ",total_reward_chance)
		"2nd":
			total_reward_chance = 0.9
			
	# from Block N to Block N+1, we either change
	# ONLY the distribution, 
	# or ONLY the hold_reward reliability (%)
	if _distribution_type == "norm_1st":
		blk_distribution(_distribution_type)
		print("mu_rwd_timepoint, std_rwd_timepoint: ", mu_rwd_timepoint, ", ", std_rwd_timepoint)
	elif _distribution_type == "norm_after_1st" and previous_total_reward_chance == total_reward_chance:
		if mu_rwd_timepoint == null :
			blk_distribution(_distribution_type,0,0,_previous_mu)
		else:
			blk_distribution(_distribution_type)
		print("change distribution. mu_rwd_timepoint, std_rwd_timepoint: ", mu_rwd_timepoint, ", ", std_rwd_timepoint)
	elif _distribution_type == "norm_after_1st" and previous_total_reward_chance != total_reward_chance:
		print("change total_reward_chance: ",total_reward_chance)
		if mu_rwd_timepoint == null :
			mu_rwd_timepoint = _previous_mu
			std_rwd_timepoint = _previous_std
	else:
		print("error: the case is not defined")


	# based on the given distribution parameters,
	# generate reward_given_timepoint template, which serves as the the "right" answer for trials
	# all about tokens
	for i in range(number_of_trials_this_blk):
		# if reward is given
		dice_if_rwd_given = MathUtils.generate_random(0,1,"float") # set total hold_reward chance 
		if dice_if_rwd_given <= total_reward_chance:	
			# if given, when?
			match _distribution_type:
			# the cases here should mathch the cases in the fuction "blk_distribution(_distribution_type)"
			# that's why there are two cases are identical.

				"norm_after_1st": # Normal distribution
					while true: # Avoid generating negative numbers
						timepoint = MathUtils.normrnd(mu_rwd_timepoint, std_rwd_timepoint)
						if timepoint > 0:
							break 
					timepoint = roundi(timepoint)
				"norm_1st":# Normal distribution
					while true: # Avoid generating negative numbers
						timepoint = MathUtils.normrnd(mu_rwd_timepoint, std_rwd_timepoint)
						if timepoint > 0:
							break 
					timepoint = roundi(timepoint)
				"flat":
					timepoint = MathUtils.generate_random(flat_min, flat_max,"int")

			reward_given_timepoint_template.append(timepoint)
			reward_given_timepoint_template_this_blk.append(timepoint)
		else:
			reward_given_timepoint_template.append(null)
			reward_given_timepoint_template_this_blk.append(null)

		# how much to give as reward
		match _value_type:
			"fixed":
				h_value_list= [10]
				o_value_list = [0]
				var dice_h = MathUtils.generate_random(0,h_value_list.size()-1,"int")
				var random_h = h_value_list[dice_h]
				hold_vlaue_template.append(random_h)
				hold_reward_template_this_blk.append(random_h) # Hold hold_reward
				var dice_o = MathUtils.generate_random(0,o_value_list.size()-1,"int")
				var random_o = o_value_list[dice_o]
				opt_out_value_template.append(random_o) # Opt-out hold_reward
				opt_out_reward_template_this_blk.append(random_o) # Opt-out hold_reward
			"RANDOM":
				h_value_list= [0,5,10,15,20]
				var dice_h = MathUtils.generate_random(0,h_value_list.size()-1,"int")
				var random_h = h_value_list[dice_h]
				hold_vlaue_template.append(random_h) # Hold hold_reward
				hold_reward_template_this_blk.append(random_h) # Hold hold_reward
				if random_h >=5:
					o_value_list = [-15,-10,-5, 0, 5]
				elif random_h == 0:
					o_value_list = [-15,-10,-5, 0]
				var dice_o = MathUtils.generate_random(0,o_value_list.size()-1,"int")
				var random_o = o_value_list[dice_o]
				opt_out_value_template.append(random_o) # Opt-out hold_reward
				opt_out_reward_template_this_blk.append(random_o) # Opt-out hold_reward
			
# save the configuration with data	
	var text1 = "reward_given_timepoint_template_this_blk : \n%s" % str(reward_given_timepoint_template_this_blk)
	var text2 = "hold_reward_template_this_blk : \n%s" % str(hold_reward_template_this_blk)
	var text3 = "opt_out_reward_template_this_blk :\n %s" % str(opt_out_reward_template_this_blk)
	var text4 = "total_reward_chance: %s" % str(total_reward_chance)
	var text5 = "number_of_trials_accumu_rwd_timepointlated: %s" % str(number_of_trials)
	var text8 = "number_of_trials_this_blk: %s" % str(number_of_trials_this_blk)
	var text6 = "distribution_type: %s" % str(_distribution_type)
	var text7 = "mu_rwd_timepoint, std_rwd_timepoint: %s, %s" % [str(mu_rwd_timepoint) , str(std_rwd_timepoint)]
	var text =  text4 + "\n" + text7 + "\n" +text8 +  "\n" + text6 + "\n" +text1 + "\n" + text2 + "\n" + text3 + "\n" + text5 + "\n" 
	
	if save_loc<=36:
		var save_loc_ = "text"+str(save_loc)
		Global.set(save_loc_, text)
	else:
		print("save_loc too large")


func blk_distribution(_distribution_type, _min=0,_max=0,_previous_mu=0):
	if _previous_mu ==0:
		pass
	else:
		# Specify a previous distribution parameter
		mu_rwd_timepoint = _previous_mu
	
	match _distribution_type:
		"norm_after_1st": # Normal distribution
			var dice_mu_rwd_timepoint
			var new_mu_rwd_timepoint
			var new_std_rwd_timepoint
			while true: # Avoid same as previous
				while true: # Avoid generating negative numbers
					dice_mu_rwd_timepoint = MathUtils.generate_random(0,mu_rwd_timepoint_change_list.size()-1,"int")
					var mu_rwd_timepoint_change = mu_rwd_timepoint_change_list[dice_mu_rwd_timepoint]
					new_mu_rwd_timepoint  = mu_rwd_timepoint * (1+mu_rwd_timepoint_change)
					new_mu_rwd_timepoint = roundi(new_mu_rwd_timepoint)
					if new_mu_rwd_timepoint >= 10:
						break
					else: 
						mu_rwd_timepoint_change_list.erase(dice_mu_rwd_timepoint)
						print("removed a dice face")
		
				var dice_variance_rwd_timepoint_2mu = MathUtils.generate_random(0,variance_rwd_timepoint_2mu_list.size()-1,"int")
				new_std_rwd_timepoint = new_mu_rwd_timepoint* variance_rwd_timepoint_2mu_list[dice_variance_rwd_timepoint_2mu]
				new_std_rwd_timepoint = roundf(new_std_rwd_timepoint *1000) /100
				new_std_rwd_timepoint = new_std_rwd_timepoint /10
				if new_std_rwd_timepoint != mu_rwd_timepoint:
					break

			mu_rwd_timepoint = new_mu_rwd_timepoint
			std_rwd_timepoint = new_std_rwd_timepoint

		"flat": # flat distribution
			flat_min = _min
			flat_max = _max
		
		"norm_1st":
			mu_rwd_timepoint = 20
			std_rwd_timepoint = 10
			std_rwd_timepoint = roundf(std_rwd_timepoint *1000) /100
			std_rwd_timepoint = std_rwd_timepoint /10
	



#MARK: Reset
func init_trial():
	if trial_count >=number_of_trials:
		hide_nodes(exclude_label_1,original_states)
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
	num_of_press = 0
	Global.press_history.clear()
	# Initialization rewards
	hold_reward = hold_vlaue_template[trial_count-1]
	opt_out_reward = opt_out_value_template[trial_count-1]
	reward_given_timepoint = reward_given_timepoint_template[trial_count-1]
	print("trial", trial_count, "\nreward: ", hold_reward,"\t" ,opt_out_reward, "\treward_given_timepoint: ", reward_given_timepoint)
	if_opt_left = MathUtils.generate_random(0,1,"float")
	init_trial_ui()


func save_data(_case):
	match _case:
		"head":
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE)
			file.store_line("Tokens: %d\n" % Global.wealth)
			file.store_line("# Button type: 0:hold; 1:opt-out")  # CSV列标题
			file.store_line("# The following is CSV format data, one press record per line")
			file.store_line("head: trial num, press_num, timestamp_ms, reward_flag, button_type\n")
			file.close()

		"body":
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE)
					# CSV format: Use commas to separate fields, and strings need to be wrapped in quotes when they contain commas
			var csv_line = ""
			for press in Global.press_history:
				csv_line = "%d,%d ,%d,%s,%s" % [
						press.trial_count,
						num_of_press,  # 序号
						press.timestamp,  # 时间戳
						str(press.rwd_marker).to_lower(),  # 奖励标记（转为小写，如true/false）
						press.btn_type_marker  # 按键类型
					]
				file.seek_end()
				file.store_line(csv_line)
			file.close()
			Global.press_history.clear()
		"summary":
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE) # FileAccess.READ_WRITE will append, while FileAccess.WRITE will overwrite the whole file
			file.seek(0)
			file.store_line("Tokens: %d" % Global.wealth)
			file.close()


func reset_scene_to_start_button():
	save_data("body")
	# Reset the scene
	if trial_count >= 1:
		original_states = hide_nodes(exclude_label_1,original_states)
		_reusable_timer.wait_time = _interval * 2
		_reusable_timer.start()
		await _reusable_timer.timeout
	original_states_2 = hide_nodes([],original_states_2)
	_reusable_timer.wait_time = _interval
	_reusable_timer.start()
	await _reusable_timer.timeout
	quitButton.disabled = false
	startButton.disabled = false
	vboxstart.visible = true
	vboxbottom.visible = true
	vboxtop.visible = true
	timer_case = 0
	

func reset_to_start_next_trial():
	if trial_count <= number_of_trials:
		init_trial()
		restore_nodes(original_states_2)
		restore_nodes(original_states)
		# Reset status
		_label_refresh(Global.wealth,"init")

	if trial_count > number_of_trials:
		_label_refresh(Global.wealth,"finish")



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
		_label_refresh(Global.wealth,"pressing...")
		record_press_data(current_time, trial_count, reward_given_flag, PressData.BtnType.HOLD)
		
	elif reward_given_flag == false:
		num_of_press += 1
		_label_refresh(Global.wealth,"pressing...")
		if num_of_press < reward_given_timepoint:
			record_press_data(current_time, trial_count, reward_given_flag, PressData.BtnType.HOLD)
		if num_of_press == reward_given_timepoint:
			Global.wealth+= hold_reward
			reward_given_flag = true
			print("hold-reward_given_flag  ",reward_given_flag)
			_label_refresh(Global.wealth,"reward_given")
			record_press_data(current_time, trial_count, true, PressData.BtnType.HOLD)
			reset_scene_to_start_button()


func _on_opt_out_button_pressed():
	# 获取当前时间戳（秒）
	var current_time = Time.get_ticks_msec() 
	Global.wealth += opt_out_reward
	reward_given_flag = true
	_label_refresh(Global.wealth, "opt_out")
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
	Global.press_history.append(new_press)
	

# MARK: UI
func place_button(_if_opt_left):
	# 获取窗口尺寸
	var window_size = get_viewport_rect().size
	var root = get_node("/root/Node2D" )
	root.set_anchors_and_offsets_preset( PRESET_FULL_RECT, PRESET_MODE_KEEP_SIZE)# this is important!
	if menuButton.visible == true:
		Utils.setup_layout(vbox, PRESET_CENTER, 0.5, 0.85, window_size)
	else:
		Utils.setup_layout(vbox, PRESET_CENTER, 0.5, 0.5, window_size)
	Utils.setup_layout(vboxstart, PRESET_CENTER, 0.5, 0.5, window_size)
	Utils.setup_layout(vboxbottom, PRESET_CENTER, 0.5, 0.85, window_size)
	Utils.setup_layout(vboxtop, PRESET_CENTER, 0.5, 0.15, window_size)
	match _if_opt_left:
		"left":
			Utils.setup_layout($MenuButton, PRESET_CENTER, 0.35, 0.4, window_size)
			Utils.setup_layout($MenuButton2, PRESET_CENTER, 0.65, 0.4, window_size)
		"right":
			Utils.setup_layout($MenuButton2, PRESET_CENTER, 0.35, 0.4, window_size)
			Utils.setup_layout($MenuButton, PRESET_CENTER, 0.65, 0.4, window_size)
	

func init_trial_ui():
	if if_opt_left >=0.5:
		place_button("left") # Initialize UI
	else:
		place_button("right") # Initialize UI with optout on the right


func _process(_delta):
	init_trial_ui()


# MARK: Label Refresh
func _label_refresh(wealth,case_text):
	# 更新UI
	if  hold_reward != null:
		if hold_reward <= 0:
			hold_button_label.text = "" + str(hold_reward)
		else:
			hold_button_label.text = "+" + str(hold_reward)
		if opt_out_reward <= 0:
			opt_out_button_label.text = "" + str(opt_out_reward) 
		else:
			opt_out_button_label.text = "+" + str(opt_out_reward)
	
	label_2.text = " Your Tokens: " + str(wealth)
	var neutralcolor = label_startbtn.label_settings.font_color
	var positivecolor = Color("GREEN")
	var negativecolor = Color("PLUM")
	match case_text:
		"opt_out":
			label_1.label_settings.font_size = 72
			if opt_out_reward > 0:
				label_1.text = "Tokens! + " +str(opt_out_reward)
				label_1.label_settings.font_color = positivecolor
			elif opt_out_reward == 0:
				label_1.text = " + " +str(opt_out_reward)
				label_1.label_settings.font_color = neutralcolor
			else:	
				label_1.text = "Opt Out! "+str(opt_out_reward)
				label_1.label_settings.font_color = negativecolor
		"reward_given":
			label_1.label_settings.font_size = 72
			if hold_reward == 0:
				label_1.text = "+ " +str(hold_reward)
				label_1.label_settings.font_color = neutralcolor
			else:
				label_1.text = "Tokens! + " +str(hold_reward)
				label_1.label_settings.font_color = positivecolor
			reward_given_flag = false

		"pressing...":
			label_1.text = ""
			#label_1.label_settings.font_size = 36
			#label_1.text = str(num_of_press)# need t add num_of_press to the func parameter
			#label_1.label_settings.font_color = neutralcolor
		"init":
			label_1.label_settings.font_size = 36
			label_1.label_settings.font_color = neutralcolor
			if trial_count <= 3:
				label_startbtn.text = "Press the Disk \n to Start"
				if trial_count <= 1:
					label_1.text = "Press BLUE once to give up, \n or keep pressing RED to earn more tokens"
				if trial_count == 2:
					label_1.text = "Value on buttons are tokens you can get\n if you new_press them."
				if trial_count == 3:
					label_1.text = "If you change your mind, \n you can always opt out via the BLUE one."
			else:
				label_startbtn.text = ""
				label_1.text = ""
			quitButton.disabled = true
			startButton.disabled = true
			vboxstart.visible = false
			vboxbottom.visible = false
			vboxtop.visible = false
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
			"visible": child.visible if "visible" in child else null,	
			"disabled": child.disabled if "disabled" in child else null
		}
		if "visible" in child:
			child.visible = false
		if "disabled" in child:
			child.disabled = true						

	return _original_states

# Restore all child nodes to their original state
func restore_nodes(states):
	for child in states:
		# 恢复可见性
		if "visible" in child:
			child.visible = states[child]["visible"]
		# 恢复互动状态
		if states[child]["disabled"] != null:
			child.disabled = states[child]["disabled"]
	hold_button.disabled = false
	opt_out_button.disabled = false
	
	states.clear()

# MARK: Timer/End
func set_countdownTimer(ifset:bool):
	if ifset == true:
		countdownTimer = Timer.new()
		label_t.text = "Time Left: " + str(time_left) + " s"
		countdownTimer.autostart = false
		countdownTimer.one_shot = false
		vbox.add_child(countdownTimer) 
		countdownTimer.start(1)
		countdownTimer.timeout.connect(_on_countdown_timer_timeout)
	else:
		label_t.text = "" 


func _on_countdown_timer_timeout():
	time_left -= 1
	
	if time_left >= 0:
		label_t.text = "Time Left: " + str(time_left) +" s"
	else:
		label_t.text = "Time's Up!"
		countdownTimer.stop()  
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)



func _notification(what:int)->void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data("summary")
		#cleanup()
		get_tree().quit()

# 正确释放动态创建的节点
func cleanup():
	for child in get_children():
		if child is CanvasItem:
			child.queue_free()  # 标记节点在下一帧释放
