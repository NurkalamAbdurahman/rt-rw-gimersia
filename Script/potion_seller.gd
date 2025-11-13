extends Node2D

@onready var area = $Area2D
@onready var label = $Label
@onready var sfx_open_shop = $SFX_OpenShop 

var player_in_range = false
var shop_opened = false
var player_ref = null

func _ready():
	label.visible = false
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body
		if not shop_opened:
			label.visible = true
			label.text = "Press [E] to Buy Potion"

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		label.visible = false

func _process(delta):
	if player_in_range and not shop_opened and Input.is_action_just_pressed("interract"):
		open_shop()

func open_shop():
	GameData.is_popup_open = true
	if shop_opened:
		return

	var shop_ui = preload("res://Scenes/ui/shop.tscn").instantiate()
	get_tree().root.add_child(shop_ui)
	shop_opened = true
	label.visible = false
	print("Shop opened")

	# 🔊 Mainkan suara saat shop dibuka
	if sfx_open_shop:
		sfx_open_shop.play()

	# Pause gerakan player
	if player_ref and player_ref.has_method("set_process_input"):
		player_ref.set_process_input(false)
		player_ref.set_physics_process(false)

	# Unpause saat shop ditutup
	shop_ui.connect("tree_exited", Callable(self, "_on_shop_closed"))

func _on_shop_closed():
	GameData.is_popup_open = false
	print("Shop closed")
	shop_opened = false

	# Aktifkan kembali gerakan player
	if player_ref and player_ref.has_method("set_process_input"):
		player_ref.set_process_input(true)
		player_ref.set_physics_process(true)

	if player_in_range:
		label.visible = true
