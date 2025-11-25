extends Area2D
var player_in_range = false
var player_ref = null
@onready var sfx_trompet = get_tree().root.get_node("bonus_stage/sfx_trompet")
@onready var sfx_splash = get_tree().root.get_node("bonus_stage/sfx_waterSplash")
@onready var sfx_close = get_tree().root.get_node("bonus_stage/sfx_close")
@onready var sfx_buyNotEnough = get_tree().root.get_node("bonus_stage/sfx_buyNotEnough")
@onready var confirm_popup_scene = preload("res://Scenes/confirm_popup.tscn")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coin: Area2D = $Coin
# Local label references
@onready var interact_label: Label = $messege_label
@onready var zonk_label: Label = $zonkMessage
@onready var fountain_label: Label = $fountainMessage2

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	coin.visible = false
	
	# Pastikan semua label disembunyikan saat start
	hide_all_messages()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body
		show_interact_message()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		hide_interact_message()

func _process(_delta):
	if player_in_range and not GameData.is_popup_open and Input.is_action_just_pressed("interract"):
		_show_confirm_popup()

func _show_confirm_popup():
	GameData.is_popup_open = true
	_freeze_player(true)
	
	var popup = confirm_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show_popup("Spend a coin to try your luck")
	
	popup.confirmed.connect(_on_popup_confirmed)
	popup.cancelled.connect(_on_popup_cancelled)
	popup.tree_exited.connect(_on_popup_closed)

func _on_popup_closed():
	GameData.is_popup_open = false
	# Setelah popup ditutup, tampilkan kembali pesan interaksi jika player masih di area
	if player_in_range:
		show_interact_message()

func _on_popup_confirmed():
	_throw_coin()
	_freeze_player(false)
	GameData.is_popup_open = false

func _on_popup_cancelled():
	if sfx_close:
		sfx_close.play()
	_freeze_player(false)
	GameData.is_popup_open = false

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
	# Cek jika koin habis
	if GameData.coins <= 0:
		if sfx_buyNotEnough:
			sfx_buyNotEnough.play()
		return
	
	# Lanjutkan jika ada koin
	var coin_cost = GameData.coins
	GameData.coins -= coin_cost
	GameData.emit_signal("stats_updated")
	
	# Mainkan animasi coin dan sfx splash
	if sfx_splash:
		coin.visible = true
		sfx_splash.play()
		animation_player.play("RESET")
	
	# Tampilkan pesan di fountain_label
	fountain_label.visible = true
	
	# Tampilkan fountain label selama 2 detik
	await get_tree().create_timer(2.0).timeout
	
	# Sembunyikan fountain label
	fountain_label.visible = false
	
	# Tampilkan zonk label dan mainkan sfx terompet
	zonk_label.visible = true
	if sfx_trompet:
		sfx_trompet.play()
	
	await get_tree().create_timer(2.0).timeout
	zonk_label.visible = false
	
	# Tampilkan pesan tahun baru jika koin habis
	if GameData.coins <= 0:
		_show_new_year_event()

func _show_new_year_event():
	# Tampilkan pesan tahun baru di fountain_label
	fountain_label.visible = true
	
	# Tunggu sebentar lalu sembunyikan
	await get_tree().create_timer(2.0).timeout
	fountain_label.visible = false

# Local message functions
func show_interact_message():
	interact_label.visible = true

func hide_interact_message():
	interact_label.visible = false

func hide_all_messages():
	interact_label.visible = false
	fountain_label.visible = false
	zonk_label.visible = false
