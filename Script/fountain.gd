extends Area2D

var player_in_range = false
@onready var ui = get_tree().root.get_node("bonus_stage/ui_coin/coins_bonus") # sesuaikan path
@onready var sfx_trompet = get_tree().root.get_node("bonus_stage/sfx_trompet") # node AudioStreamPlayer

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		ui.show_message("Press E", 1.5)

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		ui.show_message("", 0.1)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interract"): # pastikan "interact" = E
		_throw_coin()

func _throw_coin():
	if GameData.coins <= 0:
		ui.show_fountain_message("You don't have any coins!", 2.0)
		return

	# Gunakan semua koin yang dimiliki player
	var coin_cost = GameData.coins
	GameData.coins -= coin_cost
	GameData.emit_signal("stats_updated")

	# Hasil hanya zonk
	ui.show_fountain_message("ZONK! You threw away all your coins...", 3.0)

	# Karena koin jadi 0, tampilkan event Tahun Baru
	if GameData.coins <= 0:
		_show_new_year_event()

func _show_new_year_event():
	ui.show_fountain_message("🎉 SELAMAT TAHUN BARU! 🎺", 4.0)
	if sfx_trompet:
		sfx_trompet.play()
