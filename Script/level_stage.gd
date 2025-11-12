extends Control

# Variabel Button
@onready var stage_1: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage1
@onready var stage_2: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage2
@onready var stage_3: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage3

# Variabel State & Navigasi
var buttons: Array = []
var selected_index: int = 0

# Variabel Audio
@onready var sfx_hover: AudioStreamPlayer = $SFX_Hover
@onready var sfx_start: AudioStreamPlayer = $SFX_Start # Tambahkan SFX untuk start/pilih

# Variabel Visual untuk Status Terkunci
const LOCKED_COLOR = Color(0.3, 0.3, 0.3, 0.5) # Warna redup (abu-abu gelap, 50% opasitas)
const UNLOCKED_COLOR = Color(0.7, 0.7, 0.7) # Warna abu-abu normal saat tidak fokus

func _ready() -> void:
	# Masukkan semua tombol ke array
	buttons = [stage_1, stage_2, stage_3]

	# Connect signal tombol klik mouse
	for btn in buttons:
		btn.pressed.connect(_on_button_pressed.bind(btn)) # Mengirim referensi tombol saat dipanggil

	# Terapkan kunci pada tombol yang belum terbuka
	_update_lock_status()
	
	# Set fokus awal
	_update_button_focus()

func _update_lock_status():
	# Stage 2 terkunci jika Stage 1 belum selesai
	if GameData.is_finish_stage1 == false:
		stage_2.disabled = true
		stage_2.add_theme_color_override("font_color", LOCKED_COLOR)
	else:
		stage_2.disabled = false
		
	# Stage 3 terkunci jika Stage 2 belum selesai
	if GameData.is_finish_stage2 == false:
		stage_3.disabled = true
		stage_3.add_theme_color_override("font_color", LOCKED_COLOR)
	else:
		stage_3.disabled = false


func _process(delta):
	# Navigasi Kanan
	if Input.is_action_just_pressed("menu_right"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	# Navigasi Kiri
	elif Input.is_action_just_pressed("menu_left"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	# Pilih
	elif Input.is_action_just_pressed("ui_accept"):
		# Hanya emit signal jika tombol TIDAK disabled (untuk mencegah Stage 2/3 aktif via keyboard jika terkunci)
		if buttons[selected_index].disabled == false:
			buttons[selected_index].emit_signal("pressed")


func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		
		# Jika tombol terkunci, pertahankan visual terkunci dan lewati
		if btn.disabled == true:
			btn.scale = Vector2(1, 1)
			btn.add_theme_color_override("font_color", LOCKED_COLOR)
			continue # Lanjut ke tombol berikutnya

		# Tombol yang bisa diakses (Tidak disabled)
		if i == selected_index:
			if sfx_hover and not sfx_hover.playing:
				sfx_hover.play()
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # teks emas (FOKUS)
			btn.scale = Vector2(1.12, 1.12) # sedikit membesar
		else:
			btn.add_theme_color_override("font_color", UNLOCKED_COLOR) # teks abu-abu (NORMAL)
			btn.scale = Vector2(1, 1) # normal


func _on_button_pressed(button: Button):
	# Dapatkan jalur scene berdasarkan nama tombol
	var scene_path: String
	
	if button == stage_2:
		scene_path = "res://scenes/FIX/STAGE_2.tscn"
	elif button == stage_3:
		scene_path = "res://scenes/FIX/STAGE_3.tscn"
	else:
		# Jika ada tombol lain yang terhubung, tapi tidak ditangani
		print("Tombol tidak dikenali.")
		return
	
	# Mainkan SFX start dan ganti scene
	if sfx_start:
		sfx_start.play()
		await sfx_start.finished # Tunggu SFX selesai sebelum ganti scene
	
	print("Loading Scene: " + scene_path)
	get_tree().change_scene_to_file(scene_path)
