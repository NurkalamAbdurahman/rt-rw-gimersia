extends CanvasLayer

@onready var root_control: Control = $Control
@onready var label: Sprite2D = $Control/MarginContainer/Congratulations
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var panel: Panel = $Control/Panel

var is_done: bool = false

func _ready():
	root_control.visible = false
	panel.scale = Vector2.ZERO
	panel.modulate.a = 0.0
	label.visible = false
	label.modulate.a = 0.0
	label.scale = Vector2.ONE
	panel.pivot_offset = panel.size / 2


func show_celebration():
	get_tree().paused = true
	root_control.visible = true
	
	panel.pivot_offset = panel.size / 2
	
	# --- PANEL ANIMASI MASUK ---
	panel.scale = Vector2(0.3, 0.3)
	panel.modulate.a = 0.0

	var panel_tween = create_tween()

	# Fade-in + Grow
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	panel_tween.parallel().tween_property(panel, "scale", Vector2(1.15, 1.15), 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Soft settle to scale 1
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await panel_tween.finished

	# --- LABEL MUNCUL ---
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	audio_stream_player_2d.play()

	var label_tween = create_tween()

	# Pop effect
	label_tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	label_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Settle
	label_tween.tween_property(label, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(3.0).timeout
	hide_celebration()


func hide_celebration():
	# Reset UI
	var hide_tween = create_tween()

	hide_tween.tween_property(panel, "scale", Vector2(0.3, 0.3), 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	hide_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.25)

	hide_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.2)

	await hide_tween.finished

	root_control.visible = false
	#get_tree().paused = false8
	is_done = true
	
	panel.scale = Vector2.ZERO
	panel.modulate.a = 0.0
	label.visible = false
	label.scale = Vector2.ONE
	label.modulate.a = 0.0
