extends Area2D

var player_in_range = false
var player_ref = null

@onready var ui = get_tree().root.get_node("bonus_stage/ui_coin/coins_bonus")
@onready var sfx_trompet = get_tree().root.get_node("bonus_stage/sfx_trompet")
@onready var sfx_splash = get_tree().root.get_node("bonus_stage/sfx_waterSplash") # ← tambahkan node sound splash di scene kamu
@onready var confirm_popup_scene = preload("res://Scenes/confirm_popup.tscn")
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coin: Area2D = $Coin

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	coin.visible = false

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body
		ui.show_message("Press E")
		

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		ui.show_message("")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interract"):
		_show_confirm_popup()

func _show_confirm_popup():
	_freeze_player(true)
	
	var popup = confirm_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show_popup("Are you sure?")
	
	popup.confirmed.connect(_on_popup_confirmed)
	popup.cancelled.connect(_on_popup_cancelled)

func _on_popup_confirmed():
	_throw_coin() # ← langsung jalankan proses lempar koin
	_freeze_player(false)

func _on_popup_cancelled():
	ui.show_message("Cancelled.", 2.0)
	_freeze_player(false)

func _freeze_player(freeze: bool):
	if not player_ref:
		return
	
	if freeze:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		player_ref.velocity = Vector2.ZERO
	else:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)

func _throw_coin():
	if GameData.coins <= 0:
		ui.show_fountain_message("You don't have any coins!", 2.0)
		return
	
	var coin_cost = GameData.coins
	GameData.coins -= coin_cost
	GameData.emit_signal("stats_updated")

	# 1️⃣ Tampilkan pesan melempar koin
	ui.show_fountain_message("You threw a coin...", 2.0)

	# 2️⃣ Jalankan efek splash dan tunggu 5 detik
	if sfx_splash:
		coin.visible = true
		sfx_splash.play()
		animation_player.play("RESET")
	await get_tree().create_timer(4.0).timeout
	
	# 3️⃣ Setelah 5 detik, tampilkan pesan zonk
	ui.show_fountain_message("ZONK! You threw away all your coins...", 3.0)

	# 4️⃣ Jika koin habis, munculkan event
	if GameData.coins <= 0:
		_show_new_year_event()

func _show_new_year_event():
	ui.show_fountain_message("🎉 HOHOHOHO Bukan Tempat Sampah! 🎺", 4.0)
	if sfx_trompet:
		sfx_trompet.play()
