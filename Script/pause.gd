extends Control

@export var pause_key: String = "esc"

@onready var resume_button = $Panel/VBoxContainer/resume
@onready var controls_button = $Panel/VBoxContainer/controls
@onready var quit_button = $Panel/VBoxContainer/quit

@onready var confirm_panel = $Confirm
@onready var yes_button: Button = $Confirm/VBoxContainer/HBoxContainer/ya
@onready var no_button: Button = $Confirm/VBoxContainer/HBoxContainer/tidak

@onready var control_menu = $Control
@onready var exit_control = $Control/Panel/HBoxContainer/exit

@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover


# ========= NAVIGASI BUTTON PAUSE =========
var buttons: Array[Button] = []
var selected_index: int = 0

# ========= NAVIGASI BUTTON CONFIRM =========
var confirm_buttons: Array[Button] = []
var confirm_index: int = 0


func _ready() -> void:
	# Tombol untuk pause menu
	buttons = [resume_button, controls_button, quit_button]

	# Tombol untuk confirm menu
	confirm_buttons = [yes_button, no_button]

	# Disable focus
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for btn in confirm_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_update_focus()
	_update_confirm_focus()

	# Connect tombol
	resume_button.pressed.connect(_on_resume_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	exit_control.pressed.connect(_on_exit_control_pressed)

	visible = false
	confirm_panel.visible = false
	control_menu.visible = false


func _process(delta):
	if Input.is_action_just_pressed(pause_key):
		toggle_pause()


func toggle_pause():
	# ESC di control → balik ke pause
	if control_menu.visible:
		control_menu.visible = false
		$Panel.visible = true
		$TextEdit.visible = true
		$TextureRect.visible = true
		return

	# ESC di confirm → balik ke pause
	if confirm_panel.visible:
		confirm_panel.visible = false
		$Panel.visible = true
		$TextEdit.visible = true
		$TextureRect.visible = true
		return

	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	$Panel.visible = get_tree().paused

	if visible:
		selected_index = 0
		_update_focus()
		confirm_index = 0
		_update_confirm_focus()


# ====================== INPUT NAVIGASI ==========================
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ======= Navigasi Confirm Menu (YES / NO) =======
	if confirm_panel.visible:
		# Left / A
		if event.is_action_pressed("menu_left"):
			_move_confirm(-1)

		# Right / D
		elif event.is_action_pressed("menu_right"):
			_move_confirm(1)

		# TAB → geser kanan terus
		elif event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
			_move_confirm(1)

		# Enter
		elif event.is_action_pressed("resume"):
			confirm_buttons[confirm_index].emit_signal("pressed")

		return

	# ======= Navigasi Pause Menu =======
	if $Panel.visible:
		if event.is_action_pressed("menu_up"):
			_move_selection(-1)

		elif event.is_action_pressed("menu_down"):
			_move_selection(1)

		elif event.is_action_pressed("resume"):
			buttons[selected_index].emit_signal("pressed")



# ====================== PAUSE BUTTON NAV ==========================
func _move_selection(dir: int) -> void:
	selected_index += dir

	if selected_index < 0:
		selected_index = buttons.size() - 1
	elif selected_index >= buttons.size():
		selected_index = 0
	
	if sfx_hover.playing:
		sfx_hover.stop()
	sfx_hover.play()
	_update_focus()


func _update_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(1, 1, 1)
			btn.scale = Vector2(1, 1)


# ====================== CONFIRM YES/NO NAV ==========================
func _move_confirm(dir: int) -> void:
	confirm_index += dir

	if confirm_index < 0:
		confirm_index = confirm_buttons.size() - 1
	elif confirm_index >= confirm_buttons.size():
		confirm_index = 0

	_update_confirm_focus()


func _update_confirm_focus() -> void:
	for i in range(confirm_buttons.size()):
		var btn = confirm_buttons[i]
		if i == confirm_index:
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(1, 1, 1)
			btn.scale = Vector2(1, 1)


# ======================== BUTTON FUNCTIONS =========================

func _on_resume_pressed():
	sfx_button.play()
	get_tree().paused = false
	visible = false

func _on_controls_pressed():
	sfx_button.play()
	$Panel.visible = false
	$TextEdit.visible = false
	$TextureRect.visible = false
	control_menu.visible = true

func _on_exit_control_pressed():
	sfx_button.play()
	control_menu.visible = false
	$Panel.visible = true
	$TextEdit.visible = true
	$TextureRect.visible = true

func _on_quit_pressed():
	sfx_button.play()
	$Panel.visible = false
	$TextEdit.visible = false
	$TextureRect.visible = false
	confirm_panel.visible = true
	confirm_index = 0
	_update_confirm_focus()

func _on_yes_pressed():
	sfx_button.play()
	get_tree().paused = false
	GameData.set_not_death(false)
	print(GameData.has_dead)
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")

func _on_no_pressed():
	sfx_button.play()
	confirm_panel.visible = false
	$Panel.visible = true
	$TextEdit.visible = true
	$TextureRect.visible = true
