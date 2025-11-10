extends Area2D

@export var coin_cost: int = 1
var player_in_range = false
@onready var ui = get_tree().root.get_node("bonus_stage/ui_coin/coins_bonus") # sesuaikan path dengan scene kamu

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		ui.show_message("Press E to throw a coin", 1.5)

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		ui.show_message("", 0.1)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interract"): # pastikan action "interact" = E
		_throw_coin()

func _throw_coin():
	# Cek apakah player punya cukup koin untuk dikurangi
	if GameData.coins < coin_cost:
		ui.show_fountain_message("Not enough coins to throw!", 2.0)
		return

	# Kurangi coin sesuai coin_cost
	GameData.coins -= coin_cost
	GameData.emit_signal("stats_updated")

	# Random reward
	var roll = randf()
	var message = ""

	if roll < 0.5:
		message = "ZONK! Nothing happened..."
	elif roll < 0.8:
		var bonus = randi_range(1, 100)
		GameData.add_coin(bonus)
		message = "Lucky! You found " + str(bonus) + " coins!"
	else:
		GameData.add_potion(1)
		message = "You received a potion!"

	# Tampilkan pesan di UI
	ui.show_fountain_message(message, 3.0)
