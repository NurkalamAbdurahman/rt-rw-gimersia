extends CanvasLayer

@onready var root_control: Control = $Control
@onready var label: Label = $Control/MarginContainer/Label
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_done: bool = false

func _ready():
	root_control.visible = false

func show_celebration():
	audio_stream_player_2d.play()
	# Tampilkan popup dan pause game
	root_control.visible = true
	get_tree().paused = true

	# Reset teks awal
	label.scale = Vector2(0.2, 0.2)
	label.modulate.a = 0.0

	# Animasi scale & fade in
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1,1), 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Auto hide setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	hide_celebration()

func hide_celebration():
	root_control.visible = false
	get_tree().paused = false
	is_done = true
