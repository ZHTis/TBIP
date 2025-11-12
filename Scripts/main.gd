extends Control
# Node reference
@onready var label_1 = $VBox/Label1
@onready var label_t = $VBox/TimerLabel # Label used to display countdown
@onready var label_discript = $LabelDscript

@onready var label_info_top = $VBoxTop/HBoxTop/HBoxTop/LabelLeft
@onready var label_value_info_top = $VBoxTop/HBoxTop/HBoxTop/LabelRight
@onready var label_info_mid = $VBoxTop/HBoxTop/HBoxMid/LabelLeft
@onready var label_value_info_mid = $VBoxTop/HBoxTop/HBoxMid/LabelRight
@onready var label_info_bottom = $VBoxTop/HBoxBottom/LabelUp
@onready var label_value_info_bottom = $VBoxTop/HBoxBottom/LabelDown
@onready var vboxtop = $VBoxTop

@onready var hold_button = $MenuButton/HoldButton
@onready var menuButton = $MenuButton
@onready var opt_out_button = $MenuButton2/OptOutButton
@onready var hold_button_label = $MenuButton/HoldButton/Text
@onready var opt_out_button_label = $MenuButton2/OptOutButton/Text
@onready var vbox = $VBox

@onready var vboxstart = $VBoxSTART
@onready var vboxbottom = $VBoxBottom
@onready var quitButton = $VBoxBottom/QuitButton
@onready var startButton = $VBoxSTART/StartButton
@onready var label_startbtn = $VBoxBottom/Label

@onready var sound = $AudioStreamPlayer
@onready var colorRect = $ColorRect
@onready var infer_base_timer = $InferBaseTimer

var hascountdownTimertriggered = false
var countdownTimer : Timer
var intervalTimer: Timer 
var earningTimer=[0.0,0.0,0.0]
enum DistributionType{FLAT,NORM_1ST, NORM_AFTER_1ST, NORM_1ST_CUSTOM, SET1,SET2,SET3,SET4}
var ValueSets
enum SampleType{POOL, SLICED,}
enum BtnType { START, OPT_OUT, INVALID, WAIT, HOLD,}
##### Global variables used in main.gd######
var TOTAL_REWARD_CHANCE
var PREVIOUS_TOTAL_REWARD_CHANCE
var UNIT_INTERVAL: float
var MU_RWD_TIMEPOINT # mu, std results are generated from random fuctions
var STD_RWD_TIMEPOINT
var NUMBER_OF_TRIALS = 0
var IF_OPT_LEFT = MathUtils.generate_random(0, 1, "float")
var default_exception_proportion = float(0.0)
var trial_count = 0 
var trial_timeout : bool = false
# var only used in time based
var IS_HOLDING : bool = false
var HAS_BEEN_PRESSED : bool = false
var DURATION 
# infer_base_timer variable 
var START_TIME: float = 0.0
# trial variables
var INITIALIZED_FLAG: bool = false
var NUM_OF_PRESS: int = 0
var REWARD_GIVEN_FLAG: bool = false
var h_value_list # seeds for "hold_vlaue_template"
var o_value_list # seeds for "opt_out_value_template"
# Store the original state for recovery (processing possible initial hidden elements)
var original_states = {}
var original_states_2 = {}
var EXCLUDE_LABEL_1 
var EXCLUDE_NODES_FOR_SRART_MENU 
var OPT_LEFT_FLAG
var blk_flag
var BLK_SWITCH
var blks_paras = []
var blk_labels = []
var default_color
var DIMCOLOR = Color("58110b83")
# NORM
# refresh for each trial
var reward_given_timepoint
var hold_reward
var opt_out_reward
var trial_start_time
var task_show_time
var actual_reward_given_timepoint
var actual_reward_value
# refresh for each block
var reward_given_timepoint_template
var hold_vlaue_template
var opt_out_value_template
# sessions settings
var total_reward_chance_structure
var mu_rwd_timepoint_change_list
var variance_rwd_timepoint_2mu_list
var h_value_listRND # case "RANDOM" options
var o_value_listRND
# flat
var FLAT_MIN
var FLAT_MAX
var speed_up_mode = Global.speed_up_mode
var auto_mode = Global.auto_mode
#for agent
var agent_action_timer = Timer.new()
var agent_pos=Vector2.ZERO
var agent_event
var agent_potential_positions = [Vector2(300, 400), Vector2(700, 400), Vector2(1100, 400)]
var task_on
##################

func _ready():
	get_tree().auto_accept_quit = false
	Global.init_write() # Initialize storage directory
	print("auto_mode ", auto_mode)
	if Global.auto_mode:
		_agent() # Start the agent if auto_mode is enabled
	Global.press_history = [] # Clear new_press history
	Global.wealth = 0 # Initialize Global.wealth
	trial_count = 0
	INITIALIZED_FLAG = false
	NUMBER_OF_TRIALS = 0
	EXCLUDE_LABEL_1 = [vbox.name]
	EXCLUDE_NODES_FOR_SRART_MENU = [vboxstart.name, vboxbottom.name, vboxtop.name]
	default_color = hold_button.self_modulate
	generate_all_trials(5) # case 5: from config file
	init_task() # Initialize the task
	


# MARK: TASK
func init_task(): # Initialize task, BLK design
	# timer for calculate earnings predefined 
	earningTimer=[0.0,0.0,0.0]
	# timer for wait too long warning
	countdownTimer = one_time_timer(countdownTimer)
	countdownTimer.timeout.connect(_on_countdown_timer_timeout)
	# Start 1st Trial
	intervalTimer = one_time_timer(intervalTimer)

	colorRect.visible = false
	startButton.pressed.connect(_on_start_button_pressed)
	quitButton.pressed.connect(_on_quit_button_pressed)
	if  Global.inference_type== Global.InferenceFlagType.time_based:
		hold_button.pressed.connect(_on_start_to_wait_button_pressed)
		opt_out_button.pressed.connect(_on_opt_out_button_pressed)
		infer_base_timer.timeout.connect(_on_infer_baser_timer_timeout)

	if  Global.inference_type== Global.InferenceFlagType.press_based:
		# press based
		# Connect button signa
		hold_button.pressed.connect(_on_hold_button_pressed)
		opt_out_button.pressed.connect(_on_opt_out_button_pressed)
	
	save_data("head")

	quitButton.disabled = true
	startButton.disabled = true
	vboxstart.visible = false
	vboxbottom.visible = false
	vboxtop.visible = false
	label_startbtn.visible = false
	prepare_init_trial()

# MARK: INIT
func prepare_init_trial():
	countdownTimer.stop()
	trial_timeout = false
	if Global.inference_type == Global.InferenceFlagType.time_based:
		HAS_BEEN_PRESSED = false
		IS_HOLDING = false
		DURATION = 0.0
		START_TIME = 0.0
	if Global.inference_type == Global.InferenceFlagType.press_based:
		NUM_OF_PRESS = 0 

	if trial_count >= NUMBER_OF_TRIALS:
		hide_nodes(EXCLUDE_LABEL_1, original_states) #vbox hide
		trial_count += 1
		return
	if INITIALIZED_FLAG == false:# the 1st trial
		blk_flag = 1
		_label_refresh(Global.wealth, "init")
		reset_scene_to_start_button()
		INITIALIZED_FLAG = true
		return

	# Initialization rewards
	hold_reward = hold_vlaue_template[trial_count]
	opt_out_reward = opt_out_value_template[trial_count]
	trial_count += 1 # trial count from 1 while list index from 0
	REWARD_GIVEN_FLAG = false
	if reward_given_timepoint_template[trial_count-1] != null:
		reward_given_timepoint = reward_given_timepoint_template[trial_count-1] /speed_up_mode
	else:
		reward_given_timepoint = reward_given_timepoint_template[trial_count-1]

	print("blk:",blk_labels[trial_count-1],"\ttrial\t", trial_count, "\nreward: ", hold_reward, "\t", opt_out_reward, "\treward_given_timepoint: ", reward_given_timepoint)
	# place_options_left_or_right() refresh with window size and excute each frame 
	# but we don't want to change left or right each frame only each trial so chose numbe is seperate from the function
	IF_OPT_LEFT = MathUtils.generate_random(0, 1, "float")
	place_options_left_or_right() 

	_label_refresh(Global.wealth, "init")


func generate_all_trials(case_, blk_num = 1):
	# Generate a block of trials, generate reward_given_timepoint and hold_reward given tremplate here
	print("=======Generate a block of trials=======","\t",case_,"\t", blk_num)
	match case_:
		4: # from config
			var user_path = ProjectSettings.globalize_path("user://")
			var path = user_path + "task_config.cfg"
			var configuration = ConfigFile.new()
			if configuration.load(path) != 0:
				return
			blk_num = configuration.get_sections().size()
		
			reward_given_timepoint_template = []
			hold_vlaue_template = []
			opt_out_value_template = []
			var reward_chance_mode

			var i = 1
			var a 
			for blk in configuration.get_sections():
				blk_flag ="blk%s"%i
				print("section: ",blk)
				a = load_from_config(blk,
					configuration.get_value(blk, "blkPara_change_distr_or_chance","none"),
					configuration.get_value(blk, "blkPara_distr_type"),
					configuration.get_value(blk, "blkPara_distr_para_1"),
					configuration.get_value(blk, "blkPara_distr_para_2"),
					configuration.get_value(blk, "blkPara_chance"),
					configuration.get_value(blk, "blkPara_value_list"),
					configuration.get_value(blk, "blkPara_value_list2"),
					configuration.get_value(blk, "blkPara_tr_num_num_range")
				)
				# the structure of  result is: 
					#0 [ _reward_chance_mode, 
					#1 _total_reward_chance_structure,
					# _mu_rwd_timepoint_change_list,
					#3 _variance_rwd_timepoint_2mu_list,
					# _h_value_list_,
					#5 _o_value_list_,
					# _tr_num_n_range[0],
					# _tr_num_n_range[1] 
				reward_chance_mode = a[0]
				h_value_listRND = a[4]
				o_value_listRND = a[5]
				total_reward_chance_structure = a[1]
				mu_rwd_timepoint_change_list = a[2]
				variance_rwd_timepoint_2mu_list = a[3]
				print(
					"reward_chance_mode ", reward_chance_mode
					, "\ntotal_reward_chance_structure ", total_reward_chance_structure
					, "\nmu_rwd_timepoint_change_list ", mu_rwd_timepoint_change_list.size()
					, "\nvariance_rwd_timepoint_2mu_list ", variance_rwd_timepoint_2mu_list
					, "\nh_value_listRND ", h_value_listRND
					, "\no_value_listRND ", o_value_listRND
					)

				if str(blk) == "blk1":
					blk_(0.5, "random_chance", DistributionType.NORM_1ST_CUSTOM,"A", a[6], a[7],SampleType.SLICED, 5)
				else:
					blk_(0.5, reward_chance_mode, DistributionType.NORM_1ST_CUSTOM,"B", a[6], a[7],SampleType.SLICED, 2)
				i += 1
			Global.write_sessionDesign_to_file(Global.filename_config)
		5:
			BLK_SWITCH = [3,7,11]
			if blk_num == 1:
				blk_num = BLK_SWITCH[-1] 
			Global.inference_type = Global.InferenceFlagType.time_based
			reward_given_timepoint_template = []
			hold_vlaue_template = []
			opt_out_value_template = []
			ValueSets = [5,-1, 25,-1,5,-25]
			var except_ratio = 0.5
			var  blk_vlaue_sets = [DistributionType.SET1, DistributionType.SET2]
			#[DistributionType.SET4, DistributionType.SET3]
			#[DistributionType.SET1, DistributionType.SET2]
			#[DistributionType.SET3, DistributionType.SET4]
			#[DistributionType.SET2, DistributionType.SET1]

			for i in range(1, blk_num + 1):
				blk_flag ="blk%s"%i
				print("BLK_SWITCH ",BLK_SWITCH)
				print("###### blk%s"%i)
				if i <= 2:	
					blk_(0.5, "full", blk_vlaue_sets[0],5)
				if i > 2 and i<=(BLK_SWITCH[0]):
					total_reward_chance_structure = [1]
					blk_(0.5, "chance_allow_repeat", blk_vlaue_sets[0],10,10, "B",0.2,SampleType.SLICED, 2)
				if i > (BLK_SWITCH[0]) and i<=(BLK_SWITCH[1]):
					total_reward_chance_structure = [0.7]
					blk_(0.5, "chance_allow_repeat", blk_vlaue_sets[0],40,40, "B",except_ratio, SampleType.SLICED, 2)
				if i > (BLK_SWITCH[1]) and i<=blk_num:
					total_reward_chance_structure = [0.7]
					blk_(0.5, "chance_allow_repeat", blk_vlaue_sets[1],40,40, "B",except_ratio, SampleType.SLICED, 2)
					
			Global.write_sessionDesign_to_file(Global.filename_config)


# MARK: BLK
func blk_(_interval, _reward_chance_mode, _distribution_type,
		# tr_num range:
		tr_num1, 
		tr_num2=tr_num1,
		# rwd value & eception_proportion:
		_value_type="A",
		_exception_proportion = default_exception_proportion,
		# vicent
		_sample_type = SampleType.SLICED, _slice_size = 5,
		# fetch from previous blk
		_previous_total_reward_chance = 0.0, _previous_mu = 0, _previous_std = 0.0):

	UNIT_INTERVAL = _interval /speed_up_mode
	var dice_if_rwd_given
	var timepoint
	var blk_para = BLKPara.new()
	
	var reward_signal_given_timepoint_template_this_blk = []
	var hold_reward_template_this_blk = []
	var opt_out_reward_template_this_blk = []

	
	# rnd tr_num
	var number_of_trials_this_blk = MathUtils.generate_random(tr_num1, tr_num2, "int")
	NUMBER_OF_TRIALS += number_of_trials_this_blk
	print("cumulated NUMBER_OF_TRIALS: ", NUMBER_OF_TRIALS)
	Global.num_of_trials = NUMBER_OF_TRIALS
	var blk_label = []
	blk_label.resize(number_of_trials_this_blk)
	blk_label.fill(blk_flag)
	blk_labels.append_array(blk_label)

	if _previous_total_reward_chance == 0:
		PREVIOUS_TOTAL_REWARD_CHANCE = TOTAL_REWARD_CHANCE
	else:
		PREVIOUS_TOTAL_REWARD_CHANCE = _previous_total_reward_chance

	match _reward_chance_mode:
		"full":
			TOTAL_REWARD_CHANCE = 1
			print("TOTAL_REWARD_CHANCE: ", TOTAL_REWARD_CHANCE)
		"random_distribution":
			TOTAL_REWARD_CHANCE = PREVIOUS_TOTAL_REWARD_CHANCE
			print("TOTAL_REWARD_CHANCE: ", TOTAL_REWARD_CHANCE)
		"random_chance": #cannot be the same as previous
			var _dice
			var _dicelen = total_reward_chance_structure.size()
			while true:
				_dice = MathUtils.generate_random(0, _dicelen - 1, "int")
				if total_reward_chance_structure[_dice] != PREVIOUS_TOTAL_REWARD_CHANCE:
					break
			TOTAL_REWARD_CHANCE = total_reward_chance_structure[_dice] # set total hold_reward chance
			print("TOTAL_REWARD_CHANCE: ", TOTAL_REWARD_CHANCE)
		"chance_allow_repeat": #can be the same as previous
			var _dice
			var _dicelen = total_reward_chance_structure.size()
			if _dicelen == 1:
				TOTAL_REWARD_CHANCE = total_reward_chance_structure[0]
			else:
				_dice = MathUtils.generate_random(0, _dicelen - 1, "int")
				TOTAL_REWARD_CHANCE = total_reward_chance_structure[_dice] # set total hold_reward chance
			print("TOTAL_REWARD_CHANCE: ", TOTAL_REWARD_CHANCE)
			
	# from Block N to Block N+1, we either change
	# ONLY the distribution, 
	# or ONLY the hold_reward reliability (%)
	
	if _distribution_type == DistributionType.NORM_AFTER_1ST and MU_RWD_TIMEPOINT == null:
		if PREVIOUS_TOTAL_REWARD_CHANCE == TOTAL_REWARD_CHANCE:
			MAKE_blk_distribution(_distribution_type,0,0,_previous_mu)
			print("change distribution. MU_RWD_TIMEPOINT, STD_RWD_TIMEPOINT: ", MU_RWD_TIMEPOINT, ", ", STD_RWD_TIMEPOINT)
		elif PREVIOUS_TOTAL_REWARD_CHANCE != TOTAL_REWARD_CHANCE:
			print("change TOTAL_REWARD_CHANCE: ", TOTAL_REWARD_CHANCE)
			MU_RWD_TIMEPOINT = _previous_mu
			STD_RWD_TIMEPOINT = _previous_std
	else:
		MAKE_blk_distribution(_distribution_type)

	# based on the given distribution parameters,
	# generate reward_given_timepoint template, which serves as the the "right" answer for trials
	# all about tokens
	# MARK: Vincentization
	
	match _sample_type:
		SampleType.POOL:
			for i in range(number_of_trials_this_blk):
				# if reward is given
				dice_if_rwd_given = MathUtils.generate_random(0, 1, "float") # set total hold_reward chance
				if dice_if_rwd_given <= TOTAL_REWARD_CHANCE:
					# if given, when?
					if _distribution_type == DistributionType.FLAT:
						if Global.inference_type == Global.InferenceFlagType.press_based:
							timepoint = MathUtils.generate_random(FLAT_MIN, FLAT_MAX, "int")
					else:
						if MU_RWD_TIMEPOINT <= 0:# responded to MAKE_blk_distribution when Err reported
							get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
						else:
							while true:  #MARK:  Floor&Ceiling of timepoint
								timepoint = MathUtils.normrnd(MU_RWD_TIMEPOINT, STD_RWD_TIMEPOINT)
								if timepoint >= 0.5: 
									break
							if Global.inference_type == Global.InferenceFlagType.press_based:
								timepoint = roundi(timepoint)
							elif Global.inference_type == Global.InferenceFlagType.time_based:
								timepoint = roundf(timepoint *100) /10
								timepoint = timepoint / 10
								timepoint = timepoint * 4
								timepoint = roundf(timepoint)/4

					reward_given_timepoint_template.append(timepoint)
					reward_signal_given_timepoint_template_this_blk.append(timepoint)
				else:
					reward_given_timepoint_template.append(null)
					reward_signal_given_timepoint_template_this_blk.append(null)

		SampleType.SLICED:
			var create_pool = []
			var seed_for_slice 
			if speed_up_mode > 1:
				if number_of_trials_this_blk < 100:
					seed_for_slice = 100
				else:
					seed_for_slice = number_of_trials_this_blk+10
			else:
				seed_for_slice = 100000
			for i in range(1, seed_for_slice):
				while true:  
					timepoint = MathUtils.normrnd(MU_RWD_TIMEPOINT, STD_RWD_TIMEPOINT)
					if timepoint >= 0.5:
						break
				if Global.inference_type == Global.InferenceFlagType.press_based:
					timepoint = roundi(timepoint)
				elif Global.inference_type == Global.InferenceFlagType.time_based:
					timepoint = roundf(timepoint *100) /10
					timepoint = timepoint / 10
					timepoint = timepoint * 4
					timepoint = roundf(timepoint)/4

				create_pool.append(timepoint)
			create_pool.sort()

			var pool_from_pool=[]
			if _slice_size == -1: # as many bins as the number of trials in the block
				_slice_size = number_of_trials_this_blk
			
			pool_from_pool.resize(_slice_size)
			pool_from_pool.fill([])
			var n = roundi(number_of_trials_this_blk / _slice_size)
			for i in range(_slice_size):
				var temp = []
				temp.append_array(create_pool.slice(i * float(seed_for_slice) / _slice_size, float((i + 1) * seed_for_slice) / _slice_size)) 
				temp.shuffle()
				pool_from_pool[i] = temp
				#print("pool_from_pool for vincentization bin%s: "%i,pool_from_pool[i].slice(0, n),"n: ", n)
				reward_signal_given_timepoint_template_this_blk.append_array(pool_from_pool[i].slice(0, n))

			var n_null = roundi(number_of_trials_this_blk * (1 - TOTAL_REWARD_CHANCE))
			print("n_null: ", n_null)
			reward_signal_given_timepoint_template_this_blk.shuffle()
			for j in range(n_null):
				reward_signal_given_timepoint_template_this_blk[j] = null
			reward_signal_given_timepoint_template_this_blk.shuffle()
			reward_given_timepoint_template.append_array(reward_signal_given_timepoint_template_this_blk)
			#print("reward_signal_given_timepoint_template_this_blk: ", reward_signal_given_timepoint_template_this_blk)
		

	# MARK: Reward Value
	match _value_type:
		"RANDOM":
			# h_value_list,o_value_list should be predefined 
			h_value_list = h_value_listRND
			o_value_list = o_value_listRND
			var dice_h = MathUtils.generate_random(0, h_value_list.size() - 1, "int")
			var random_h = h_value_list[dice_h]
			var dice_o
			var random_o
			for i in range(number_of_trials_this_blk):
				while true: # Avoid generating negative numbers
					dice_o = MathUtils.generate_random(0, o_value_list.size() - 1, "int")
					random_o = o_value_list[dice_o]
					if random_o < random_h:
						break
				hold_vlaue_template.append(random_h) # Hold hold_reward
				hold_reward_template_this_blk.append(random_h) # Hold hold_reward
				opt_out_value_template.append(random_o) # Opt-out hold_reward
				opt_out_reward_template_this_blk.append(random_o) # Opt-out hold_reward
		"A":
			var ao = setValues(number_of_trials_this_blk,ValueSets, "none")
			hold_reward_template_this_blk = ao[0]
			opt_out_reward_template_this_blk = ao[1]
			hold_vlaue_template.append_array(hold_reward_template_this_blk)
			opt_out_value_template.append_array(opt_out_reward_template_this_blk)
		"B":
			var ao = setValues(number_of_trials_this_blk,ValueSets,"h5o5_ur",_exception_proportion, reward_signal_given_timepoint_template_this_blk)
			hold_reward_template_this_blk = ao[0]
			opt_out_reward_template_this_blk = ao[1]
			hold_vlaue_template.append_array(hold_reward_template_this_blk)
			opt_out_value_template.append_array(opt_out_reward_template_this_blk)

	blk_para._init(
		blk_flag,# blk_flag
		TOTAL_REWARD_CHANCE,# chance
		str(DistributionType.values()),# distribution_type
		[],# distr_para_1
		[],# distr_para_2
		[],# reward_signal_given_timepoint_template_this_blk_
		[],# h_value_list
		[],# o_value_list	
		[] # tr_num_range
	)
	blk_para.rwd_given_signal_timepoint = reward_signal_given_timepoint_template_this_blk		
	blk_para.h_value_list = hold_reward_template_this_blk
	blk_para.o_value_list = opt_out_reward_template_this_blk
	blk_para.tr_num_range = [tr_num1, tr_num2]
	blk_para.distr_para_1 = [MU_RWD_TIMEPOINT]
	blk_para.distr_para_2 = [STD_RWD_TIMEPOINT]
	blks_paras.append(blk_para)
# save the configuration with data	
	print("%s generated.\n"%blk_flag)
	var template=[]
	var trial_setting=[]
	for i in range(number_of_trials_this_blk):
		trial_setting=[
				reward_signal_given_timepoint_template_this_blk[i],
				hold_reward_template_this_blk[i],
				opt_out_reward_template_this_blk[i]
				]
		template.append(trial_setting)
	var text={
		"blk": blk_flag,
		"reward_signal_timepoint": reward_signal_given_timepoint_template_this_blk,
		"TOTAL_REWARD_CHANCE": TOTAL_REWARD_CHANCE,
		"number_of_trials_accumu_rwd_timepointlated": NUMBER_OF_TRIALS,
		"number_of_trials_this_blk": number_of_trials_this_blk,
		"distribution_type": _distribution_type,
		"MU_RWD_TIMEPOINT": MU_RWD_TIMEPOINT,
		"STD_RWD_TIMEPOINT": STD_RWD_TIMEPOINT,
		"template_t_h_o": template
	}
	
	Global.config_text.append(text)
# MARK:End'blk'

func set123(_mu, _std_mu):
	MU_RWD_TIMEPOINT = _mu
	if Global.inference_type == Global.InferenceFlagType.press_based:
		MU_RWD_TIMEPOINT = roundi(MU_RWD_TIMEPOINT)
	elif Global.inference_type == Global.InferenceFlagType.time_based:
		MU_RWD_TIMEPOINT = roundf(MU_RWD_TIMEPOINT * 100) / 10
		MU_RWD_TIMEPOINT = MU_RWD_TIMEPOINT / 10
	STD_RWD_TIMEPOINT = _std_mu * MU_RWD_TIMEPOINT
	STD_RWD_TIMEPOINT = roundf(STD_RWD_TIMEPOINT * 1000) / 100
	STD_RWD_TIMEPOINT = STD_RWD_TIMEPOINT / 10
	
func MAKE_blk_distribution(_distribution_type, _min = 0, _max = 0, _previous_mu = 0, 
	_1st_mu_rwd_timepoint =20, _1st_std_rwd_timepoint=10):

	if _previous_mu != 0:
		# Specify a previous distribution parameter
		MU_RWD_TIMEPOINT = _previous_mu
	
	match _distribution_type:
		DistributionType.SET1:
			set123(3, 0.25)
		DistributionType.SET2:
			set123(4, 0.25)
		DistributionType.SET3:
			set123(5, 0.25)
		DistributionType.SET4:
			set123(2.5, 0.25)

		DistributionType.NORM_AFTER_1ST: # Normal distribution
			var new_mu_rwd_timepoint
			var new_std_rwd_timepoint
		
			while true: # Avoid same as previous
				var dicelen = mu_rwd_timepoint_change_list.size()
				while true:
					var dice_mu_rwd_timepoint = MathUtils.generate_random(0, mu_rwd_timepoint_change_list.size() - 1, "int")
					var mu_rwd_timepoint_change = mu_rwd_timepoint_change_list[dice_mu_rwd_timepoint]
					new_mu_rwd_timepoint = MU_RWD_TIMEPOINT * (1 + mu_rwd_timepoint_change)
					new_mu_rwd_timepoint = roundi(new_mu_rwd_timepoint)
					
					if Global.inference_type == Global.InferenceFlagType.press_based:
						if new_mu_rwd_timepoint >= 10:
							break
					elif Global.inference_type == Global.InferenceFlagType.time_based:
						if new_mu_rwd_timepoint >= 2 and new_mu_rwd_timepoint <= 12:
							break
				
					mu_rwd_timepoint_change_list.erase(mu_rwd_timepoint_change_list[dice_mu_rwd_timepoint])
					dicelen = mu_rwd_timepoint_change_list.size()
					print("REMOVED a dice face",mu_rwd_timepoint_change_list)
					if dicelen == 0:	
						print("Err!!!!: invalid distribution parameters")
						MU_RWD_TIMEPOINT=0
						STD_RWD_TIMEPOINT=0
						return
		
				var dice_variance_rwd_timepoint_2mu = MathUtils.generate_random(0, variance_rwd_timepoint_2mu_list.size() - 1, "int")
				new_std_rwd_timepoint = new_mu_rwd_timepoint * variance_rwd_timepoint_2mu_list[dice_variance_rwd_timepoint_2mu]
				new_std_rwd_timepoint = roundf(new_std_rwd_timepoint * 1000) / 100
				new_std_rwd_timepoint = new_std_rwd_timepoint / 10
				if new_std_rwd_timepoint != MU_RWD_TIMEPOINT:
					break

			MU_RWD_TIMEPOINT = new_mu_rwd_timepoint
			STD_RWD_TIMEPOINT = new_std_rwd_timepoint

		DistributionType.FLAT: # flat distribution
			FLAT_MIN = _min
			FLAT_MAX = _max

		DistributionType.NORM_1ST_CUSTOM: # Normal distribution
			var dice_mu_rwd_timepoint = MathUtils.generate_random(0, mu_rwd_timepoint_change_list.size() - 1, "int")
			MU_RWD_TIMEPOINT = mu_rwd_timepoint_change_list[dice_mu_rwd_timepoint]
			var dice_variance_rwd_timepoint_2mu = MathUtils.generate_random(0, variance_rwd_timepoint_2mu_list.size() - 1, "int")
			STD_RWD_TIMEPOINT = MU_RWD_TIMEPOINT * variance_rwd_timepoint_2mu_list[dice_variance_rwd_timepoint_2mu]

		DistributionType.NORM_1ST:
			MU_RWD_TIMEPOINT = _1st_mu_rwd_timepoint
			if Global.inference_type == Global.InferenceFlagType.press_based:
				MU_RWD_TIMEPOINT = roundi(MU_RWD_TIMEPOINT)
			elif Global.inference_type == Global.InferenceFlagType.time_based:
				MU_RWD_TIMEPOINT = roundf(MU_RWD_TIMEPOINT * 100) / 10
				MU_RWD_TIMEPOINT = MU_RWD_TIMEPOINT / 10
			STD_RWD_TIMEPOINT = _1st_std_rwd_timepoint
			STD_RWD_TIMEPOINT = roundf(STD_RWD_TIMEPOINT * 1000) / 100
			STD_RWD_TIMEPOINT = STD_RWD_TIMEPOINT / 10


#MARK: Set values
# values = [ h_value,o_value, h2,o2, h3,o3]
func setValues(_number_of_trials_this_blk,values, _case, exception_proportion=default_exception_proportion, _reward_given_timepoint_template_this_blk=[]):
	var opt_out_value_this_blk = []
	var hold_vlaue_this_blk = []
	hold_vlaue_this_blk.resize(_number_of_trials_this_blk)
	hold_vlaue_this_blk.fill(values[0])
	opt_out_value_this_blk.resize(_number_of_trials_this_blk)
	opt_out_value_this_blk.fill(values[1])
	match _case:
		"none":
			pass
		"h5o5_ur":# asign values sets proportionally equal according to reward given timepoint template
			var urwd_idx = []
			var rwd_idx=[]
			for idx in range(len(_reward_given_timepoint_template_this_blk)): 
				if  _reward_given_timepoint_template_this_blk[idx] == null:
					urwd_idx.append(idx)
				else:
					rwd_idx.append(idx)
			print("urwd_idx: ", urwd_idx)
			urwd_idx.shuffle()
			rwd_idx.shuffle()

			var both_exception_together = exception_proportion*_number_of_trials_this_blk 
			var each_exception_urwd = roundi(both_exception_together * (1-TOTAL_REWARD_CHANCE)) *0.5
			if TOTAL_REWARD_CHANCE < 1.0:
				if each_exception_urwd == 0: 
					each_exception_urwd = 1 # at least 1 exception
			var each_exception_rwd = both_exception_together * TOTAL_REWARD_CHANCE*0.5
			each_exception_rwd = roundi(each_exception_rwd)
			if each_exception_rwd == 0:
				each_exception_rwd = 1 # at least 1 exception
			print("each_exception_urwd: ", each_exception_urwd, "\teach_exception_rwd: ", each_exception_rwd)

			urwd_idx = urwd_idx.slice(0, 2*each_exception_urwd)
			rwd_idx = rwd_idx.slice(0, 2*each_exception_rwd)
			#unrwd
			for i in range(each_exception_urwd):
				var idx = urwd_idx[i]
				hold_vlaue_this_blk[idx] = values[4]  #h3
				opt_out_value_this_blk[idx] = values[5] #o3
			for i in range(each_exception_urwd, len(urwd_idx)):
				var idx = urwd_idx[i]
				hold_vlaue_this_blk[idx] = values[2] #h2
				opt_out_value_this_blk[idx] = values[3] #o2
			# rwd
			for i in range(each_exception_rwd):
				var idx = rwd_idx[i]
				hold_vlaue_this_blk[idx] = values[4]  #h3
				opt_out_value_this_blk[idx] = values[5] #o3
			for i in range(each_exception_rwd, len(rwd_idx)):
				var idx = rwd_idx[i]
				hold_vlaue_this_blk[idx] = values[2] #h2
				opt_out_value_this_blk[idx] = values[3] #o2

	return [hold_vlaue_this_blk, opt_out_value_this_blk]



func load_from_config(_blk,
					_blkPara_change_distr_or_chance,
					_blkPara_distr_type,
					_blkPara_distr_para_1,
					_blkPara_distr_para_2,
					_blkPara_chance,
					_blkPara_value_list,
					_blkPara_value_list_2,
					_blkPara_tr_num_num_range
					):
	var _o_value_list_ = []
	var _h_value_list_ = []
	var _tr_num_n_range
	if _blkPara_value_list == "":
		print('Err: %s "blkPara_value_list" not defined'%_blk)
		return
	else:
		var f_h_value_list_ = Utils.parse_numeric_array(_blkPara_value_list)
		for floatitem in f_h_value_list_:
			var intitem = int(floatitem)
			_h_value_list_.append(intitem)

	if _blkPara_value_list_2 == "":
		print('Err: %s "blkPara_value_list_2" not defined'%_blk)
		return
	else:
		var f_o_value_list_ = Utils.parse_numeric_array(_blkPara_value_list_2)
		for floatitem in f_o_value_list_:
			var intitem = int(floatitem)
			_o_value_list_.append(intitem)

	if _blkPara_tr_num_num_range == "":
		print('Err: %s "blkPara_tr_num_num_range" not defined'%_blk)
		return
	else:
		_tr_num_n_range = Utils.parse_numeric_array(_blkPara_tr_num_num_range)
		if _tr_num_n_range.size() != 2:
			print('Err: %s "blkPara_tr_num_num_range" format error'%_blk)
			return


	var _total_reward_chance_structure
	if _blkPara_chance == "":
		print('Err: %s "blkPara_chance" not defined'%_blk)
		return
	else:
		_total_reward_chance_structure = Utils.parse_numeric_array(_blkPara_chance)

	var _mu_rwd_timepoint_change_list
	var _variance_rwd_timepoint_2mu_list
	match _blkPara_distr_type:
		-1:
			print("Err: %s 'distr_type' not defined"%_blk)
			return
		1:
			pass
		0:
			if _blkPara_distr_para_1 == "":
				print("Err: %s 'distr_para_1' not defined"%_blk)
				return
			if _blkPara_distr_para_2 == "":
				print("Err: %s 'distr_para_2' not defined"%_blk)
				return
			else:
				_mu_rwd_timepoint_change_list = Utils.parse_numeric_array(_blkPara_distr_para_1)
				_variance_rwd_timepoint_2mu_list = Utils.parse_numeric_array(_blkPara_distr_para_2)

	var _reward_chance_mode
	match _blkPara_change_distr_or_chance:
		3:
			_reward_chance_mode = "chance_allow_repeat"
		2:
			var dice_ = MathUtils.generate_random(0, 1, "int")
			if dice_ == 0:
				_reward_chance_mode = "random_distribution"
			else:
				_reward_chance_mode = "random_chance"
		1:
			_reward_chance_mode = "random_distribution"
		0:
			_reward_chance_mode = "random_chance"
	

	var result = [_reward_chance_mode,
				_total_reward_chance_structure,
				_mu_rwd_timepoint_change_list,
				_variance_rwd_timepoint_2mu_list,
				_h_value_list_,
				_o_value_list_,
				_tr_num_n_range[0],
				_tr_num_n_range[1]
				]
	return result

#MARK: Save data
func save_data(_case):
	match _case:
		"json":
			var data = {
				"blk": blk_labels[trial_count -1], # trial_count from 1 while list index from 0
				"cumulative_trial_count": trial_count,
				"reward_signal_given_timepoint(s)": reward_given_timepoint_template[trial_count -1],
				"actual_reward_given_timestamp": actual_reward_given_timepoint,
				"trial_start_timestamp": trial_start_time,
				"task_show_timestamp": task_show_time,	
				"hold_reward": hold_reward,	
				"opt_out_reward": opt_out_reward,	
				"actual_reward_value": actual_reward_value,
				"if_trial_timeout": trial_timeout,
				"if_optionis on_left": OPT_LEFT_FLAG,
				"press_history": JSON.stringify(Global.press_history,"", false, false),
			}
			var json_string = JSON.stringify(data,"  ", false, false)
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE)
			file.seek_end()
			file.store_string(json_string)
			file.store_string("\n") # need this to separate different json entries
			file.close()

		"head":
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE)
			file.store_line("auto_mode: %s\nspeed_up_value: %s" % [Global.auto_mode,Global.speed_up_mode])
			file.store_line("Inference Type: %s" % Global.inference_type) 
			file.store_line("# Inference Type: 0:time-based; 1:press-based\n") 
			file.store_line("# Button type: 0:press the green to start trial; 1:opt-out; 2:INVALID,3:WAIT(time-based),4:HOLD(press-based)") # CSV列标题
			file.close()

		"summary":
			var file = FileAccess.open(Global.filename_data, FileAccess.READ_WRITE) # FileAccess.READ_WRITE will append, while FileAccess.WRITE will overwrite the whole file
			file.seek_end()
			file.store_line("\n\nTokens: %d" % Global.wealth)
			file.close()


func reset_scene_to_start_button():
	task_on = false
	colorRect.visible = false
	countdownTimer.stop()
	save_data("json")
	Global.press_history.clear()
	hold_button.self_modulate = default_color
	# Reset the scene
	if trial_count >= 1:
		earningTimer[1]= Time.get_ticks_msec()/1000.0
		earningTimer[2] = earningTimer[1] - earningTimer[0] + earningTimer[2]
		print("Earning timer paused at ", earningTimer[1], " valid time ", earningTimer[2])
		original_states = hide_nodes(EXCLUDE_LABEL_1, original_states)
		intervalTimer.wait_time = UNIT_INTERVAL * 2
		intervalTimer.start()
		await intervalTimer.timeout
	_label_refresh(Global.wealth, "init")
	original_states_2 = hide_nodes([], original_states_2)
	intervalTimer.wait_time = UNIT_INTERVAL
	intervalTimer.start()
	await intervalTimer.timeout

	# Reset status
	quitButton.disabled = false
	startButton.disabled = false
	vboxstart.visible = true
	vboxbottom.visible = true
	vboxtop.visible = true
	label_startbtn.visible = true
	# label status
	trial_start_time = Time.get_ticks_msec()/1000.0


func reset_to_start_next_trial():
	if trial_count <= NUMBER_OF_TRIALS:
		prepare_init_trial()
		restore_nodes(original_states_2)
		restore_nodes(original_states)
		task_show_time = Time.get_ticks_msec()/1000.0
		task_on = true
	if trial_count > NUMBER_OF_TRIALS:
		_label_refresh(Global.wealth, "finish")


# MARK: Buttons Response
func _input(event):
	if vboxstart.visible == false:
		# Detect key release from key board
		# if event.is_action_released("press_optout_button"):
			# if not opt_out_button.disabled:
				# opt_out_button.emit_signal("pressed")
		# if event.is_action_released("press_hold_button"):
			# if not hold_button.disabled:
				# hold_button.emit_signal("pressed")
		# 检测鼠标左键点击
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var btn_area = hold_button.get_global_rect()
			var btn_area_2 = opt_out_button.get_global_rect()
			var click_pos = event.position
			var current_time = Time.get_ticks_msec()/1000.0
		
			if btn_area.has_point(click_pos) or btn_area_2.has_point(click_pos):
				pass
			else:
				warning()
				record_press_data(current_time, BtnType.INVALID)
			# change color of background:


func warning():
	sound.play()
	var window_size = get_viewport_rect().size
	colorRect.size = window_size
	colorRect.color = Color.YELLOW_GREEN
	colorRect.visible = true
	intervalTimer.wait_time = UNIT_INTERVAL / 2
	intervalTimer.start()
	await intervalTimer.timeout
	colorRect.visible = false


 #for time-based inference
func _on_start_to_wait_button_pressed():
	var start_wait_action_time = Time.get_ticks_msec()/ 1000.0 # Always reset START_TIME on press
	hold_button.self_modulate = DIMCOLOR
	if not HAS_BEEN_PRESSED:
		HAS_BEEN_PRESSED = true
		infer_base_timer.one_shot = true # 单次触发模式
		if reward_given_timepoint != null:
			infer_base_timer.start(reward_given_timepoint)	
		print("Wait Time Start%s" % reward_given_timepoint)
		# wait too long warning
		set_countdownTimer(true,'Time-out: you lost 2 tokens', 60)
	record_press_data(start_wait_action_time,BtnType.WAIT)


func _on_infer_baser_timer_timeout():
	infer_base_timer.stop()
	print("Wait Time out")
	DURATION = Time.get_ticks_msec() / 1000.0 - START_TIME # 计算按住时长（秒）
	_reward_given_actions(hold_reward)
	_label_refresh(Global.wealth,"reward_given")
	reset_scene_to_start_button()
	
		
# for press-based inference
func _on_hold_button_pressed():
	# Get the current timestamp (seconds)
	var current_time = Time.get_ticks_msec()/1000.0
	# Handle invalid behavior
	if reward_given_timepoint == null:
		NUM_OF_PRESS += 1
		_label_refresh(Global.wealth, "pressing...")
		record_press_data(current_time, BtnType.HOLD)
		
	elif REWARD_GIVEN_FLAG == false:
		NUM_OF_PRESS += 1
		_label_refresh(Global.wealth, "pressing...")
		if NUM_OF_PRESS < reward_given_timepoint:
			record_press_data(current_time, BtnType.HOLD)
		if NUM_OF_PRESS == reward_given_timepoint:
			_reward_given_actions(hold_reward)
			print("hold-REWARD_GIVEN_FLAG  ", REWARD_GIVEN_FLAG)
			_label_refresh(Global.wealth, "reward_given")
			record_press_data(current_time, BtnType.HOLD)
			reset_scene_to_start_button()


func _on_opt_out_button_pressed():
	# 获取当前时间戳（秒）
	var opt_out_action_time = Time.get_ticks_msec()/1000.0
	if not infer_base_timer.is_stopped():
		infer_base_timer.stop()
	_reward_given_actions(opt_out_reward)
	_label_refresh(Global.wealth, "opt_out")
	record_press_data(opt_out_action_time,BtnType.OPT_OUT)
	reset_scene_to_start_button()


func _on_quit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_start_button_pressed():
	var start_trial_action_time = Time.get_ticks_msec()/1000.0
	record_press_data(start_trial_action_time, BtnType.START)
	earningTimer[0] = Time.get_ticks_msec()/1000.0
	print("===Earning timer started at ", earningTimer[0])
	reset_to_start_next_trial()


func _reward_given_actions(reward_value):
	Global.wealth += reward_value
	actual_reward_given_timepoint = Time.get_ticks_msec()/1000.0
	actual_reward_value = reward_value
	REWARD_GIVEN_FLAG = true

# 封装记录按键数据的函数
func record_press_data(current_time, btn_type) -> void:
	# 创建PressData实例
	var new_press = PressData.new(current_time, btn_type)
	Global.press_history.append(new_press.to_array())
	

# MARK: UI
func place_button(_if_opt_left,case="by_windowsize"):
	match case:
		"by_fixed_layout":
			pass
		"by_windowsize":
			# 获取窗口尺寸
			var window_size = get_viewport_rect().size
			var root = get_node("/root/Node2D")
			root.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_KEEP_SIZE) # this is important!
			if menuButton != null:
				Utils.setup_layout(label_discript, PRESET_CENTER, 0.5, 0.8, window_size)
			Utils.setup_layout(vbox, PRESET_CENTER, 0.5, 0.5, window_size) # feedback
			Utils.setup_layout(vboxstart, PRESET_CENTER, 0.5, 0.65, window_size)
			Utils.setup_layout(vboxbottom, PRESET_CENTER, 0.5, 0.85, window_size)
			Utils.setup_layout(vboxtop, PRESET_CENTER, 0.5, 0.2, window_size)
			match _if_opt_left:
				"left":
					Utils.setup_layout($MenuButton, PRESET_CENTER, 0.35, 0.4, window_size)
					Utils.setup_layout($MenuButton2, PRESET_CENTER, 0.65, 0.4, window_size)
				"right":
					Utils.setup_layout($MenuButton2, PRESET_CENTER, 0.35, 0.4, window_size)
					Utils.setup_layout($MenuButton, PRESET_CENTER, 0.65, 0.4, window_size)
	

func place_options_left_or_right():
	if IF_OPT_LEFT >= 0.5:
		OPT_LEFT_FLAG = "left"
		place_button("left") # Initialize UI
	else:
		OPT_LEFT_FLAG = "right"
		place_button("right") # Initialize UI with optout on the right


func _process(_delta):
	place_options_left_or_right()


# MARK: Label Refresh
func _label_refresh(wealth, case_text):
	# 更新UI
	if hold_reward != null:
		if hold_reward <= 0:
			hold_button_label.text = "" + str(hold_reward)
		else:
			hold_button_label.text = "+" + str(hold_reward)
		if opt_out_reward <= 0:
			opt_out_button_label.text = "" + str(opt_out_reward)
		else:
			opt_out_button_label.text = "+" + str(opt_out_reward)

	label_info_top.text = " Your Tokens: " 
	label_value_info_top.text = str(wealth)
	label_info_mid.text = " Elapesed Time(s): "
	label_value_info_mid.text = str(roundi(earningTimer[2]))
	label_info_bottom.text = " Your Earnings: "
	label_value_info_bottom.text = str(roundf((100* wealth)/ earningTimer[2]) / 100)

	var neutralcolor = Color("WHITE")
	var positivecolor = Color("GREEN")
	var negativecolor = Color("PLUM")
	label_startbtn.label_settings.font_color = neutralcolor
	label_startbtn.label_settings.font_size = 25
	label_startbtn.visible = false

	match case_text:

		"opt_out":
			label_1.label_settings.font_size = 72
			if opt_out_reward > 0:
				label_1.text = "+ " + str(opt_out_reward)
				label_1.label_settings.font_color = positivecolor
			elif opt_out_reward == 0:
				label_1.text = " + " + str(opt_out_reward)
				label_1.label_settings.font_color = positivecolor
			else:
				label_1.text = "" + str(opt_out_reward)
				label_1.label_settings.font_color = negativecolor

			label_1.visible = true
			label_t.visible = false

		"reward_given":
			label_1.label_settings.font_size = 72
			if hold_reward == 0:
				label_1.text = "+ " + str(hold_reward)
				label_1.label_settings.font_color = positivecolor
			else:
				label_1.text = "+ " + str(hold_reward)
				label_1.label_settings.font_color = positivecolor
			REWARD_GIVEN_FLAG = false

			label_1.visible = true
			label_t.visible = false

		"timeout":
			label_1.label_settings.font_size = 72
			label_1.text = str(-5)
			label_1.label_settings.font_color = negativecolor
			label_t.text = "Timeout! Panelty: -5"
			label_1.visible = true
			label_t.visible = true

		"pressing...":
			label_1.visible = false
			#label_1.text = ""
			#label_1.label_settings.font_size = 36
			#label_1.text = str(NUM_OF_PRESS)# need t add NUM_OF_PRESS to the func parameter
			#label_1.label_settings.font_color = neutralcolor

		"init": 
			label_1.visible = false
			label_t.visible = false
			label_discript.visible = true
			label_discript.label_settings.font_color = neutralcolor
			label_discript.label_settings.font_size = 25

			if trial_count < 4:
				label_startbtn.label_settings.font_color = neutralcolor
				label_startbtn.label_settings.font_size = 25
				label_startbtn.text = "Press the Disk \n to Start"

				if trial_count == 1:
					match Global.inference_type:
						Global.InferenceFlagType.time_based:
							label_discript.text = "Press BLUE once to give up, \n or press RED to wait for more tokens"
						Global.InferenceFlagType.press_based:
							label_discript.text = "Press BLUE once to give up, \n or keep pressing RED to earn more tokens"
				elif trial_count == 2:
						label_discript.text = "Value on buttons are tokens you can get\n if you press them."
				elif trial_count == 3:
						label_discript.text = "If you change your mind, \n you can always opt out via the BLUE one."
			else:
				label_discript.text = ""
				label_startbtn.text = ""
	

		"finish":
			label_1.text = "Finished!\n Close the window to exit"
			label_1.visible = true


# Hide all child nodes and deactivate interactive elements
func hide_nodes(_list, _original_states):
	# 先保存所有子节点的原始状态
	_original_states.clear()
	for child in get_children():
		if child.name in _list:
			continue # 跳过不需要隐藏的节点
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
func set_countdownTimer(ifset: bool,timeouttext: String, time):
	if ifset == true:
			label_t.text = timeouttext
			countdownTimer.start(time/speed_up_mode)
			print("countdownTimer started")
	else:
		label_t.text = ""


func _on_countdown_timer_timeout():
	warning() #beep
	countdownTimer.stop()
	print("countdownTimer stopped")
	_reward_given_actions(-5) # record actuAL reward
	trial_timeout = true # mark this trial as a timeout trial
	_label_refresh(Global.wealth, "timeout")
	reset_scene_to_start_button()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data("summary")
		#cleanup()
		get_tree().quit()


# 正确释放动态创建的节点
func cleanup():
	for child in get_children():
		if child is CanvasItem:
			child.queue_free() # 标记节点在下一帧释放


func _agent():
	add_child(agent_action_timer)
	agent_action_timer.wait_time = 0.2  # 间隔 0.05 秒
	agent_action_timer.autostart = true  # 自动启动
	agent_action_timer.one_shot = false  # 循环触发
	agent_action_timer.timeout.connect(_on_agent_action_timer_timeout)
	agent_action_timer.start()


func _on_agent_action_timer_timeout():
	if vboxstart.visible == true:
		startButton.emit_signal("pressed")
	if task_on == true:
		var dice = MathUtils.generate_random(0, 1, "int")
		if dice == 0:
			hold_button.emit_signal("pressed")
		else:
			opt_out_button.emit_signal("pressed")
	if trial_count > NUMBER_OF_TRIALS:
		agent_action_timer.queue_free()


func one_time_timer(timername):
	timername = Timer.new()
	timername.autostart = false
	timername.one_shot = true
	add_child(timername)
	return timername
