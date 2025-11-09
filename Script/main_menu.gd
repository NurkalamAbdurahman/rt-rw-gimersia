extends Control

@onready var start_game: Button = $MarginContainer/VBoxContainer/Start

func _ready():
	start_game.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	start_game.disabled = true
	
	# Muat scene transisi secara dinamis
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)

	# Jalankan fade-out dulu, baru pindah ke stage1
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/stage1.tscn")
