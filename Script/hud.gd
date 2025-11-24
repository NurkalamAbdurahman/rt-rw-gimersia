extends CanvasLayer

@onready var strength_potion: Control = $MarginContainer4/HBoxContainer/StrengthPotion
@onready var speed_potion: Control = $MarginContainer4/HBoxContainer/SpeedPotion
@onready var timer_speed: Label = $TimerSpeed
@onready var timerstrength: Label = $Timerstrength

var last_strength := -1
var last_speed := -1

func _ready() -> void:
	strength_potion.visible = false
	speed_potion.visible = false
	strength_potion.modulate.a = 0.0
	speed_potion.modulate.a = 0.0
	
	timer_speed.visible = false
	timerstrength.visible = false
	timer_speed.modulate.a = 0.0
	timerstrength.modulate.a = 0.0

func _process(delta: float) -> void:
	if GameData.strength_potion != last_strength:
		_update_strength_ui()
		last_strength = GameData.strength_potion
		
	if GameData.speed_potion != last_speed:
		_update_speed_ui()
		last_speed = GameData.speed_potion
	
	_update_buff_timers()

func _update_buff_timers():
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	if player.strength_buff_active:
		if not timerstrength.visible:
			timerstrength.visible = true
			fade(timerstrength, 1.0)
		
		var time_left = int(player.strength_buff_time)
		var minutes = time_left / 60
		var seconds = time_left % 60
		timerstrength.text = "%02d:%02d" % [minutes, seconds]
		
		if player.strength_buff_time <= 10.0:
			timerstrength.modulate = Color(1, 0.3, 0.3)
		else:
			timerstrength.modulate = Color(1, 1, 1)
	else:
		if timerstrength.visible:
			fade(timerstrength, 0.0)
			await get_tree().create_timer(0.25).timeout
			timerstrength.visible = false
	
	if player.speed_buff_active:
		if not timer_speed.visible:
			timer_speed.visible = true
			fade(timer_speed, 1.0)
		
		var time_left = int(player.speed_buff_time)
		var minutes = time_left / 60
		var seconds = time_left % 60
		timer_speed.text = "%02d:%02d" % [minutes, seconds]
		
		if player.speed_buff_time <= 10.0:
			timer_speed.modulate = Color(1, 0.3, 0.3)
		else:
			timer_speed.modulate = Color(1, 1, 1)
	else:
		if timer_speed.visible:
			fade(timer_speed, 0.0)
			await get_tree().create_timer(0.25).timeout
			timer_speed.visible = false

func fade(control: Control, to_alpha: float, duration: float = 0.25):
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", to_alpha, duration)

func _update_strength_ui():
	if GameData.strength_potion > 0:
		strength_potion.visible = true
		fade(strength_potion, 1.0)
	else:
		fade(strength_potion, 0.0)
		await get_tree().create_timer(0.25).timeout
		strength_potion.visible = false

func _update_speed_ui():
	if GameData.speed_potion > 0:
		speed_potion.visible = true
		fade(speed_potion, 1.0)
	else:
		fade(speed_potion, 0.0)
		await get_tree().create_timer(0.25).timeout
		speed_potion.visible = false
