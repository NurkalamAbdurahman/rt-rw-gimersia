extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var attack_area: Area2D = $AttackArea2D

# Speed settings
@export var patrol_speed = 30.0
@export var chase_speed = 80.0
@export var attack_speed = 20.0

# Area settings
@export var wander_range = 200.0
@export var detection_radius = 150.0
@export var attack_range = 40.0

# State machine
enum State { IDLE, PATROL, CHASE, ATTACK, HURT }
var current_state = State.IDLE
var last_direction = Vector2.DOWN

# Timers
var idle_timer = 0.0
var patrol_timer = 0.0
var attack_cooldown = 0.0

# Targets
var target_position = Vector2.ZERO
var player = null
var patrol_center = Vector2.ZERO

func _ready():
	randomize()
	patrol_center = global_position
	
	# Setup detection area
	if not detection_area:
		detection_area = Area2D.new()
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = detection_radius
		collision.shape = circle
		detection_area.add_child(collision)
		add_child(detection_area)
	
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	# Setup attack area
	if not attack_area:
		attack_area = Area2D.new()
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = attack_range
		collision.shape = circle
		attack_area.add_child(collision)
		add_child(attack_area)
	
	change_to_idle()

func _physics_process(delta):
	# Debug
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		print("Distance to player: ", dist, " | State: ", State.keys()[current_state])
	
	# Update cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# State machine
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.PATROL:
			handle_patrol(delta)
		State.CHASE:
			handle_chase(delta)
		State.ATTACK:
			handle_attack(delta)
		State.HURT:
			handle_hurt(delta)

# ============ IDLE STATE ============
func handle_idle(delta):
	velocity = Vector2.ZERO
	idle_timer -= delta
	
	play_animation("idle")
	
	# PERBAIKAN: Cek player setiap frame, bukan hanya saat timer habis
	if player and is_instance_valid(player):
		change_to_chase()
		return
	
	if idle_timer <= 0:
		change_to_patrol()

func change_to_idle():
	current_state = State.IDLE
	velocity = Vector2.ZERO
	idle_timer = randf_range(1.0, 3.0)

# ============ PATROL STATE ============
func handle_patrol(delta):
	patrol_timer -= delta
	
	var direction = (target_position - global_position).normalized()
	velocity = direction * patrol_speed
	last_direction = direction
	
	play_animation("walk")
	move_and_slide()
	
	# Reached target or timer expired
	if global_position.distance_to(target_position) < 10 or patrol_timer <= 0:
		change_to_idle()

func change_to_patrol():
	current_state = State.PATROL
	pick_patrol_target()
	patrol_timer = randf_range(2.0, 5.0)

func pick_patrol_target():
	# Patrol around center point
	var random_offset = Vector2(
		randf_range(-wander_range, wander_range),
		randf_range(-wander_range, wander_range)
	)
	target_position = patrol_center + random_offset

# ============ CHASE STATE ============
func handle_chase(delta):
	if not player or not is_instance_valid(player):
		print("Player lost in chase!")
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	print("Chasing! Distance: ", distance_to_player)
	
	# Too far, return to patrol
	if distance_to_player > detection_radius * 1.2:
		print("Player too far!")
		player = null
		change_to_idle()
		return
	
	# Close enough to attack
	if distance_to_player < attack_range:
		print("Attack range!")
		change_to_attack()
		return
	
	# Chase the player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	last_direction = direction
	
	print("Velocity: ", velocity)
	
	play_animation("run")
	move_and_slide()
	
	print("After move_and_slide, position: ", global_position)

func change_to_chase():
	current_state = State.CHASE

# ============ ATTACK STATE ============
func handle_attack(delta):
	if not player or not is_instance_valid(player):
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Player moved away
	if distance_to_player > attack_range * 1.5:
		change_to_chase()
		return
	
	# Move slowly towards player while attacking
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * attack_speed
	last_direction = direction
	
	# Attack animation
	if attack_cooldown <= 0:
		play_animation("attack")
		attack_cooldown = 1.0  # Attack every 1 second
		perform_attack()
	else:
		# Between attacks, use walk_attack animation
		play_animation("walk_attack")
	
	move_and_slide()

func change_to_attack():
	current_state = State.ATTACK
	attack_cooldown = 0.5  # First attack delay

func perform_attack():
	# Here you can add damage to player
	print("Goblin attacks!")
	
	# Check if player is in attack range
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(10)  # Deal 10 damage

# ============ HURT STATE ============
func handle_hurt(delta):
	# Play hurt animation once
	velocity = velocity * 0.9  # Slow down
	move_and_slide()

func take_damage(amount: int):
	if current_state == State.HURT:
		return
	
	current_state = State.HURT
	play_animation("hurt")
	
	# Knockback
	if player and is_instance_valid(player):
		var knockback_dir = (global_position - player.global_position).normalized()
		velocity = knockback_dir * 150
	
	# Return to chase after hurt animation
	await get_tree().create_timer(0.5).timeout
	if player and is_instance_valid(player):
		change_to_chase()
	else:
		change_to_idle()

# ============ ANIMATION HELPER ============
func play_animation(anim_type: String):
	var direction_suffix = get_direction_suffix(last_direction)
	var anim_name = anim_type + direction_suffix
	
	# Cek apakah animasi ada
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		print("WARNING: Animation not found: ", anim_name)
		return
	
	# Only play if different animation
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func get_direction_suffix(direction: Vector2) -> String:
	if direction.length() < 0.1:
		return "_down"  # Default
	
	if abs(direction.x) > abs(direction.y):
		return "_right" if direction.x > 0 else "_left"
	else:
		return "_down" if direction.y > 0 else "_up"

# ============ DETECTION ============
func _on_detection_body_entered(body):
	print("Body entered detection: ", body.name)
	print("Body groups: ", body.get_groups())  # Cek grup yang dimiliki
	
	if body.is_in_group("Player"):
		print("Player detected!")
		player = body
		change_to_chase()
		print("Changed to CHASE state")
	else:
		print("Body is NOT in Player group!")

func _on_detection_body_exited(body):
	if body == player:
		# Player left detection area
		if current_state == State.CHASE:
			player = null
			change_to_idle()
