extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@export var chest_id: String = "SceneAG_Chest_1" # Ganti ini di setiap instance chest!
@onready var hud: Label = $"../Hud/Label"

var player_in_area = false
var chest_opened = false
var skullkey = 1

func _ready():
	if GameData.is_chest_opened(chest_id):
		# Jika statusnya TRUE (sudah dibuka)
		print("Chest ", chest_id, " sudah dibuka sebelumnya. Menghapus...")
		queue_free() # Langsung hapus chest dari scene
		return # Keluar dari _ready
		
	tertutup.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false
	sfx_chest_open.stop()

func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			cek_buka_chest()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.text = "Press E to open"
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false

func cek_buka_chest():
	if GameData.golden_keys > 0:
		# Punya silver key ✅
		GameData.golden_keys -= 1
		buka_chest()
	else:
		# Tidak punya ❌ → munculkan warning
		label.text = "You need a Golden Key!"
		label.visible = true
		await get_tree().create_timer(1.3).timeout
		if player_in_area and not chest_opened:
			label.text = "Press E to open"
		else:
			label.visible = false

func buka_chest():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	anim_sprite.visible = true
	
	GameData.set_chest_opened(chest_id)

	
	# 🔊 Sound effect
	sfx_chest_open.play()

	# Mainkan animasi buka peti
	anim_sprite.animation = "open"
	anim_sprite.play()

	var reward = randi_range(15, 25)
	GameData.add_coin(reward)
	GameData.add_skull_key(skullkey) # <-- Dapat koin & kunci
	print("Chest reward:", reward)

	await anim_sprite.animation_finished

	anim_sprite.visible = false
	terbuka.visible = true

	# --- INI BAGIAN YANG DIUBAH ---

	# 1. Buat pesan untuk koin
	var message = "You gained %s coins!" % reward
	
	# 2. Tambahkan pesan untuk kunci di baris baru (\n)
	message += "\nYou received a Skull Key!"
	
	# 3. Atur teks label dengan pesan gabungan
	hud.text = message
	
	# 4. Pastikan label visible DAN buat tidak transparan (alpha = 1.0)
	hud.visible = true
	hud.modulate.a = 1.0

	# 5. Tunggu 3 detik (lebih lama sedikit agar 2 baris terbaca)
	await get_tree().create_timer(3.0).timeout

	# 6. Sembunyikan lagi labelnya
	hud.modulate.a = 0.0
