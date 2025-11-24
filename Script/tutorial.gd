extends Area2D

signal step_completed(step_id)

@export var step_id: String = ""
@export var instruction_text: String = ""

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

var is_active := false

func _ready():
	detection_area.set_deferred("disabled", is_disable)
	label.visible = false
	label.text = instruction_text
	obor_26.connect("torch_lit", Callable(self, "_on_torch_lit"))
	goblin_6.connect("goblin_die", Callable(self, "_on_goblin_die"))
	goblin_6.connect("battle", Callable(self, "_on_battle"))
	map_editor_layer.connect("map_opened", Callable(self, "_on_map_opened"))
	silver_chest_3.connect("chest_has_opened", Callable(self, "_on_chest_opened"))
	goblin_7.connect("goblin_die", Callable(self, "_on_goblin_boss_die"))
	hidden_to_maze_2.connect("body_entered", Callable(self, "_on_body_player_entered"))
	GameData.connect("use_potion", Callable(self, "_on_use_potion"))
	
	if step_id == "8":
		detection_area.set_deferred("disabled", true)

func _process(delta: float) -> void:
	if TutorialManager.current_step_index == 3:
		detection_area.set_deferred("disabled", false)
	
# Torch.gd
func _on_torch_lit():
	barrier2.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_goblin_die():
	barrier_collision.set_deferred("disabled", true)
	if is_active:
		complete_step()
		
func _on_battle():
	barrier_collision.set_deferred("disabled", false)
	barrier_collision_2.set_deferred("disabled", false)
	
func _on_map_opened():
	barrier_collision_3.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_chest_opened():
	barrier_collision_4.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_use_potion():
	barrier_collision_6.set_deferred("disabled", true)
	if is_active:
		complete_step()

func _on_goblin_boss_die():
	barrier_collision_7.set_deferred("disabled", true)
	
	if step_id == "8":
		detection_area.set_deferred("disabled", false)
	
	if is_active:
		complete_step()
		
func _on_body_player_entered():
	barrier_collision_5.set_deferred("disabled", true)
	if is_active:
		complete_step()

func activate():
	is_active = true
	label.visible = true

func complete_step():
	if not is_active:
		return

	is_active = false
	label.visible = false
	sfx.play()
	emit_signal("step_completed", step_id)
	detection_area.set_deferred("disabled", true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if step_id == "1":
			activate()
		elif step_id == "2":
			barrier2.set_deferred("disabled", false)
			activate()
		elif step_id == "3":
			barrier_collision.set_deferred("disabled", false)
			activate()
		elif step_id == "4":
			barrier_collision_3.set_deferred("disabled", false)
			activate()
		elif step_id == "5":
			barrier_collision_4.set_deferred("disabled", false)
			GameData.add_speed_potion(1)
			activate()
		elif step_id == "6":
			barrier_collision_6.set_deferred("disabled", false)
			activate()
		elif step_id == "7":
			barrier_collision_5.set_deferred("disabled", false)
			activate()
		elif step_id == "8":
			barrier.set_deferred("disabled", false)
			barrier_22.set_deferred("disabled", false)
			
