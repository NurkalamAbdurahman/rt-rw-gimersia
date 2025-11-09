extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen  # 🔊 Tambahan

var player_in_area = false
var chest_opened = false

func _ready():
	tertutup.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false
	sfx_chest_open.stop()  # Pastikan tidak bunyi di awal
	
func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			buka_chest()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false

func buka_chest():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	anim_sprite.visible = true
	
	# 🔈 Putar suara chest open
	sfx_chest_open.play()

	# Mainkan animasi buka peti
	anim_sprite.animation = "open"
	anim_sprite.play()

	var reward = randi_range(1, 10)
	GameData.add_coin(reward)
	print("Chest reward:", reward)

	# Tunggu sampai animasi selesai
	await anim_sprite.animation_finished

	# Setelah animasi selesai, ganti ke sprite chest terbuka
	anim_sprite.visible = false
	terbuka.visible = true
