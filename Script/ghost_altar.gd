extends Node2D

@export var ghost_scene: PackedScene = preload("res://Scenes/Ghost.tscn")

var player_in_range = false
var ghost_active = false

func _ready():
	$Area2D.connect("body_entered", Callable(self, "_on_body_enter"))
	$Area2D.connect("body_exited", Callable(self, "_on_body_exit"))
	$Label.visible = false

func _on_body_enter(body):
	if body.is_in_group("player") and not ghost_active:
		player_in_range = true
		$Label.text = "Press [E] to start Ghost Chase!"
		$Label.visible = true

func _on_body_exit(body):
	if body.is_in_group("player"):
		player_in_range = false
		$Label.visible = false

func _process(delta):
	if player_in_range and not ghost_active and Input.is_action_just_pressed("interract"):
		start_ghost()

func start_ghost():
	var ghost = ghost_scene.instantiate()
	get_tree().root.add_child(ghost)

	var player = get_tree().get_first_node_in_group("player")
	ghost.global_position = global_position + Vector2(0, -16)
	ghost.start_chase(player)

	ghost.connect("chase_finished", Callable(self, "_on_chase_finished"))

	ghost_active = true
	$Label.visible = false

func _on_chase_finished(success: bool):
	print("Chase finished, removing altar…")
	queue_free()
