extends Control

@onready var message_label = $messageLable
@onready var fountain_label = $fountainMessage
@onready var zonk_label = $zonkMessagess

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
