extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked
@onready var hud: Label = $"../../Hud/Label"
@export var min_coin :int = 3
@export var max_coin :int = 10

@export var chest_id: String = "SceneA_Chest_1"
@export var puzzle_section: int = 0  # 0, 1, atau 2 untuk section

var player_in_area = false
var chest_opened = false
signal chest_has_opened

func _ready():
	if GameData.is_chest_opened(chest_id):
		print("Chest ", chest_id, " sudah dibuka sebelumnya. Menghapus...")
		queue_free()
		return
	
	tertutup.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false
	sfx_chest_open.stop()
	hud.visible = false
	hud.modulate.a = 0.0


func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			cek_buka_chest()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.text = "[E] OPEN"
		label.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false


func cek_buka_chest():
	if GameData.silver_keys > 0:
		GameData.silver_keys -= 1
		buka_chest()
	else:
		sfx_chest_locked.play()
		label.visible = true
		await get_tree().create_timer(1.3).timeout
		if player_in_area and not chest_opened:
			label.text = "[E] OPEN"
		else:
			label.visible = false


func buka_chest():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	anim_sprite.visible = true
	
	GameData.set_chest_opened(chest_id)
	
	# Mainkan animasi peti
	sfx_chest_open.play()
	anim_sprite.animation = "open"
	anim_sprite.play()
	await anim_sprite.animation_finished
	
	anim_sprite.visible = false
	terbuka.visible = true
	
	# === Tampilkan pattern section dulu ===
	await get_tree().create_timer(0.2).timeout
	show_pattern_section()
	emit_signal("chest_has_opened")


func show_pattern_section():
	# Tandai section sudah di-reveal
	PuzzleManager.reveal_section(puzzle_section)
	
	# Pause game
	get_tree().paused = true
	
	# Instance viewer pattern
	var PatternViewerScene = load("res://Scenes/pattern_viewer.tscn")
	var viewer = PatternViewerScene.instantiate()
	viewer.section_index = puzzle_section
	
	get_tree().root.add_child(viewer)
	viewer.viewer_closed.connect(_on_pattern_viewer_closed)
	
	print("=== SHOWING PATTERN SECTION ", puzzle_section, " ===")



func _on_pattern_viewer_closed():
	get_tree().paused = false
	print("=== PATTERN VIEWER CLOSED, GAME RESUMED ===")
	show_reward_smooth()


func show_reward_smooth():
	var reward = randi_range(min_coin, max_coin)
	GameData.add_coin(reward)
	
	hud.text = ""
	hud.visible = true
	
	# Mulai dari transparan
	hud.modulate = Color(hud.modulate.r, hud.modulate.g, hud.modulate.b, 0.0)
	
	# Tween untuk fade in/out
	var tween = create_tween()
	
	# Fade in
	tween.tween_property(hud, "modulate", Color(1, 1, 1, 1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Tahan 2 detik
	tween.tween_interval(2.0)
	
	# Fade out
	tween.tween_property(hud, "modulate", Color(1, 1, 1, 0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
