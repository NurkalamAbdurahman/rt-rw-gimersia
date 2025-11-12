extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@export var chest_id: String = "SceneA_Chest_1" # Ganti ini di setiap instance chest!
@onready var hud: Label = $"../../Hud/Label"
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked

var player_in_area = false
var chest_opened = false
var pityadd = 1

# Chest.gd

func _ready():
	# --- PERIKSA PERSISTENCE DI _READY ---
	if GameData.is_chest_opened(chest_id):
		# Jika statusnya TRUE (sudah dibuka)
		print("Chest ", chest_id, " sudah dibuka sebelumnya. Menghapus...")
		queue_free() # Langsung hapus chest dari scene
		return # Keluar dari _ready
		
	# Jika statusnya FALSE (belum dibuka), inisialisasi normal:
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
	if GameData.silver_keys > 0:
		# Punya silver key ✅
		GameData.silver_keys -= 1
		buka_chest()
	else:
		# Tidak punya ❌ → munculkan warning
		sfx_chest_locked.play()
		label.text = "You need a Silver Key!"
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

	# --- SIMPAN STATUS PERSISTENCE SAAT DIBUKA ---
	GameData.set_chest_opened(chest_id)

	# 🔊 Sound effect
	sfx_chest_open.play()

	# Mainkan animasi buka peti
	anim_sprite.animation = "open"
	anim_sprite.play()

	# --- AWAL BAGIAN LOGIKA REWARD YANG DIUBAH ---
	var reward = randi_range(3, 10)
	GameData.add_coin(reward)
	GameData.add_pity(pityadd)
	
	# 1. Buat "flag" untuk menandai apakah kita dapat kunci
	var got_golden_key = false 
	if GameData.pity == GameData.max_pity:
		GameData.add_golden_key(pityadd)
		got_golden_key = true # <-- Set flag ini ke true!

	print("Chest reward:", reward, " | Got Golden Key:", got_golden_key)
	# --- AKHIR BAGIAN LOGIKA REWARD YANG DIUBAH ---

	await anim_sprite.animation_finished

	anim_sprite.visible = false
	terbuka.visible = true

	# --- AWAL BAGIAN TAMPIL PESAN YANG DIUBAH ---
	
	# 2. Buat pesan dasar (untuk koin)
	var message = "You gained %s coins!" % reward
	
	# 3. JIKA dapat kunci emas (flag-nya true), tambahkan pesan kedua
	if got_golden_key:
		# \n artinya "buat baris baru"
		message += "\nYou received a Golden Key!" 
		
	# 4. Atur teks label dengan pesan yang sudah kita buat
	hud.text = message
	
	# 5. Tampilkan labelnya
	hud.visible = true
	hud.modulate.a = 1.0

	# 6. Tentukan durasi tunggu (lebih lama jika ada 2 baris pesan)
	var wait_duration = 2.0 # Durasi normal
	if got_golden_key:
		wait_duration = 3.5 # Durasi lebih lama untuk 2 baris
	
	await get_tree().create_timer(wait_duration).timeout

	# 7. Sembunyikan lagi labelnya
	hud.modulate.a = 0.0
	# --- AKHIR BAGIAN TAMPIL PESAN YANG DIUBAH ---
