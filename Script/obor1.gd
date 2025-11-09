extends Node2D

@onready var obor_mati = $OborMati
@onready var obor_hidup = $OborHidup
@onready var area = $Area2D
@onready var label = $Label

var player_in_area = false

func _ready():
	obor_mati.visible = true
	obor_hidup.visible = false
	label.visible = false

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("e"):
		nyalakan_obor()

func nyalakan_obor():	
	obor_mati.visible = false
	obor_hidup.visible = true
	label.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and obor_mati.visible:
		player_in_area = true
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false
