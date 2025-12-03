extends Area2D

var player_in_range = false
var player_ref = null
var current_popup = null

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
	hide_interact_message()

	current_popup = confirm_popup_scene.instantiate()
	# beri nama supaya mudah dicari (opsional)
	current_popup.name = "confirm_popup"
	get_tree().current_scene.add_child(current_popup)
	current_popup.show_popup("Spend a coin to try your luck")

	current_popup.confirmed.connect(Callable(self, "_on_popup_confirmed"))
	current_popup.cancelled.connect(Callable(self, "_on_popup_cancelled"))
	current_popup.tree_exited.connect(Callable(self, "_on_popup_closed"))

func _on_popup_closed():
	# dipanggil bila popup di-queue_free() sendiri
	GameData.is_popup_open = false
	current_popup = null
	if player_in_range:
		show_interact_message()

func _on_popup_confirmed():
	# Jika koin habis, bunyi sfx tetapi popup tetap terbuka
	if GameData.coins <= 0:
		if sfx_buyNotEnough:
			sfx_buyNotEnough.play()
		return  # popup tetap aktif, player tetap freeze sesuai popup
	

	# Jika ada koin, lanjut lempar
	_throw_coin(GameData.coins)
	_close_popup()


func _on_popup_cancelled():
	if sfx_close:
		sfx_close.play()
	_close_popup()

func _close_popup():
	GameData.is_popup_open = false
	_freeze_player(false)

	if current_popup and current_popup.is_inside_tree():
		current_popup.queue_free()
	current_popup = null

	if player_in_range:
		show_interact_message()

func _freeze_player(freeze: bool):
	if not player_ref:
		return

	if freeze:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		# hati-hati kalau player_ref mungkin tidak punya velocity properti
		if "velocity" in player_ref:
			player_ref.velocity = Vector2.ZERO
	else:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)

# coin_cost default = 1
func _throw_coin(coin_cost: int = 1) -> void:
	# safety check
	if GameData.coins < coin_cost:
		if sfx_buyNotEnough:
			sfx_buyNotEnough.play()
		return

	# potong koin
	GameData.coins -= coin_cost
	GameData.emit_signal("stats_updated")

	# Mainkan animasi coin dan sfx splash
	if sfx_splash:
		coin.visible = true
		sfx_splash.play()
		animation_player.play("RESET")

	# Tampilkan pesan fountain pertama
	fountain_label.visible = true
	await get_tree().create_timer(2.0).timeout
	fountain_label.visible = false

	# Jika setelah bayar koin habis, tunjukkan event "new year" sekarang (sebelum zonk)
	var is_new_year = GameData.coins <= 0
	if is_new_year:
		await _show_new_year_event()

	# Tampilkan zonk label dan mainkan sfx terompet (zonk jadi yang terakhir)
	zonk_label.visible = true
	if sfx_trompet:
		sfx_trompet.play()
	await get_tree().create_timer(2.0).timeout
	zonk_label.visible = false

	# sembunyikan coin visual
	coin.visible = false

func _show_new_year_event() -> void:
	# Tampilkan pesan tahun baru di fountain_label selama 2 detik
	fountain_label.visible = true
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
