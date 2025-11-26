extends CanvasLayer

@onready var root_control: Control = $Control
@onready var label: Label = $Control/MarginContainer/Label
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var panel: Panel = $Control/Panel
@onready var margin_container: MarginContainer = $Control/Panel/MarginContainer

# Animation constants
const ANIMATION_DURATION: float = 2.0
const TWEEN_TRANS: Tween.TransitionType = Tween.TRANS_BACK
const TWEEN_EASE: Tween.EaseType = Tween.EASE_OUT

var is_done: bool = false
var original_margin_position: Vector2

func _ready():
	root_control.visible = false
	
	# Simpan posisi asli margin_container
	original_margin_position = margin_container.position
	
	# Setup awal untuk margin_container - posisi di atas layar
	margin_container.position.y = -margin_container.size.y
	margin_container.modulate.a = 0.0

func show_celebration():
	if is_done:
		return
		
	get_tree().paused = true
	root_control.visible = true
	
	# Reset state margin_container
	margin_container.position.y = -margin_container.size.y
	margin_container.modulate.a = 0.0
	
	# Animasi margin_container turun dari atas sambil fade in
	var margin_tween = create_tween()
	margin_tween.set_parallel(true)  # Jalankan semua animasi secara paralel
	
	# Animasi posisi - turun dari atas
	margin_tween.tween_property(margin_container, "position:y", original_margin_position.y, ANIMATION_DURATION)\
		.set_trans(TWEEN_TRANS).set_ease(TWEEN_EASE)
	
	# Animasi fade in
	margin_tween.tween_property(margin_container, "modulate:a", 1.0, ANIMATION_DURATION * 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	audio_stream_player_2d.max_distance = 9999
	audio_stream_player_2d.play()
	# Tunggu sampai animasi margin_container selesai
	await margin_tween.finished
	
	# Tampilkan label dan mainkan SFX
	
	# Tunggu 3 detik lalu sembunyikan
	await get_tree().create_timer(3.0).timeout
	hide_celebration()

func hide_celebration():
	# Animasi margin_container naik ke atas sambil fade out
	var hide_tween = create_tween()
	hide_tween.set_parallel(true)
	
	# Animasi posisi - naik ke atas
	hide_tween.tween_property(margin_container, "position:y", -margin_container.size.y, ANIMATION_DURATION * 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Animasi fade out
	hide_tween.tween_property(margin_container, "modulate:a", 0.0, ANIMATION_DURATION * 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await hide_tween.finished
	
	root_control.visible = false
	#get_tree().paused = false
	is_done = true
