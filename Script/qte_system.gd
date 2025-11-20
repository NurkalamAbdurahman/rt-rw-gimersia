# QTE_AttackSystem.gd
# Attach this to a CanvasLayer node in your scene
extends CanvasLayer

signal qte_success
signal qte_failed

@onready var qte_container: Panel = $QTEContainer
@onready var target_box: ColorRect = $QTEContainer/TargetBox
@onready var hit_zone: ColorRect = $QTEContainer/HitZone
@onready var timer_label: Label = $TimerLabel
@onready var instruction_label: Label = $InstructionLabel

# Settings
@export var container_width: float = 400.0
@export var target_speed: float = 560.0
@export var time_limit: float = 3.0
@export var target_size: float = 30.0
@export var hit_zone_width: float = 60.0

# State
var qte_active: bool = false
var time_remaining: float = 0.0
var target_direction: int = 1
var can_input: bool = false

func _ready():
	add_to_group("QTE_System")  # Add this
	
	# Setup container
	qte_container.custom_minimum_size = Vector2(container_width, 100)
	qte_container.position = Vector2(
		get_viewport().size.x / 2 - container_width / 2,
		get_viewport().size.y / 2 - 50
	)
	
	# Setup target (kotak merah)
	target_box.custom_minimum_size = Vector2(target_size, target_size)
	target_box.color = Color.RED
	
	# Setup hit zone (zona tengah)
	hit_zone.custom_minimum_size = Vector2(hit_zone_width, 100)
	hit_zone.color = Color(0, 1, 0, 0.3)  # Green transparent
	hit_zone.position.x = container_width / 2 - hit_zone_width / 2
	
	hide_qte()

func _process(delta):
	if not qte_active:
		return
	
	# Update timer
	time_remaining -= delta
	timer_label.text = "%.1fs" % time_remaining
	
	# Move target kiri-kanan
	target_box.position.x += target_speed * target_direction * delta
	
	# Bounce di tepi
	if target_box.position.x <= 0:
		target_box.position.x = 0
		target_direction = 1
	elif target_box.position.x >= container_width - target_size:
		target_box.position.x = container_width - target_size
		target_direction = -1
	
	# Check timeout
	if time_remaining <= 0:
		end_qte(false)

func _input(event):
	if not qte_active or not can_input:
		return
	
	if event.is_action_pressed("attack"):
		check_hit()

func start_qte():
	qte_active = true
	can_input = true
	time_remaining = time_limit
	
	# Random starting position and direction
	target_direction = 1 if randf() > 0.5 else -1
	target_box.position.x = randf_range(0, container_width - target_size)
	target_box.position.y = (qte_container.custom_minimum_size.y - target_size) / 2
	
	show_qte()
	instruction_label.text = "Press ATTACK when RED BOX in GREEN ZONE!"

func check_hit():
	can_input = false
	
	# Check if target is in hit zone
	var target_center = target_box.position.x + target_size / 2
	var zone_start = hit_zone.position.x
	var zone_end = zone_start + hit_zone_width
	
	var success = target_center >= zone_start and target_center <= zone_end
	end_qte(success)

func end_qte(success: bool):
	qte_active = false
	can_input = false
	
	if success:
		instruction_label.text = "PERFECT HIT!"
		instruction_label.modulate = Color.GREEN
		print("🎯 QTE System: Emitting success signal")
		qte_success.emit()
	else:
		instruction_label.text = "MISS!"
		instruction_label.modulate = Color.RED
		print("🎯 QTE System: Emitting failed signal")
		qte_failed.emit()
	
	# Wait before hiding
	await get_tree().create_timer(0.5).timeout
	hide_qte()

func show_qte():
	qte_container.visible = true
	timer_label.visible = true
	instruction_label.visible = true
	instruction_label.modulate = Color.WHITE

func hide_qte():
	qte_container.visible = false
	timer_label.visible = false
	instruction_label.visible = false

func is_qte_active() -> bool:
	return qte_active
