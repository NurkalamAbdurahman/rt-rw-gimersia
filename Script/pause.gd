extends Control

@export var pause_key: String = "esc"

@onready var resume_button = $Panel/VBoxContainer/resume
@onready var controls_button = $Panel/VBoxContainer/controls
@onready var quit_button = $Panel/VBoxContainer/quit
@onready var confirm_panel = $Confirm
@onready var yes_button = $Confirm/Panel/HBoxContainer/ya
@onready var no_button = $Confirm/Panel/HBoxContainer2/tidak

@onready var control_menu = $Control
@onready var exit_control = $Control/Panel/HBoxContainer/exit

func _ready() -> void:
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
	# ✅ Jika lagi di menu controls dan tekan ESC → kembali ke pause menu
	if control_menu.visible:
		control_menu.visible = false
		$Panel.visible = true
		$TextEdit.visible = true
		$TextureRect.visible = true
		return

	# ✅ Jika lagi di confirm quit dan tekan ESC → kembali ke pause menu
	if confirm_panel.visible:
		confirm_panel.visible = false
		$Panel.visible = true
		$TextEdit.visible = true
		$TextureRect.visible = true
		return

	# ✅ Normal pause / unpause
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	$Panel.visible = get_tree().paused


func _on_resume_pressed():
	get_tree().paused = false
	visible = false


# ======================== CONTROLS MENU ========================

func _on_controls_pressed():
	$Panel.visible = false
	$TextEdit.visible = false
	$TextureRect.visible = false
	control_menu.visible = true

func _on_exit_control_pressed():
	control_menu.visible = false
	$Panel.visible = true
	$TextEdit.visible = true
	$TextureRect.visible = true


# ========================= QUIT GAME ============================

func _on_quit_pressed():
	$Panel.visible = false
	$TextEdit.visible = false
	$TextureRect.visible = false
	confirm_panel.visible = true

func _on_yes_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/FIX/layar_MaenMenu.tscn")

func _on_no_pressed():
	confirm_panel.visible = false
	$Panel.visible = true
	$TextEdit.visible = true
	$TextureRect.visible = true
