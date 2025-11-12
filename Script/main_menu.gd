extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit
@onready var control_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Control
@onready var control_panel: Control = $Control
@onready var creadit_button: Button = $MarginContainer2/Creadit
@onready var creadit_panel: Control = $Creadit
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover
@onready var sfx_start: AudioStreamPlayer2D = $SFX_Start
@onready var bgm: AudioStreamPlayer2D = $BGM
@onready var video_stream_player: VideoStreamPlayer = $Creadit/TextureRect/VideoStreamPlayer
var is_panel_open: bool = false # <-- TAMBAHKAN INI

var selected_index: int = 0
var buttons: Array[Button] = []

func load_and_loop(path) :
	var new_stream = load(path)
	if new_stream is AudioStreamOggVorbis:
		new_stream.loop = true
		bgm.stream = new_stream
		bgm.play()
	else:
		print("gagal memuat file bukan ogg vorbis")

func _ready() -> void:
	# Semua tombol yang bisa dinavigasi dengan arrow keys
	buttons = [start_button,creadit_button, quit_button, control_button]
	load_and_loop("res://Assets/Audio/bgm.ogg")
	# Disable auto focus & mouse
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect event
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)

	# Indikasi fokus awal
	_update_button_focus()

	set_process_input(true)



func _input(event: InputEvent) -> void:
	# JIKA ADA PANEL YANG TERBUKA, KITA HANYA PERLU MEMPERHATIKAN TOMBOL UNTUK MENUTUP PANEL TERSEBUT
	if is_panel_open:
		if event.is_action_pressed("ui_cancel"): # Biasanya terikat ke tombol ESC
			_on_panel_closed()
			return # <-- KELUAR SETELAH MENUTUP PANEL
		return # <-- JIKA PANEL TERBUKA, KELUAR DARI FUNGSI INI

	# LOGIKA NAVIGASI MENU UTAMA HANYA BERJALAN JIKA is_panel_open = false
	if event.is_action_pressed("menu_up"):
		_move_selection(1)

	elif event.is_action_pressed("menu_down"):
		_move_selection(-1)

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			_move_selection(1)
			
		elif event.keycode == KEY_S:
			_move_selection(-1)
			
		elif event.is_action_pressed("ui_accept"):
			buttons[selected_index].emit_signal("pressed")

func _move_selection(direction: int) -> void:
	selected_index += direction

	# Looping
	if selected_index < 0:
		selected_index = buttons.size() - 1
	elif selected_index >= buttons.size():
		selected_index = 0

	# 🔊 Mainkan sound effect
	if sfx_hover.playing:
		sfx_hover.stop()
	sfx_hover.play()

	_update_button_focus()




func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]

		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)   # emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)     # abu-abu
			btn.scale = Vector2(1, 1)



func _on_start_pressed() -> void:
	sfx_start.play()
	print("Start pressed")
	start_button.disabled = true
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")


func _on_quit_pressed() -> void:
	sfx_button.play()
	print("Quit pressed")
	get_tree().quit()


func _on_control_pressed() -> void:
	sfx_button.play()
	print("Control Menu Opened")
	control_panel.visible = true
	is_panel_open = true # <-- SET KE TRUE


func _on_creadit_pressed() -> void:
	sfx_button.play()
	print("Creadit Menu Opened")
	creadit_panel.visible = true
	video_stream_player.play()
	is_panel_open = true # <-- SET KE TRUE8

# Hubungkan tombol "Close" atau "Back" di dalam control_panel/creadit_panel ke fungsi ini
func _on_panel_closed() -> void:
	control_panel.visible = false
	creadit_panel.visible = false
	is_panel_open = false # <-- SET KEMBALI KE FALSE

	# PENTING: Panggil fungsi ini jika kamu juga menutup panel dengan tombol "ESC"
