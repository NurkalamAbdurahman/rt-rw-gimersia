extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ui/Shop.tscn")
