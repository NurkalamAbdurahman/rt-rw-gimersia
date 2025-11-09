extends Control

@onready var item_container = $Background/ScrollContainer/GridContainer
@onready var close_button = $Background/Button

var item_scene = preload("res://Scenes/ui/ItemCard.tscn")

func _ready():
	var items = [
		{"name": "Ammo", "price": 100, "image": load("res://Assets/collecitions/Arrow/Arrow.png")},
		{"name": "Potion", "price": 50, "image": load("res://Assets/collecitions/Health/Cuore1.png")}
	]

	for data in items:
		var item = item_scene.instantiate()
		item.setup(data)
		item_container.add_child(item)

	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	get_tree().change_scene_to_file("res://Scenes/stage1.tscn")
