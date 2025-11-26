extends CanvasLayer

@onready var root_control: Control = $Control
@onready var label: Label = $Control/MarginContainer/Label
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var panel: Panel = $Control/Panel

var is_done: bool = false

func _ready():
	root_control.visible = false
	# Setup awal untuk panel dan label
	panel.scale = Vector2.ZERO
	
	# Atur pivot_offset ke tengah panel agar scaling berasal dari pusat
	panel.pivot_offset = panel.size / 2

func show_celebration():
	get_tree().paused = true
	root_control.visible = true
	
	# Pastikan pivot_offset sudah diatur ke tengah sebelum animasi
	panel.pivot_offset = panel.size / 2
	
	# Animasi panel membesar selama 5 detik dari tengah
	var panel_tween = create_tween()
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Tunggu sampai animasi panel selesai
	await panel_tween.finished
	
	# Tampilkan label dan mainkan SFX
	audio_stream_player_2d.max_distance = 9999
	audio_stream_player_2d.play()
	
	# Tunggu 3 detik lalu sembunyikan
	await get_tree().create_timer(3.0).timeout
	hide_celebration()

func hide_celebration():
	root_control.visible = false
	get_tree().paused = false
	is_done = true
	# Reset state untuk penggunaan berikutnya
	panel.scale = Vector2.ZERO
