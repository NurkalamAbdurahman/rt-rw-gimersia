extends Control
@onready var timer_speed: Label = $TimerSpeed

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	if player.speed_buff_active:
		if not visible:
			visible = true
			_fade(1.0)
		_update_text(player.speed_buff_time)
	else:
		if visible:
			_hide()

func _update_text(time: float) -> void:
	var seconds := int(time)
	var minutes := seconds / 60
	var secs := seconds % 60
	timer_speed.text = "%02d:%02d" % [minutes, secs]
	timer_speed.modulate = Color(1, 0.3, 0.3) if time <= 10.0 else Color.WHITE

func _hide() -> void:
	_fade(0.0)
	await get_tree().create_timer(0.25).timeout
	visible = false

func _fade(to_alpha: float, duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", to_alpha, duration)
