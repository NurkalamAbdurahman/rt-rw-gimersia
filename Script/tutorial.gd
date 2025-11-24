extends Area2D

signal step_completed(step_id)

@export var step_id: String = ""
@export var instruction_text: String = ""

@onready var detection_area: CollisionShape2D = $DetectionArea
@onready var label: Label = $CanvasLayer/Label
@onready var sfx: AudioStreamPlayer2D = $SFX_Success
@onready var obor_26: Node2D = $"../SceneObor/Obor26"
@onready var border: StaticBody2D = $Border
@onready var goblin_6: CharacterBody2D = $"../Goblin6"
@export var is_disable = false

var is_active := false

func _ready():
	detection_area.set_deferred("disabled", is_disable)
	label.visible = false
	label.text = instruction_text
	obor_26.connect("torch_lit", Callable(self, "_on_torch_lit"))
	goblin_6.connect("goblin_die", Callable(self, "_on_goblin_die"))
	
		

func _process(delta: float) -> void:
	if TutorialManager.current_step_index == 3:
		detection_area.set_deferred("disabled", false)
	

# Torch.gd
func _on_torch_lit():
	if is_active:
		complete_step()

func _on_goblin_die():
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
	border.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		activate() # Replace with function body.
