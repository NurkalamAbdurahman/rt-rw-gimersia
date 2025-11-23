extends CanvasLayer

signal qte_success
signal qte_failed

@onready var qte_container: Panel = $QTEContainer
@onready var target_box: ColorRect = $QTEContainer/TargetBox
@onready var hit_zone: ColorRect = $QTEContainer/HitZone
@onready var pedang: Sprite2D = $QTEContainer/Pedang

@onready var timer_label: Label = $TimerLabel
@onready var instruction_label: Label = $InstructionLabel
@onready var messege: Label = $messege

@export var target_speed: float = 300.0
@export var time_limit: float = 3.0

var qte_active: bool = false
var time_remaining: float = 0.0
var target_direction: int = 1
var can_input: bool = false

func _ready():
	add_to_group("QTE_System")
	hide_qte()

func _process(delta):
	if not qte_active:
		return

	time_remaining -= delta
	timer_label.text = "%.1fs" % time_remaining

	target_box.position.x += target_speed * target_direction * delta

	var container_width = qte_container.size.x
	var target_width = target_box.size.x

	if target_box.position.x <= 0:
		target_box.position.x = 0
		target_direction = 1
	elif target_box.position.x >= container_width - target_width:
		target_box.position.x = container_width - target_width
		target_direction = -1

	if time_remaining <= 0:
		end_qte(false)

func _input(event):
	if qte_active and can_input and event.is_action_pressed("attack"):
		check_hit()

func start_qte():
	qte_active = true
	can_input = true
	time_remaining = time_limit

	var container_width = qte_container.size.x
	var target_width = target_box.size.x

	target_direction = 1 if randf() > 0.5 else -1
	target_box.position.x = randf_range(0, container_width - target_width)

	show_qte()
	instruction_label.text = "Press space to attack\nwhen RED BOX hits the GREEN ZONE"

func check_hit():
	can_input = false

	var target_center = target_box.position.x + (target_box.size.x / 2)
	var zone_start = hit_zone.position.x
	var zone_end = zone_start + hit_zone.size.x

	var success = target_center >= zone_start and target_center <= zone_end
	end_qte(success)

func end_qte(success: bool):
	qte_active = false
	can_input = false

	messege.visible = true
	messege.modulate.a = 1.0

	var tween := create_tween()

	# ==============================
	# SUCCESS → ZOOM POP ANIMATION
	# ==============================
	if success:
		messege.text = "PERFECT HIT!"
		messege.modulate = Color.GREEN
		qte_success.emit()

		# Zoom pop
		messege.scale = Vector2(1, 1)
		tween.tween_property(messege, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK)
		tween.tween_property(messege, "scale", Vector2(1, 1), 0.15)

	# ==============================
	# FAIL → SCREEN SHAKE
	# ==============================
	else:
		messege.text = "MISS!"
		messege.modulate = Color.RED
		qte_failed.emit()

		# Shake kecil
		var original_pos = messege.position
		tween.tween_property(messege, "position", original_pos + Vector2(10, 0), 0.05)
		tween.tween_property(messege, "position", original_pos - Vector2(10, 0), 0.05)
		tween.tween_property(messege, "position", original_pos, 0.05)

	# ==============================
	# FADE OUT TIMER 0.5 DETIK
	# ==============================
	await get_tree().create_timer(0.4).timeout
	tween = create_tween()
	tween.tween_property(messege, "modulate:a", 0.0, 0.3)

	await tween.finished

	messege.visible = false
	hide_qte()

func show_qte():
	qte_container.visible = true
	timer_label.visible = true
	instruction_label.visible = true
	pedang.visible = true
	hit_zone.visible = true

func hide_qte():
	qte_container.visible = false
	timer_label.visible = false
	instruction_label.visible = false
	pedang.visible = false
	hit_zone.visible = false

func is_qte_active() -> bool:
	return qte_active
