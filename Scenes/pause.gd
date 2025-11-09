extends Control

@onready var resume_button = $PanelContainer/VBoxContainer/resume
@onready var restart_button = $PanelContainer/VBoxContainer/restart
@onready var controls_button = $PanelContainer/VBoxContainer/controls
@onready var quit_button = $PanelContainer/VBoxContainer/quit

func _ready():
	visible = false  # menu pause awalnya tersembunyi

	# hubungkan tombol
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(delta):
	# toggle pause menu dengan Esc
	if Input.is_action_just_pressed("esc"):
		if visible:
			hide_pause()
		else:
			show_pause()

func show_pause():
	visible = true
	get_tree().paused = true

func hide_pause():
	visible = false
	get_tree().paused = false

func _on_resume_pressed():
	hide_pause()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_controls_pressed():
	print("Controls button pressed")  # nanti dihubungkan ke tampilan controls

func _on_quit_pressed():
	get_tree().quit()
