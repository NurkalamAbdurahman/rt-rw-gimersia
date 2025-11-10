extends Control

@onready var buy_button = $Panel/buy_button
@onready var close_button = $Panel/close_button

var potion_price = 10
var addition = 1

func _ready():
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))

func _on_buy_pressed():
	var ui = get_tree().root.get_node("bonus_stage/ui_coin/coins_bonus")
	if GameData.coins >= potion_price:
		GameData.coins -= potion_price 
		GameData.add_potion(addition)
		GameData.check_if_max_health()
		GameData.emit_signal("stats_updated") # beri tahu UI untuk update
		ui.show_message("You bought a potion!", 2.0)
	else:
		ui.show_message("Not enough gold!", 2.0)

func _on_close_pressed():
	queue_free()
