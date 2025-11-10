extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen

var player_in_area = false
var chest_opened = false
var pityadd = 1

func _ready():
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
	
	# 🔊 Sound effect
	sfx_chest_open.play()

	# Mainkan animasi buka peti
	anim_sprite.animation = "open"
	anim_sprite.play()

	var reward = randi_range(3, 10)
	GameData.add_coin(reward)
	GameData.add_pity(pityadd)
	if GameData.pity == GameData.max_pity:
		GameData.add_golden_key(pityadd)
	print("Chest reward:", reward)

	await anim_sprite.animation_finished

	anim_sprite.visible = false
	terbuka.visible = true
