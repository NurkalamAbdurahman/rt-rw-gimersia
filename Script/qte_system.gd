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
@onready var qte_bgm: AudioStreamPlayer = $QteBgm

var target_speed: float = 300.0
@export var time_limit: float = 3.0

var qte_active: bool = false
var time_remaining: float = 0.0
var target_direction: int = 1
var can_input: bool = false

func _ready() -> void:
	add_to_group("QTE_System")
	_hide_all()

func _process(delta: float) -> void:
	if not qte_active:
		return
	
	_update_timer(delta)
	_move_target(delta)
	
	if time_remaining <= 0:
		_end_qte(false)

func _input(event: InputEvent) -> void:
	if qte_active and can_input and event.is_action_pressed("attack"):
		_check_hit()

func start_qte() -> void:
	qte_active = true
	can_input = true
	time_remaining = time_limit
	target_direction = 1 if randf() > 0.5 else -1
	
	_randomize_target_position()
	_show_all()
	
	instruction_label.text = "Press space to attack\nwhen RED BOX hits the GREEN ZONE"

func is_qte_active() -> bool:
	return qte_active

func _update_timer(delta: float) -> void:
	time_remaining -= delta
	timer_label.text = "%.1fs" % time_remaining

func _move_target(delta: float) -> void:
	target_box.position.x += target_speed * target_direction * delta
	print("speed = ", target_speed, " pos = ", target_box.position.x)

	var container_width := qte_container.size.x
	var target_width := target_box.size.x
	
	if target_box.position.x <= 0:
		target_box.position.x = 0
		target_direction = 1
	elif target_box.position.x >= container_width - target_width:
		target_box.position.x = container_width - target_width
		target_direction = -1

func _randomize_target_position() -> void:
	var container_width := qte_container.size.x
	var target_width := target_box.size.x
	target_box.position.x = randf_range(0, container_width - target_width)

func _check_hit() -> void:
	can_input = false
	
	var target_center := target_box.position.x + (target_box.size.x / 2)
	var zone_start := hit_zone.position.x
	var zone_end := zone_start + hit_zone.size.x
	var success := target_center >= zone_start and target_center <= zone_end
	
	_end_qte(success)

func _end_qte(success: bool) -> void:
	qte_active = false
	can_input = false
	
	_show_result(success)
	await _animate_result(success)
	await _fade_result()
	
	_hide_all()

func _show_result(success: bool) -> void:
	messege.visible = true
	messege.modulate.a = 1.0
	messege.scale = Vector2.ONE
	
	if success:
		messege.text = "PERFECT HIT!"
		messege.modulate = Color.GREEN
		qte_success.emit()
	else:
		messege.text = "MISS!"
		messege.modulate = Color.RED
		qte_failed.emit()

func _animate_result(success: bool) -> void:
	var tween := create_tween()
	
	if success:
		tween.tween_property(messege, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK)
		tween.tween_property(messege, "scale", Vector2.ONE, 0.15)
	else:
		var original_pos := messege.position
		tween.tween_property(messege, "position", original_pos + Vector2(10, 0), 0.05)
		tween.tween_property(messege, "position", original_pos - Vector2(10, 0), 0.05)
		tween.tween_property(messege, "position", original_pos, 0.05)
	
	await get_tree().create_timer(0.4).timeout

func _fade_result() -> void:
	var tween := create_tween()
	tween.tween_property(messege, "modulate:a", 0.0, 0.3)
	await tween.finished
	messege.visible = false

func _show_all() -> void:
	qte_container.visible = true
	timer_label.visible = true
	instruction_label.visible = true
	pedang.visible = true
	hit_zone.visible = true

func _hide_all() -> void:
	qte_container.visible = false
	timer_label.visible = false
	instruction_label.visible = false
	pedang.visible = false
	hit_zone.visible = false
