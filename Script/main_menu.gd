extends Control

# Catatan: Asumsikan Anda memiliki file global singleton "GameData.gd"
# dengan struktur minimal seperti ini (Ganti dengan file GameData Anda yang sesungguhnya):
#
# # GameData.gd
# extends Node
# var is_finish_stage1: bool = false 

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
var is_panel_open: bool = false
@onready var stage_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Stage
@onready var stage_level: Control = $StageLevel

var selected_index: int = 0
var buttons: Array[Button] = []
var navigatable_buttons: Array[Button] = [] # <-- LIST TOMBOL YANG BISA DINAVIGASI

func load_and_loop(path) :
	var new_stream = load(path)
	if new_stream is AudioStreamOggVorbis:
		new_stream.loop = true
		bgm.stream = new_stream
		bgm.play()
	else:
		print("gagal memuat file bukan ogg vorbis")

func _ready() -> void:
	# 1. Penanganan Tampilan Stage Level
	if GameData.is_finish_stage1 == false:
		stage_level.visible = false

	# 2. Inisialisasi Tombol
	# Semua tombol yang ada di menu utama
	buttons = [start_button, creadit_button, quit_button, control_button, stage_button]
	
	# 3. KONDISI NONAKTIFKAN TOMBOL JIKA STAGE BELUM SELESAI
	if GameData.is_finish_stage1 == false:
		# 3a. Nonaktifkan fungsi tombol (Mouse/Klik)
		stage_button.disabled = true
		
		# 3b. Atur opasitas rendah (Visual)
		# Warna abu-abu gelap dengan alpha 0.5 (50% opasitas)
		stage_button.modulate = Color(0.3, 0.3, 0.3, 0.5) 
		stage_button.scale = Vector2(1, 1) # Pastikan skala normal
		
		# 3c. Hapus tombol dari list navigasi keyboard
		navigatable_buttons = [start_button, creadit_button, quit_button, control_button]
	else:
		# Jika stage 1 sudah selesai, semua tombol bisa dinavigasi
		navigatable_buttons = buttons
		
	
	# 4. Pengaturan Umum Tombol
	load_and_loop("res://Assets/Audio/bgm.ogg")
	
	# Disable auto focus & mouse untuk tombol yang dinavigasi
	for btn in navigatable_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect event
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)
	stage_button.pressed.connect(_on_stage_pressed)
	

	# Indikasi fokus awal
	if navigatable_buttons.size() > 0:
		_update_button_focus()

	set_process_input(true)


func _input(event: InputEvent) -> void:
	# JIKA ADA PANEL YANG TERBUKA, UTAMAKAN PENUTUPAN PANEL
	if is_panel_open:
		if event.is_action_pressed("ui_cancel"): 
			_on_panel_closed()
			return 
		return 

	# LOGIKA NAVIGASI MENU UTAMA
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
			# Pastikan list tidak kosong sebelum mencoba menekan tombol
			if navigatable_buttons.size() > 0:
				navigatable_buttons[selected_index].emit_signal("pressed")

func _move_selection(direction: int) -> void:
	var max_index = navigatable_buttons.size()
	
	if max_index == 0:
		return

	selected_index += direction

	# Looping
	if selected_index < 0:
		selected_index = max_index - 1
	elif selected_index >= max_index:
		selected_index = 0

	# 🔊 Mainkan sound effect
	if sfx_hover.playing:
		sfx_hover.stop()
	sfx_hover.play()

	_update_button_focus()

func _update_button_focus() -> void:
	# 1. Atur visual tombol yang bisa dinavigasi
	for i in range(navigatable_buttons.size()):
		var btn = navigatable_buttons[i]

		if i == selected_index:
			# Fokus
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			# Tidak Fokus
			btn.modulate = Color(0.7, 0.7, 0.7)
			btn.scale = Vector2(1, 1)

	# 2. Pertahankan visual tombol yang dinonaktifkan
	if stage_button.disabled == true:
		stage_button.modulate = Color(0.3, 0.3, 0.3, 0.5) # Opasitas rendah
		stage_button.scale = Vector2(1, 1) # Pastikan skalanya normal


func _on_start_pressed() -> void:
	sfx_button.play() # Gunakan SFX tombol biasa
	print("Start Menu Pressed, opening Stage Level")
	
	# Tampilkan Stage Level
	stage_level.visible = true
	is_panel_open = true # Penting agar navigasi menu utama berhenti


func _on_quit_pressed() -> void:
	sfx_button.play()
	print("Quit pressed")
	get_tree().quit()


func _on_control_pressed() -> void:
	sfx_button.play()
	print("Control Menu Opened")
	control_panel.visible = true
	is_panel_open = true

func _on_stage_pressed() -> void:
	# Fungsi ini tetap dipanggil, tapi tidak akan dieksekusi jika stage_button.disabled = true
	if stage_button.disabled:
		print("Stage button is locked.")
		return 
		
	sfx_button.play()
	print("Stage Level Menu Opened")
	stage_level.visible = true
	is_panel_open = true


func _on_creadit_pressed() -> void:
	sfx_button.play()
	print("Creadit Menu Opened")
	creadit_panel.visible = true
	video_stream_player.play()
	is_panel_open = true


# Hubungkan tombol "Close" atau "Back" di dalam control_panel/creadit_panel ke fungsi ini
func _on_panel_closed() -> void:
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false
	
	is_panel_open = false 

	# Setelah panel ditutup, kita ingin fokus kembali ke tombol yang terpilih
	_update_button_focus()
