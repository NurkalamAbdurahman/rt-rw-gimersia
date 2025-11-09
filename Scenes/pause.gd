extends Control

@export var pause_key: String = "esc"

@onready var resume_button = $PanelContainer/VBoxContainer/resume
@onready var restart_button = $PanelContainer/VBoxContainer/restart
@onready var quit_button = $PanelContainer/VBoxContainer/quit

func _ready() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(pause_key):
		toggle_pause()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()
