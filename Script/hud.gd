extends CanvasLayer

@onready var strength_potion: Control = $MarginContainer4/HBoxContainer/StrengthPotion
@onready var speed_potion: Control = $MarginContainer4/HBoxContainer/SpeedPotion
@onready var timer_speed: Label = $TimerSpeed
@onready var timerstrength: Label = $Timerstrength
@onready var timer_lambat: AudioStreamPlayer = $TimerLambat

var last_strength := -1
var last_speed := -1
var timer_sfx_playing := false

func _ready() -> void:
	_init_ui()

func _process(_delta: float) -> void:
	_check_potion_changes()
	_update_buff_timers()

func _init_ui() -> void:
	for control in [strength_potion, speed_potion, timer_speed, timerstrength]:
		control.visible = false
		control.modulate.a = 0.0

func _check_potion_changes() -> void:
	if GameData.strength_potion != last_strength:
		_update_potion_ui(strength_potion, GameData.strength_potion > 0)
		last_strength = GameData.strength_potion
		
	if GameData.speed_potion != last_speed:
		_update_potion_ui(speed_potion, GameData.speed_potion > 0)
		last_speed = GameData.speed_potion

func _update_potion_ui(potion: Control, show: bool) -> void:
	if show:
		potion.visible = true
		_fade(potion, 1.0)
	else:
		_fade(potion, 0.0)
		await get_tree().create_timer(0.25).timeout
		potion.visible = false

func _update_buff_timers() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	_update_timer(timerstrength, player.strength_buff_active, player.strength_buff_time)
	_update_timer(timer_speed, player.speed_buff_active, player.speed_buff_time)

func _update_timer(timer: Label, is_active: bool, time_left: float) -> void:
	if is_active:
		if not timer.visible:
			timer.visible = true
			_fade(timer, 1.0)
		
		_set_timer_text(timer, time_left)
		_handle_timer_warning(time_left)
	else:
		if timer.visible:
			_hide_timer(timer)

func _set_timer_text(timer: Label, time: float) -> void:
	var seconds := int(time)
	var minutes := seconds / 608
	var secs := seconds % 60
	timer.text = "%02d:%02d" % [minutes, secs]
	timer.modulate = Color(1, 0.3, 0.3) if time <= 10.0 else Color.WHITE

func _handle_timer_warning(time: float) -> void:
	if time <= 10.0 and not timer_sfx_playing:
		timer_lambat.play()
		timer_sfx_playing = true
	elif time > 10.0 and timer_sfx_playing:
		timer_lambat.stop()
		timer_sfx_playing = false

func _hide_timer(timer: Label) -> void:
	_fade(timer, 0.0)
	await get_tree().create_timer(0.25).timeout
	timer.visible = false
	timer_sfx_playing = false

func _fade(control: Control, to_alpha: float, duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", to_alpha, duration)
