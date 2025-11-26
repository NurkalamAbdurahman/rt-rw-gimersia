extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked

# === Tambahan untuk trap ===
@onready var sfx_trap: AudioStreamPlayer2D = $SFX_Trap
@onready var screen_fade: ColorRect = $"../HUD/ScreenFade"

@export var chest_id: String = "SceneA_Chest_1"

var player_in_area = false
var chest_opened = false

func _ready():
	if GameData.is_chest_opened(chest_id):
		queue_free()
		return
	
	tertutup.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false
	
	# Pastikan layar fade transparan di awal
	if screen_fade:
		screen_fade.modulate.a = 0.0


func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			cek_buka_chest()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.text = "[E] OPEN??"
		label.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false


func cek_buka_chest():
	# === Beda dari chest normal: tidak butuh kunci ===
	buka_chest_trap()


# ============================================
#            TRAP CHEST FUNCTION
# ============================================

func buka_chest_trap():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	anim_sprite.visible = true
	
	# Mainkan animasi buka
	sfx_chest_open.play()
	anim_sprite.animation = "open"
	anim_sprite.play()
	await anim_sprite.animation_finished
	
	anim_sprite.visible = false
	terbuka.visible = true
	
	# === TRAP AKTIVATION ===
	play_trap_effect()

func play_trap_effect():
	# 1. Mainkan SFX jebakan
	sfx_trap.play()

	# 2. Flash kedap-kedip + screen shake
	if not screen_fade:
		return

	screen_fade.visible = true

	var tween = create_tween()

	# Pengaturan kedipan
	var speed := 0.08        # kecepatan satu kedipan
	var flashes := 5          # jumlah kedipan
	var flash_color := Color(1, 1, 1, 1)   # flash putih
	var clear_color := Color(1, 1, 1, 0)   # transparan

	# === SCREEN SHAKE ===
	var player_cam := get_tree().get_first_node_in_group("camera")
	if player_cam and player_cam is Camera2D:
		shake_camera(player_cam)

	# === FLASH LOOP ===
	for i in flashes:
		# Flash ON (putih)
		tween.tween_property(screen_fade, "modulate", flash_color, speed)
		# Flash OFF
		tween.tween_property(screen_fade, "modulate", clear_color, speed)

	# Setelah selesai flash
	tween.tween_callback(func():
		screen_fade.visible = false
		screen_fade.modulate = clear_color
	)

func shake_camera(cam: Camera2D):
	var tween = create_tween()

	# Kekuatan shake
	var intensity := 12
	var time := 0.25

	# Gerak acak kiri-kanan atas-bawah
	tween.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tween.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tween.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)

	# Kembalikan kamera ke posisi normal
	tween.tween_property(cam, "offset", Vector2(0, 0), 0.1)




	# 3. Simpan status chest sudah dibuka
	GameData.set_chest_opened(chest_id)

	# 4. (Opsional) efek lanjut seperti teleport, damage, dsb
	# tinggal tambah di sini
