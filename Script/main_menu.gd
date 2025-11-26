extends Control

# ============================================================
# MAIN MENU CONTROLLER - OPTIMIZED VERSION
# Mengatur navigasi keyboard dan mouse dengan animasi smooth
# ============================================================

# ============================================================
# NODE REFERENCES - Referensi ke node UI
# ============================================================
@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit
@onready var control_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Control
@onready var stage_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Stage
@onready var creadit_button: Button = $MarginContainer2/Creadit

# Panel references
@onready var creadit_panel: Control = $Creadit
@onready var stage_level: Control = $StageLevel
@onready var control_panel: Panel = $Control2

# Audio references
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover
@onready var sfx_start: AudioStreamPlayer2D = $SFX_Start
@onready var bgm: AudioStreamPlayer2D = $BGM

# Video player reference
@onready var video_stream_player: VideoStreamPlayer = $Creadit/TextureRect/VideoStreamPlayer

# ============================================================
# STATE VARIABLES - Variabel status menu
# ============================================================
var is_panel_open: bool = false  # Apakah ada panel yang sedang terbuka
var selected_index: int = 0  # Index tombol yang sedang dipilih
var navigatable_buttons: Array[Button] = []  # Array tombol yang bisa dinavigasi
var is_mouse_control: bool = false  # Flag untuk mendeteksi kontrol mouse

# ============================================================
# ANIMATION CONSTANTS - Konstanta untuk animasi
# ============================================================
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const NORMAL_MODULATE: Color = Color(0.6, 0.6, 0.6)
const HOVER_MODULATE: Color = Color(1.0, 1.0, 1.0)
const DISABLED_MODULATE: Color = Color(0.3, 0.3, 0.3, 0.5)
const ANIMATION_DURATION: float = 0.15 

# ============================================================
# INITIALIZATION - Inisialisasi menu
# ============================================================
func _ready() -> void:
	# Load dan play background music
	_load_and_loop_bgm("res://Assets/Audio/bgm.ogg")
	
	# Setup array tombol yang bisa dinavigasi
	_setup_navigatable_buttons()
	
	# Setup mouse interaction untuk semua tombol
	_setup_mouse_interactions()
	
	# Connect button signals
	_connect_button_signals()
	
	# Setup initial visual state
	_update_button_visuals()
	
	# Hide all panels initially
	_hide_all_panels()
	
	# Enable input processing
	set_process_input(true)

# ============================================================
# BGM MANAGEMENT - Manajemen musik latar
# ============================================================
func _load_and_loop_bgm(path: String) -> void:
	"""Load dan play BGM dengan looping"""
	var new_stream = load(path)
	if new_stream is AudioStreamOggVorbis:
		new_stream.loop = true
		bgm.stream = new_stream
		bgm.play()
	else:
		push_error("Failed to load BGM - not OGG Vorbis format")

# ============================================================
# BUTTON SETUP - Setup tombol-tombol menu
# ============================================================
func _setup_navigatable_buttons() -> void:
	"""Setup array tombol berdasarkan progress game"""
	navigatable_buttons.clear()
	
	# Tombol yang selalu tersedia
	navigatable_buttons.append(start_button)
	
	# Tombol Stage - unlock jika Stage 1 selesai
	if GameData.is_finish_stage1:
		navigatable_buttons.append(stage_button)
		stage_button.disabled = false
	else:
		stage_button.disabled = true
	
	# Tombol lainnya
	navigatable_buttons.append(control_button)
	navigatable_buttons.append(quit_button)
	navigatable_buttons.append(creadit_button)
	
	

func _setup_mouse_interactions() -> void:
	"""Setup mouse hover dan click untuk semua tombol"""
	for i in range(navigatable_buttons.size()):
		var btn = navigatable_buttons[i]
		
		# Disable built-in focus agar kita kontrol manual
		btn.focus_mode = Control.FOCUS_NONE
		
		# Enable mouse filter agar bisa detect hover
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Connect mouse signals
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(i))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(i))

func _connect_button_signals() -> void:
	"""Connect semua button pressed signals"""
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	stage_button.pressed.connect(_on_stage_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)

func _hide_all_panels() -> void:
	"""Hide semua panel di awal"""
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false

# ============================================================
# INPUT HANDLING - Handling input keyboard
# ============================================================
func _input(event: InputEvent) -> void:
	# Jika panel terbuka, hanya tangani ESC untuk menutup
	if is_panel_open:
		if event.is_action_pressed("ui_cancel"):
			_close_all_panels()
		return
	
	# Navigasi keyboard menu utama
	if event.is_action_pressed("menu_down") or event.is_action_pressed("ui_down"):
		_navigate_menu(1)
		is_mouse_control = false
		
	elif event.is_action_pressed("menu_up") or event.is_action_pressed("ui_up"):
		_navigate_menu(-1)
		is_mouse_control = false
		
	elif event.is_action_pressed("ui_accept"):
		_activate_selected_button()
		is_mouse_control = false

# ============================================================
# NAVIGATION - Navigasi menu dengan keyboard
# ============================================================
func _navigate_menu(direction: int) -> void:
	"""Navigate menu ke atas atau ke bawah"""
	if navigatable_buttons.is_empty():
		return
	
	# Update selected index dengan wrapping
	selected_index = (selected_index + direction) % navigatable_buttons.size()
	if selected_index < 0:
		selected_index = navigatable_buttons.size() - 1
	
	# Skip disabled buttons
	var iterations = 0
	while navigatable_buttons[selected_index].disabled and iterations < navigatable_buttons.size():
		selected_index = (selected_index + direction) % navigatable_buttons.size()
		if selected_index < 0:
			selected_index = navigatable_buttons.size() - 1
		iterations += 1
	
	# Play hover sound
	_play_sfx(sfx_hover)
	
	# Update visual
	_update_button_visuals()

func _activate_selected_button() -> void:
	"""Activate tombol yang sedang dipilih"""
	if navigatable_buttons.is_empty() or navigatable_buttons[selected_index].disabled:
		return
	
	navigatable_buttons[selected_index].emit_signal("pressed")

# ============================================================
# MOUSE INTERACTION - Handling hover dan click mouse
# ============================================================
func _on_button_mouse_entered(button_index: int) -> void:
	"""Called saat mouse hover ke tombol"""
	var btn = navigatable_buttons[button_index]
	
	# Skip jika tombol disabled
	if btn.disabled:
		return
	
	# Update selected index
	if selected_index != button_index:
		selected_index = button_index
		_play_sfx(sfx_hover)
	
	# Set flag mouse control
	is_mouse_control = true
	
	# Update visual dengan animasi
	_update_button_visuals()

func _on_button_mouse_exited(button_index: int) -> void:
	"""Called saat mouse keluar dari tombol"""
	# Jika menggunakan keyboard, tidak perlu update
	if not is_mouse_control:
		return
	
	# Update visual state
	_update_button_visuals()

# ============================================================
# VISUAL UPDATES - Update tampilan tombol dengan animasi
# ============================================================
func _update_button_visuals() -> void:
	"""Update visual semua tombol dengan animasi smooth"""
	for i in range(navigatable_buttons.size()):
		var btn = navigatable_buttons[i]
		
		# Skip jika disabled (kecuali stage button yang perlu styling khusus)
		if btn.disabled and btn != stage_button:
			continue
		
		# Tentukan apakah tombol ini selected/hovered
		var is_selected = (i == selected_index and not is_panel_open)
		
		# Animate scale dan modulate
		if is_selected:
			_animate_button(btn, HOVER_SCALE, HOVER_MODULATE)
		else:
			_animate_button(btn, NORMAL_SCALE, NORMAL_MODULATE)
	
	# Handle stage button disabled state
	if stage_button.disabled:
		_animate_button(stage_button, NORMAL_SCALE, DISABLED_MODULATE)

func _animate_button(btn: Button, target_scale: Vector2, target_modulate: Color) -> void:
	"""Animate button dengan tween untuk smooth transition"""
	# Create tween untuk animasi
	var tween = create_tween()
	tween.set_parallel(true)  # Jalankan animasi secara bersamaan
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate scale
	tween.tween_property(btn, "scale", target_scale, ANIMATION_DURATION)
	
	# Animate modulate (color)
	tween.tween_property(btn, "modulate", target_modulate, ANIMATION_DURATION)

# ============================================================
# BUTTON CALLBACKS - Fungsi callback saat tombol ditekan
# ============================================================
func _on_start_pressed() -> void:
	"""Handler untuk tombol Start - Mulai game dari Stage 1"""
	_play_sfx(sfx_start)
	start_button.disabled = true
	
	# Fade transition ke Stage 1
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	GameData.enter_stage()
	#GameData.hard_reset()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")

func _on_stage_pressed() -> void:
	"""Handler untuk tombol Stage - Buka menu stage selection"""
	if stage_button.disabled:
		return
	
	_play_sfx(sfx_button)
	stage_level.visible = true
	is_panel_open = true

func _on_creadit_pressed() -> void:
	"""Handler untuk tombol Credit - Buka panel credit"""
	_play_sfx(sfx_button)
	creadit_panel.visible = true
	
	# Play video jika ada
	if video_stream_player:
		video_stream_player.play()
	
	is_panel_open = true

func _on_control_pressed() -> void:
	"""Handler untuk tombol Control - Buka panel control"""
	_play_sfx(sfx_button)
	control_panel.visible = true
	is_panel_open = true

func _on_quit_pressed() -> void:
	"""Handler untuk tombol Quit - Keluar dari game"""
	_play_sfx(sfx_button)
	get_tree().quit()

# ============================================================
# PANEL MANAGEMENT - Manajemen panel (open/close)
# ============================================================
func _close_all_panels() -> void:
	"""Close semua panel yang terbuka"""
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false
	
	# Stop video jika sedang playing
	if video_stream_player and video_stream_player.is_playing():
		video_stream_player.stop()
	
	is_panel_open = false
	
	# Play SFX
	_play_sfx(sfx_button)
	
	# Update visual kembali ke state normal
	_update_button_visuals()

# ============================================================
# UTILITY FUNCTIONS - Fungsi helper
# ============================================================
func _play_sfx(sfx: AudioStreamPlayer2D) -> void:
	"""Play sound effect jika ada"""
	if sfx:
		sfx.play()
