extends Control

# Catatan: Pastikan GameData.gd memiliki:
# var is_finish_stage1: bool = false
# var is_finish_stage2: bool = false

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
@onready var stage_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Stage
@onready var stage_level: Control = $StageLevel

var is_panel_open: bool = false
var selected_index: int = 0
var navigatable_buttons: Array[Button] = []

func load_and_loop(path: String) -> void:
	var new_stream = load(path)
	if new_stream is AudioStreamOggVorbis:
		new_stream.loop = true
		bgm.stream = new_stream
		bgm.play()
	else:
		print("Gagal memuat file - bukan OGG Vorbis")

func _ready() -> void:
	# 1. Load BGM
	load_and_loop("res://Assets/Audio/bgm.ogg")
	
	# 2. Setup navigatable buttons berdasarkan progress
	_setup_navigatable_buttons()
	
	# 3. Disable auto focus & mouse untuk semua tombol
	for btn in navigatable_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. Connect signals
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)
	stage_button.pressed.connect(_on_stage_pressed)
	
	# 5. Set initial focus
	if navigatable_buttons.size() > 0:
		_update_button_focus()
	
	# 6. Hide panels
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false
	
	set_process_input(true)

func _setup_navigatable_buttons() -> void:
	navigatable_buttons.clear()
	
	# Selalu tambahkan tombol-tombol ini
	navigatable_buttons.append(start_button)
	
	# Tombol Stage hanya bisa diakses jika minimal Stage 1 sudah selesai
	if GameData.is_finish_stage1:
		navigatable_buttons.append(stage_button)
		stage_button.disabled = false
		stage_button.modulate = Color(0.7, 0.7, 0.7)
	else:
		stage_button.disabled = true
		stage_button.modulate = Color(0.3, 0.3, 0.3, 0.5)
	
	navigatable_buttons.append(creadit_button)
	navigatable_buttons.append(control_button)
	navigatable_buttons.append(quit_button)

func _input(event: InputEvent) -> void:
	# Jika ada panel terbuka, prioritaskan penutupan
	if is_panel_open:
		if event.is_action_pressed("ui_cancel"):
			_on_panel_closed()
		return
	
	# Navigasi menu utama
	if event.is_action_pressed("menu_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_move_selection(1)
	elif event.is_action_pressed("menu_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_move_selection(-1)
	elif event.is_action_pressed("ui_accept"):
		if navigatable_buttons.size() > 0:
			navigatable_buttons[selected_index].emit_signal("pressed")

func _move_selection(direction: int) -> void:
	if navigatable_buttons.size() == 0:
		return
	
	selected_index = (selected_index + direction) % navigatable_buttons.size()
	
	# Handle wrap around
	if selected_index < 0:
		selected_index = navigatable_buttons.size() - 1
	
	# Play hover sound
	sfx_hover.play()
	
	_update_button_focus()

func _update_button_focus() -> void:
	# Update visual untuk semua tombol yang bisa dinavigasi
	for i in range(navigatable_buttons.size()):
		var btn = navigatable_buttons[i]
		
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)
			btn.scale = Vector2(1, 1)
	
	# Pastikan tombol yang disabled tetap terlihat disabled
	if stage_button.disabled:
		stage_button.modulate = Color(0.3, 0.3, 0.3, 0.5)
		stage_button.scale = Vector2(1, 1)

func _on_start_pressed() -> void:
	if sfx_start:
		sfx_start.play()
	print("Start pressed - Loading Stage 1")
	start_button.disabled = true
	
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")

func _on_quit_pressed() -> void:
	if sfx_button:
		sfx_button.play()
	print("Quit pressed")
	get_tree().quit()

func _on_control_pressed() -> void:
	if sfx_button:
		sfx_button.play()
	print("Control Menu Opened")
	control_panel.visible = true
	is_panel_open = true

func _on_stage_pressed() -> void:
	if stage_button.disabled:
		print("Stage button is locked")
		return
	
	if sfx_button:
		sfx_button.play()
	print("Stage Level Menu Opened")
	stage_level.visible = true
	is_panel_open = true

func _on_creadit_pressed() -> void:
	if sfx_button:
		sfx_button.play()
	print("Credit Menu Opened")
	creadit_panel.visible = true
	if video_stream_player:
		video_stream_player.play()
	is_panel_open = true

func _on_panel_closed() -> void:
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false
	
	if video_stream_player and video_stream_player.is_playing():
		video_stream_player.stop()
	
	is_panel_open = false
	_update_button_focus()
