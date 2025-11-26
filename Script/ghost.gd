extends CharacterBody2D

@export var speed: float = 83.0
@export var chase_duration: float = 5.5
@export var start_delay: float = 3.0

var target: Node = null
var chasing := false
var waiting := false

@onready var chase_timer: Timer = $ChaseTimer
@onready var hit_area: Area2D = $HitArea
@onready var sfx_breath: AudioStreamPlayer = $SFX_Breath

signal chase_finished(success: bool)


func _ready():
	chase_timer.timeout.connect(_on_ChaseTimer_timeout)
	hit_area.body_entered.connect(_on_body_entered)


func start_chase(player):
	target = player
	waiting = true
	chasing = false

	# Ghost napas selama diam
	if sfx_breath:
		sfx_breath.play()

	# Diam sesaat
	await get_tree().create_timer(start_delay).timeout

	# Stop napas
	if sfx_breath:
		sfx_breath.stop()

	# Mulai kejar!
	waiting = false
	chasing = true
	chase_timer.start(chase_duration)


func _physics_process(delta):
	# Jika belum mulai atau tidak punya target → stop
	if not chasing or target == null:
		return

	# Gerakan mengejar pemain
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


func _on_body_entered(body):
	if body.is_in_group("player") and chasing:
		chasing = false
		get_tree().call_group("bonus_stage", "ghost_failed")
		emit_signal("chase_finished", false)
		queue_free()


func _on_ChaseTimer_timeout():
	chasing = false
	get_tree().call_group("bonus_stage", "ghost_success")
	emit_signal("chase_finished", true)
	queue_free()
