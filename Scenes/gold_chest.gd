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

var player_in_area = false
var chest_opened = false
var puzzle_active = false
var puzzle_completed = false

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
		
		# Jika puzzle belum selesai → buka puzzle
		if Input.is_action_just_pressed("e") and not puzzle_completed and not puzzle_active:
			open_puzzle()
		
		# Jika puzzle selesai → cek key
		elif Input.is_action_just_pressed("e") and puzzle_completed:
			if GameData.golden_keys > 0:
				buka_chest()
			else:
				label.text = "You need a Golden Key to open this chest"
				label.visible = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		var revealed = PuzzleManager.get_revealed_count()
		label.text = "[E] Solve Puzzle (%d/3 hints)" % revealed
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
	# 🎯 LOAD SCENE, BUKAN SCRIPT
	var PuzzleScene = load("res://Scenes/gold_chest_puzzle.tscn")
	var puzzle = PuzzleScene.instantiate()

	# Tambah ke root / ke canvas UI
	get_tree().root.add_child(puzzle)

	# Connect signals (asumsi GoldChestPuzzle.gd punya signal ini)
	puzzle.puzzle_solved.connect(_on_puzzle_solved)
	puzzle.puzzle_failed.connect(_on_puzzle_failed)

	print("=== PUZZLE ADDED TO TREE ===")

func _on_puzzle_solved():
	get_tree().paused = false
	puzzle_active = false
	
	puzzle_completed = true
	
	# Cek apakah player punya golden key
	if GameData.golden_keys > 0:
		buka_chest()
	else:
		# Kalau puzzle berhasil tapi belum punya key
		label.text = "You solved the puzzle!\nBut you need a Golden Key"
		label.visible = true


func _on_puzzle_failed():
	get_tree().paused = false
	puzzle_active = false
	
	if player_in_area and not chest_opened:
		var revealed = PuzzleManager.get_revealed_count()
		label.text = "[E] Solve Puzzle (%d/3 hints)" % revealed
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
	var reward = randi_range(50, 100)
	var skull_keys = randi_range(2, 3)
	
	GameData.add_coin(reward)
	GameData.add_skull_key(skull_keys)
	
	print("Golden Chest reward:", reward, "coins and", skull_keys, "skull keys")
	
	await anim_sprite.animation_finished
	
	anim_sprite.visible = false
	terbuka.visible = true
	
	# Show reward message
	var message = "You gained %s coins!" % reward
	message += "\nYou received %s Skull Keys!" % skull_keys
	
	hud.text = message
	hud.visible = true
	hud.modulate.a = 1.0
	
	await get_tree().create_timer(3.0).timeout
	hud.modulate.a = 0.0
