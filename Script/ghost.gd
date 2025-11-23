extends CharacterBody2D

@export var speed: float = 90.0
@export var chase_duration: float = 5.0

var target: Node = null
var chasing := false

@onready var chase_timer: Timer = $ChaseTimer
@onready var hit_area: Area2D = $HitArea

func _ready():
	chase_timer.timeout.connect(_on_ChaseTimer_timeout)
	hit_area.body_entered.connect(_on_body_entered)

func start_chase(player):
	target = player
	chasing = true
	chase_timer.start(chase_duration)
signal chase_finished(success: bool)

func _physics_process(delta):
	if not chasing or target == null:
		return

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player") and chasing:
		chasing = false
		get_tree().call_group("bonus_stage", "ghost_failed")
		queue_free()
		emit_signal("chase_finished", false)  # kalau gagal
		queue_free()

func _on_ChaseTimer_timeout():
	chasing = false
	get_tree().call_group("bonus_stage", "ghost_success")
	queue_free()
	emit_signal("chase_finished", true)
	queue_free()
