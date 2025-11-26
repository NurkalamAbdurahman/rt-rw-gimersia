extends Node2D

@onready var area = $Area2D
@onready var label = $Label
@onready var sfx_open_shop = $SFX_OpenShop 
@onready var player: AudioStreamPlayer2D = $"../Player/SFX_Run_Stone"

var player_in_range = false
var shop_opened = false
var player_ref = null
var interact_cooldown = false  # ✅ Cooldown untuk mencegah spam

# ✅ STATIC CHECK UNTUK MENCEK JIKA SHOP SUDAH ADA
static var current_shop_instance: CanvasLayer = null

func _ready():
	label.visible = false
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body
		# ✅ CEK JIKA SHOP SUDAH ADA DI SCENE
		if not shop_opened and current_shop_instance == null:
			label.visible = true
			label.text = "[E] Shop"

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		label.visible = false

func _process(delta):
	# ✅ TAMBAH PROTEKSI EXTRA: cek shop_opened, cooldown, DAN current_shop_instance
	if (player_in_range and not shop_opened and not interact_cooldown 
		and current_shop_instance == null and Input.is_action_just_pressed("interract")):
		_open_shop_with_protection()

func _open_shop_with_protection():
	# ✅ Aktifkan cooldown
	interact_cooldown = true
	
	# ✅ Cooldown timer untuk mencegah spam
	var cooldown_timer = get_tree().create_timer(0.5)
	cooldown_timer.timeout.connect(_reset_cooldown)
	
	open_shop()

func _reset_cooldown():
	interact_cooldown = false

func open_shop():
	# ✅ DOUBLE CHECK SEBELUM MEMBUKA SHOP
	if shop_opened or current_shop_instance != null:
		return
		
	GameData.is_popup_open = true
	player.stop()

	var shop_ui = preload("res://Scenes/ui/shop.tscn").instantiate()
	get_tree().root.add_child(shop_ui)
	
	# ✅ SET STATIC VARIABLE
	current_shop_instance = shop_ui
	
	shop_opened = true
	label.visible = false
	print("Shop opened")

	# 🔊 Mainkan suara saat shop dibuka
	if sfx_open_shop:
		sfx_open_shop.play()

	# ✅ PAUSE PLAYER DENGAN CARA YANG LEBIH AMAN
	_pause_player_movement()

	# Unpause saat shop ditutup
	shop_ui.connect("tree_exited", Callable(self, "_on_shop_closed"))

func _pause_player_movement():
	# ✅ Method yang lebih aman untuk menghentikan player
	if player_ref and player_ref.has_method("lock_movement"):
		player_ref.lock_movement()
		print("Player movement locked by shop")
	elif player_ref:
		# Fallback jika method lock_movement tidak ada
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		print("Player movement stopped by shop (fallback)")

func _resume_player_movement():
	# ✅ Method yang lebih aman untuk melanjutkan player
	if player_ref and player_ref.has_method("unlock_movement"):
		player_ref.unlock_movement()
		print("Player movement unlocked by shop")
	elif player_ref:
		# Fallback jika method unlock_movement tidak ada
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
		print("Player movement resumed by shop (fallback)")

func _on_shop_closed():
	GameData.is_popup_open = false
	print("Shop closed")
	shop_opened = false
	
	# ✅ RESET STATIC VARIABLE
	current_shop_instance = null

	# ✅ AKTIFKAN KEMBALI GERAKAN PLAYER DENGAN CARA YANG AMAN
	_resume_player_movement()

	if player_in_range:
		label.visible = true
