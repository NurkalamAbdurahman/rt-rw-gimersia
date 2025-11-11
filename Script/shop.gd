extends CanvasLayer

@onready var buy_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/buy_button
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/close_button
@onready var sfx_buy_potion = get_tree().root.get_node("bonus_stage/sfx_buyPotion")
@onready var sfx_buy_not_enough = get_tree().root.get_node("bonus_stage/sfx_buyNotEnough")
@onready var sfx_close = get_tree().root.get_node("bonus_stage/sfx_close")

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
		GameData.emit_signal("stats_updated")
		ui.show_message("You bought a potion!", 2.0)
		if sfx_buy_potion:
			sfx_buy_potion.play()
	else:
		ui.show_message("Not enough gold!", 2.0)
		if sfx_buy_not_enough:
			sfx_buy_not_enough.play()

func _on_close_pressed():
	if sfx_close:
		sfx_close.play()
	queue_free()
