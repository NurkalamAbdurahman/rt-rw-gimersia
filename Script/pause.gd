extends Control

@export var pause_key: String = "esc"

@onready var resume_button = $Panel/VBoxContainer/resume
@onready var quit_button = $Panel/VBoxContainer/quit
@onready var confirm_panel = $Confirm
@onready var yes_button = $Confirm/Panel/HBoxContainer/ya
@onready var no_button = $Confirm/Panel/HBoxContainer2/tidak

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

	visible = false
	confirm_panel.visible = false

func _process(delta):
	if Input.is_action_just_pressed(pause_key):
		toggle_pause()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	confirm_panel.visible = false  # sembunyikan confirm kalau pause muncul

func _on_resume_pressed():
	get_tree().paused = false
	visible = false
	
func _on_quit_pressed():
	# sembunyikan pause panel utama dan elemen lain
	$Panel.visible = false
	$TextEdit.visible = false
	$TextureRect.visible = false
	# munculkan confirm panel
	confirm_panel.visible = true

func _on_yes_pressed():
	get_tree().paused = false  # pastikan game tidak paused
	get_tree().change_scene_to_file("res://Scenes/ui/MainMenu.tscn")
func _on_no_pressed():
	# sembunyikan confirm panel
	confirm_panel.visible = false
	# munculkan kembali pause panel dan elemen lain
	$Panel.visible = true
	$TextEdit.visible = true
	$TextureRect.visible = true
