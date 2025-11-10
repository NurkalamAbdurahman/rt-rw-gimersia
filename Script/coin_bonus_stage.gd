extends Control

@onready var coin_label = $coinLabel
@onready var message_label = $messageLable
@onready var fountain_label = $fountainMessage
@onready var zonk_label = $zonkMessage

func _ready():
	update_ui()
	GameData.stats_updated.connect(update_ui)
	GameData.add_coin(100)

func update_ui():
	coin_label.text = "Coins: " + str(GameData.coins)

func show_message(text: String, duration := 2.0):
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(duration).timeout
	message_label.visible = false
	
func show_fountain_message(text: String, duration := 2.0):
	fountain_label.text = text
	fountain_label.visible = true
	await get_tree().create_timer(duration).timeout
	fountain_label.visible = false

func show_zonk_label(text: String, duration := 4.0):
	zonk_label.text = text
	zonk_label.visible = true
	await get_tree().create_timer(duration).timeout
	zonk_label.visible = false
