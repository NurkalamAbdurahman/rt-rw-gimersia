extends Node2D

@onready var tertutup: Sprite2D = $silver_chest
@onready var anim_sprite: AnimatedSprite2D = $silver_chest_openanimation
@onready var terbuka: Sprite2D = $silver_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@onready var hud: Label = $"../../Hud/Label"
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked

@export var chest_id: String = "SceneA_Chest_1"
@export var puzzle_section: int = 0  # 0, 1, or 2 for the three sections

var player_in_area = false
var chest_opened = false
var pityadd = 1

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
			label.text = "[E] Open"
		else:
			label.visible = false

func buka_chest():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	anim_sprite.visible = true
	
	GameData.set_chest_opened(chest_id)
	
	# Sound effect
	sfx_chest_open.play()
	
	# Mainkan animasi buka peti
	anim_sprite.animation = "open"
	anim_sprite.play()
	
	# Reward logic
	var reward = randi_range(3, 10)
	GameData.add_coin(reward)	
	await anim_sprite.animation_finished
	
	anim_sprite.visible = false
	terbuka.visible = true
	
	# Show reward message
	var message = "You gained %s coins!" % reward
		
	hud.text = message
	hud.visible = true
	hud.modulate.a = 1.0
	
	var wait_duration = 2.0
	
	await get_tree().create_timer(wait_duration).timeout
	hud.modulate.a = 0.0
	
	# === NEW: SHOW PATTERN SECTION ===
	await get_tree().create_timer(0.5).timeout  # Small delay
	show_pattern_section()

func show_pattern_section():
	# Mark this section as revealed in PuzzleManager
	PuzzleManager.reveal_section(puzzle_section)
	
	# Pause game and show pattern viewer
	get_tree().paused = true
	
	# Load and show pattern viewer
	var PatternViewerScript = load("res://Script/PatternViewer.gd")
	var viewer = CanvasLayer.new()
	viewer.set_script(PatternViewerScript)
	viewer.section_index = puzzle_section
	viewer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().root.add_child(viewer)
	viewer.viewer_closed.connect(_on_pattern_viewer_closed)
	
	print("=== SHOWING PATTERN SECTION ", puzzle_section, " ===")

func _on_pattern_viewer_closed():
	get_tree().paused = false
	print("=== PATTERN VIEWER CLOSED, GAME RESUMED ===")
