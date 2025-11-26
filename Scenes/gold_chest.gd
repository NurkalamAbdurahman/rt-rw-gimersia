extends Node2D
@onready var tertutup: Sprite2D = $gold_chest
@onready var anim_sprite: AnimatedSprite2D = $gold_chest_openanimation
@onready var terbuka: Sprite2D = $gold_chest_open
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_open: AudioStreamPlayer2D = $SFX_ChestOpen
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked
@onready var hud: Label = $"../Hud/Label"

@export var chest_id: String = "SceneAG_GoldChest_1"
@export var skyes :int = 1

var player_in_area = false
var chest_opened = false
var puzzle_active = false
var puzzle_completed = false

func _ready():
	if GameData.is_chest_opened(chest_id):
		print("Chest ", chest_id, " sudah dibuka sebelumnya. Menghapus...")
		queue_free()
		return
	
	# Check if puzzle was already solved for this chest
	puzzle_completed = PuzzleManager.is_chest_puzzle_solved(chest_id)
	
	tertutup.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false
	sfx_chest_open.stop()

func _process(_delta):
	if player_in_area and not chest_opened:
		
		if Input.is_action_just_pressed("e"):
			# If puzzle already solved
			if puzzle_completed:
				# Check if has key
				if GameData.golden_keys > 0:
					GameData.golden_keys -= skyes
					buka_chest()
				else:
					sfx_chest_locked.play()
					label.text = "Puzzle solved!"
					label.visible = true
			else:
				# Puzzle not solved yet, open puzzle
				if not puzzle_active:
					open_puzzle()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		
		# Update label based on puzzle status
		if puzzle_completed:
			if GameData.golden_keys > 0:
				label.text = "[E] Open Chest (1 Golden Key)"
			else:
				label.text = "[E] Need Golden Key"
		else:
			label.text = "[E] Solve Puzzle"
		
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false

func open_puzzle():
	print("=== OPENING GOLD CHEST PUZZLE ===")
	puzzle_active = true
	label.visible = false
	get_tree().paused = true
	GameData.is_popup_open = true
	
	# Load puzzle scene
	var PuzzleScene = load("res://Scenes/gold_chest_puzzle.tscn")
	var puzzle = PuzzleScene.instantiate()
	get_tree().root.add_child(puzzle)
	
	# Connect signals
	puzzle.puzzle_solved.connect(_on_puzzle_solved)
	puzzle.puzzle_failed.connect(_on_puzzle_failed)
	print("=== PUZZLE ADDED TO TREE ===")

func _on_puzzle_solved():
	get_tree().paused = false
	puzzle_active = false
	puzzle_completed = true
	GameData.is_popup_open = false
	
	# Mark puzzle as solved in PuzzleManager
	PuzzleManager.mark_chest_puzzle_solved(chest_id)
	
	print("Puzzle solved for chest: ", chest_id)
	
	# Check if player has golden key
	if GameData.golden_keys > 0:
		GameData.golden_keys -= skyes
		buka_chest()
	else:
		# Puzzle solved but no key
		sfx_chest_locked.play()
		label.text = "Puzzle solved!"
		label.visible = true
		
		# Auto update label after 3 seconds
		await get_tree().create_timer(3.0).timeout
		if player_in_area and not chest_opened:
			label.text = "[E] Need Golden Key"
			label.visible = true

func _on_puzzle_failed():
	get_tree().paused = false
	puzzle_active = false
	GameData.is_popup_open = false
	
	if player_in_area and not chest_opened:
		if puzzle_completed:
			label.text = "[E] Need Golden Key" if GameData.golden_keys == 0 else "[E] Open Chest (1 Golden Key)"
		else:
			label.text = "[E] Solve Puzzle"
		label.visible = true

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
	
	# Reward lebih besar untuk golden chest
	var reward = randi_range(15, 25)
	var skull_keys = skyes
	
	GameData.add_coin(reward)
	GameData.add_skull_key(skull_keys)
	
	print("Golden Chest reward:", reward, "coins and", skull_keys, "skull keys")
	
	await anim_sprite.animation_finished
	
	anim_sprite.visible = false
	terbuka.visible = true
	
	# Show reward message
	var message = ""
	message += ""
	
	hud.text = message
	hud.visible = true
	hud.modulate.a = 1.0
	
	await get_tree().create_timer(3.0).timeout
	hud.modulate.a = 0.0
