extends Node2D

@onready var terkunci : Sprite2D = $Terkunci
@onready var anim_sprite: AnimatedSprite2D = $open_animation
@onready var terbuka: Sprite2D = $Terbuka
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label

var player_in_area = false
var chest_opened = false

func _ready():
	label.visible = false

func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			buka_pintu()
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false
func buka_pintu():
	label.visible = false
	get_tree().change_scene_to_file("res://Scenes/stage1-example-enemy.tscn")
