extends Node2D  # <-- pastikan baris ini ada di atas

func _input(event):
	if event.is_action_pressed("open_map"):
		var map_scene = load("res://Scenes/map_editor.tscn").instantiate()
		get_tree().root.add_child(map_scene)
		get_tree().paused = true
		map_scene.owner = null
