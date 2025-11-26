extends Area2D

signal step_completed(step_id)

@export var step_id: String = ""
@export var instruction_text: String = ""
@export var typing_speed: float = 0.05  # Kecepatan mengetik per karakter

@onready var player_2: CharacterBody2D = $"../Player2"
@onready var detection_area: CollisionShape2D = $DetectionArea
@onready var label: Label = $CanvasLayer/Label
@onready var sfx: AudioStreamPlayer2D = $SFX_Success
@onready var obor_26: Node2D = $"../SceneObor/Obor26"
@onready var goblin_6: CharacterBody2D = $"../Goblin6"
@onready var goblin_7: CharacterBody2D = $"../Goblin7"
@export var is_disable = false
@onready var barrier2: CollisionShape2D = $"../Barrier/Barrier2/CollisionShape2D"
@onready var barrier: CollisionShape2D = $"../Barrier/Barrier/CollisionShape2D"
@onready var barrier_collision: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision"
@onready var barrier_collision_2: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision2"
@onready var barrier_collision_3: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision3"
@onready var map_editor_layer: Control = $"../MapEditorLayer/MapEditorUI"
@onready var silver_chest_3: StaticBody2D = $"../Chest/SilverChest3"
@onready var barrier_collision_4: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision4"
@onready var barrier_collision_5: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision5"
@onready var hidden_to_maze_2: Node2D = $"../HiddenToMaze2"
@onready var barrier_collision_6: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision6"
@onready var barrier_22: CollisionShape2D = $"../Barrier/Barrier/CollisionShape2D2"
@onready var barrier_collision_7: CollisionShape2D = $"../Barrier/Barrier3/barrierCollision7"
@onready var sfx_finish: AudioStreamPlayer2D = $SFX_Finish

var is_active := false
var is_typing := false
var typing_tween: Tween

func _ready():
	detection_area.set_deferred("disabled", is_disable)
	label.visible = false
	label.text = ""

	# Connect semua seperti aslinya
	obor_26.connect("torch_lit", Callable(self, "_on_torch_lit"))
	goblin_6.connect("goblin_die", Callable(self, "_on_goblin_die"))
	goblin_6.connect("battle", Callable(self, "_on_battle"))
	map_editor_layer.connect("map_opened", Callable(self, "_on_map_opened"))
	silver_chest_3.connect("chest_has_opened", Callable(self, "_on_chest_opened"))
	goblin_7.connect("goblin_die", Callable(self, "_on_goblin_boss_die"))
	hidden_to_maze_2.connect("body_entered", Callable(self, "_on_body_player_entered"))
	GameData.connect("use_potion", Callable(self, "_on_use_potion"))

	# Step 8 disable detection area awal
	if step_id == "8":
		detection_area.set_deferred("disabled", true)

func _process(delta: float) -> void:
	# Step 3: buka map → area aktif
	if TutorialManager.current_step_index == 3 and step_id == "3":
		detection_area.set_deferred("disabled", false)

# ===============================
# TYPING ANIMATION
# ===============================

func start_typing_animation(text: String):
	if is_typing:
		stop_typing_animation()
	
	is_typing = true
	label.visible = true
	label.text = ""
	
	# Gunakan tween untuk animasi mengetik
	typing_tween = create_tween()
	
	for i in range(text.length() + 1):
		typing_tween.tween_callback(func(): 
			if is_typing:
				label.text = text.substr(0, i)
		)
		typing_tween.tween_interval(typing_speed)
	
	typing_tween.tween_callback(func(): is_typing = false)

func stop_typing_animation():
	if typing_tween:
		typing_tween.kill()
		typing_tween = null
	is_typing = false

# ===============================
# EVENT HANDLERS (DIPROTEKSI)
# ===============================

func _on_torch_lit():
	if step_id != "1": return
	barrier2.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_goblin_die():
	if step_id != "2": return
	barrier_collision.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_battle():
	if step_id != "2": return
	barrier_collision.set_deferred("disabled", false)
	barrier_collision_2.set_deferred("disabled", false)

func _on_map_opened():
	if step_id != "3": return
	barrier_collision_3.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_chest_opened():
	if step_id != "4": return
	barrier_collision_4.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_use_potion():
	if step_id != "5": return
	barrier_collision_6.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_body_player_entered():
	# Ini step 6
	if step_id != "6": return
	barrier_collision_5.set_deferred("disabled", true)
	if is_active:
		complete_step()

# BOSS GOBLIN (STEP 7)
func _on_goblin_boss_die():
	if step_id == "8": detection_area.set_deferred("disabled", false)
	barrier_collision_7.set_deferred("disabled", true)
	if is_active:
		sfx_finish.play()
		complete_step()

# ===============================
# AREA ENTER (AKTIVASI STEP)
# ===============================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	match step_id:
		"1":
			activate()

		"2":
			player_2.invincible_forever = true
			player_2.make_invincible()
			barrier2.set_deferred("disabled", false)
			activate()

		"3":
			barrier_collision.set_deferred("disabled", false)
			activate()

		"4":
			player_2.remove_invincible()
			barrier_collision_3.set_deferred("disabled", false)
			activate()

		"5":
			GameData.set_health(GameData.health - 1)
			barrier_collision_4.set_deferred("disabled", false)
			GameData.add_hp_potion(1)
			activate()

		"6":
			barrier_collision_6.set_deferred("disabled", false)
			activate()

		"7":
			player_2.invincible_forever = true
			player_2.make_invincible()
			barrier_collision_5.set_deferred("disabled", false)
			activate()

		"8":
			player_2.remove_invincible()
			PuzzleManager.reset_puzzle()
			barrier.set_deferred("disabled", false)
			barrier_22.set_deferred("disabled", false)
			activate()

func _on_body_exited(body: Node2D) -> void:
	await get_tree().create_timer(3).timeout
	stop_typing_animation()
	label.visible = false

# ===============================
# CORE FUNCTIONS
# ===============================

func activate():
	is_active = true
	start_typing_animation(instruction_text)

func complete_step():
	if not is_active:
		return

	is_active = false
	stop_typing_animation()
	label.visible = false
	sfx.play()
	emit_signal("step_completed", step_id)
	detection_area.set_deferred("disabled", true)
