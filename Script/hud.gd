extends CanvasLayer
@onready var strength_potion: Control = $MarginContainer4/HBoxContainer/StrengthPotion
@onready var speed_potion: Control = $MarginContainer4/HBoxContainer/SpeedPotion
@onready var buff_strength: Control = $MarginContainer3/VBoxContainer/BuffStrength
@onready var buff_speed: Control = $MarginContainer3/VBoxContainer/BuffSpeed
@onready var timer_lambat: AudioStreamPlayer = $TimerLambat

var last_strength := -1
var last_speed := -1
var timer_sfx_playing := false

func _ready() -> void:
	for control in [strength_potion, speed_potion, buff_strength, buff_speed]:
		control.visible = false
		control.modulate.a = 0.0

func _process(_delta: float) -> void:
	_check_potion_changes()
	_update_buff_visibility()

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

func _update_buff_visibility() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	_update_buff_container(buff_strength, player.strength_buff_active)
	_update_buff_container(buff_speed, player.speed_buff_active)
	_handle_timer_warning(player)

func _update_buff_container(container: Control, is_active: bool) -> void:
	if is_active:
		if not container.visible:
			container.visible = true
			_fade(container, 1.0)
	else:
		if container.visible:
			_fade(container, 0.0)
			await get_tree().create_timer(0.25).timeout
			container.visible = false

func _handle_timer_warning(player) -> void:
	var min_time = min(player.strength_buff_time if player.strength_buff_active else INF,
					   player.speed_buff_time if player.speed_buff_active else INF)
	
	if min_time <= 10.0 and not timer_sfx_playing:
		timer_lambat.play()
		timer_sfx_playing = true
	elif min_time > 10.0 and timer_sfx_playing:
		timer_lambat.stop()
		timer_sfx_playing = false

func _fade(control: Control, to_alpha: float, duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", to_alpha, duration)
