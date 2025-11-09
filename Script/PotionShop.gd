extends Control

var potion_price = 10
@onready var buy_button = $Panel/buy_button
@onready var close_button = $Panel/close_button

func _ready():
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))

func _on_buy_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Player not found in group 'player'!")
		return

	if player.gold >= potion_price:
		player.gold -= potion_price
		player.potions += 1
		print("You bought a potion! Total:", player.potions)
	else:
		print("Not enough gold!")

func _on_close_pressed():
	queue_free()
