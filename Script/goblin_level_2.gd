extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var attack_area: Area2D = $AttackArea2D
@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Hurt8
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var sfx_walk: AudioStreamPlayer2D = $SFX_Walk
@onready var hud: Label = $"../Hud/Label"
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX_Hurt

# Raycasts for wall detection
var wall_raycast: RayCast2D
var left_raycast: RayCast2D
var right_raycast: RayCast2D

# Speed settings
@export var patrol_speed = 30.0
@export var chase_speed = 80.0
@export var attack_speed = 30.0

# Area settings
@export var wander_range = 200.0
@export var detection_radius = 150.0
@export var attack_range = 40.0

# AI settings
@export var wall_check_distance = 30.0
@export var stuck_threshold = 5.0
@export var knockback_strength = 300.0
@export var knockback_duration = 0.4

@export var enemy_id: String = "SceneA_Goblin_1"
@export var max_health = 5
@export var attack_damage = 1
@export var attack_cooldown_time = 1.2

var is_dead = false
var skyes = 2
var is_invulnerable = false  # NEW: Invulnerability frames

# State machine
enum State { IDLE, PATROL, CHASE, ATTACK, HURT }
var current_state = State.IDLE
var last_direction = Vector2.DOWN

# Timers
var idle_timer = 0.0
var patrol_timer = 0.0
var attack_cooldown = 0.0
var stuck_timer = 0.0
var hurt_timer = 0.0  # NEW: Track hurt state duration
var invulnerability_timer = 0.0  # NEW: I-frames timer

# Targets
var target_position = Vector2.ZERO
var player = null
var patrol_center = Vector2.ZERO
var last_position = Vector2.ZERO

# Smooth movement
var knockback_velocity = Vector2.ZERO  # NEW: Separate knockback tracking
var is_being_knocked_back = false

func _ready():
	randomize()
	patrol_center = global_position
	last_position = global_position
	
	if GameData.is_enemy_killed(enemy_id):
		print("Enemy ", enemy_id, " already defeated. Removing...")
		queue_free()
		return
		
	setup_raycasts()
	setup_areas()
	
	call_deferred("setup_player_exception")
	change_to_idle()

func setup_player_exception():
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if p is CharacterBody2D:
			add_collision_exception_with(p)
			p.add_collision_exception_with(self)

func setup_areas():
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

func setup_raycasts():
	wall_raycast = RayCast2D.new()
	wall_raycast.enabled = true
	wall_raycast.exclude_parent = true
	wall_raycast.target_position = Vector2(wall_check_distance, 0)
	wall_raycast.collision_mask = 1
	add_child(wall_raycast)
	
	left_raycast = RayCast2D.new()
	left_raycast.enabled = true
	left_raycast.exclude_parent = true
	left_raycast.target_position = Vector2(-wall_check_distance * 0.7, 0)
	left_raycast.collision_mask = 1
	add_child(left_raycast)
	
	right_raycast = RayCast2D.new()
	right_raycast.enabled = true
	right_raycast.exclude_parent = true
	right_raycast.target_position = Vector2(wall_check_distance * 0.7, 0)
	right_raycast.collision_mask = 1
	add_child(right_raycast)

func _physics_process(delta):
	update_raycasts()
	check_if_stuck(delta)
	update_timers(delta)
	
	# Handle knockback separately for smoother effect
	if is_being_knocked_back:
		apply_knockback(delta)
		return
	
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

func update_timers(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and current_state == State.HURT:
			recover_from_hurt()
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		# Flash effect during invulnerability
		animated_sprite.modulate.a = 0.5 if int(invulnerability_timer * 20) % 2 == 0 else 1.0
		
		if invulnerability_timer <= 0:
			is_invulnerable = false
			animated_sprite.modulate.a = 1.0

func update_raycasts():
	if last_direction.length() > 0.1:
		var angle = last_direction.angle()
		wall_raycast.target_position = Vector2(wall_check_distance, 0).rotated(angle)
		left_raycast.target_position = Vector2(-wall_check_distance * 0.7, 0).rotated(angle)
		right_raycast.target_position = Vector2(wall_check_distance * 0.7, 0).rotated(angle)

func check_if_stuck(delta):
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < stuck_threshold:
		stuck_timer += delta
		if stuck_timer > 1.0:
			if current_state == State.PATROL:
				pick_patrol_target()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func is_wall_ahead() -> bool:
	return wall_raycast.is_colliding()

func get_clear_direction() -> Vector2:
	var directions = [
		last_direction,
		last_direction.rotated(PI / 4),
		last_direction.rotated(-PI / 4),
		last_direction.rotated(PI / 2),
		last_direction.rotated(-PI / 2),
		-last_direction
	]
	
	for dir in directions:
		if is_direction_clear(dir):
			return dir
	
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func is_direction_clear(direction: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * wall_check_distance
	)
	query.exclude = [self]
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

# ============ IDLE STATE ============
func handle_idle(delta):
	velocity = velocity.lerp(Vector2.ZERO, 10 * delta)  # Smooth deceleration
	idle_timer -= delta  # BUG FIX: Was missing timer countdown!
	play_animation("idle")

	if sfx_walk and sfx_walk.playing:
		sfx_walk.stop()
	
	if player and is_instance_valid(player):
		change_to_chase()
		return
	
	if idle_timer <= 0:
		change_to_patrol()

func change_to_idle():
	current_state = State.IDLE
	idle_timer = randf_range(1.0, 3.0)

# ============ PATROL STATE ============
func handle_patrol(delta):
	patrol_timer -= delta
	
	if is_wall_ahead():
		last_direction = get_clear_direction()
		pick_patrol_target()
		return
	
	var direction = (target_position - global_position).normalized()
	if not is_direction_clear(direction):
		pick_patrol_target()
		return
	
	# Smooth acceleration
	var target_velocity = direction * patrol_speed
	velocity = velocity.lerp(target_velocity, 5 * delta)
	last_direction = direction
	
	play_animation("walk")
	move_and_slide()

	if sfx_walk and not sfx_walk.playing:
		sfx_walk.play()
	
	if global_position.distance_to(target_position) < 10 or patrol_timer <= 0:
		change_to_idle()

func change_to_patrol():
	current_state = State.PATROL
	pick_patrol_target()
	patrol_timer = randf_range(2.0, 5.0)

func pick_patrol_target():
	var max_attempts = 10
	var valid_target = false
	
	for i in range(max_attempts):
		var random_offset = Vector2(
			randf_range(-wander_range, wander_range),
			randf_range(-wander_range, wander_range)
		)
		var potential_target = patrol_center + random_offset
		
		if is_direction_clear((potential_target - global_position).normalized()):
			target_position = potential_target
			valid_target = true
			break
	
	if not valid_target:
		var clear_dir = get_clear_direction()
		target_position = global_position + clear_dir * wander_range * 0.5

# ============ CHASE STATE ============
func handle_chase(delta):
	if not player or not is_instance_valid(player):
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_radius * 1.2:
		player = null
		change_to_idle()
		return
	
	if distance_to_player < attack_range:
		change_to_attack()
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	# Smart pathfinding around walls
	if is_wall_ahead():
		if not left_raycast.is_colliding():
			direction = direction.rotated(-PI / 4)
		elif not right_raycast.is_colliding():
			direction = direction.rotated(PI / 4)
		else:
			direction = get_clear_direction()
	
	# Smooth acceleration for chase
	var target_velocity = direction * chase_speed
	velocity = velocity.lerp(target_velocity, 8 * delta)
	last_direction = direction
	
	play_animation("run")
	move_and_slide()

func change_to_chase():
	current_state = State.CHASE

# ============ ATTACK STATE ============
func handle_attack(delta):
	if not player or not is_instance_valid(player):
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_range * 1.5:
		change_to_chase()
		return
	
	# Smooth positioning during attack
	var too_close_distance = 25.0
	var ideal_distance = 35.0
	var target_velocity = Vector2.ZERO
	
	if distance_to_player < too_close_distance:
		var push_away = (global_position - player.global_position).normalized()
		target_velocity = push_away * attack_speed
	elif distance_to_player > ideal_distance:
		var direction = (player.global_position - global_position).normalized()
		target_velocity = direction * attack_speed
	
	velocity = velocity.lerp(target_velocity, 5 * delta)
	last_direction = (player.global_position - global_position).normalized()
	
	# Attack with cooldown
	if attack_cooldown <= 0:
		play_animation("attack")
		attack_cooldown = attack_cooldown_time
		perform_attack()
	else:
		play_animation("walk_attack")
	
	move_and_slide()

func change_to_attack():
	current_state = State.ATTACK
	attack_cooldown = 0.3  # Small initial delay

func perform_attack():
	if sfx_attack and not sfx_attack.playing:
		sfx_attack.play()

	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player") and body.has_method("take_damage"):
			# Check if player is in front of the enemy
			if is_target_in_front(body):
				body.take_damage(attack_damage, global_position)

func is_target_in_front(target: Node2D) -> bool:
	# Get direction to target
	var direction_to_target = (target.global_position - global_position).normalized()
	
	# Get the enemy's facing direction
	var facing_direction = last_direction.normalized()
	
	# Calculate dot product (1 = same direction, -1 = opposite, 0 = perpendicular)
	var dot = direction_to_target.dot(facing_direction)
	
	# Target is "in front" if dot > 0.5 (roughly 60 degree cone in front)
	# Adjust this value: 0.7 = narrower cone (~45°), 0.3 = wider cone (~90°)
	return dot > 0.5

# ============ HURT STATE & DAMAGE SYSTEM ============
func handle_hurt(delta):
	# Smooth deceleration during hurt state
	velocity = velocity.lerp(Vector2.ZERO, 8 * delta)
	move_and_slide()

func take_damage(amount: int, damage_source_position: Vector2):
	if is_invulnerable or is_dead:
		return

	# Enter hurt state
	current_state = State.HURT
	is_invulnerable = true
	invulnerability_timer = 0.5
	hurt_timer = knockback_duration


	sfx_hurt.play()

	play_animation("hurt")
	max_health -= amount
	
	# Calculate smooth knockback
	var knockback_dir = (global_position - damage_source_position).normalized()
	knockback_velocity = knockback_dir * knockback_strength
	is_being_knocked_back = true
	
	# Stop after knockback duration
	get_tree().create_timer(knockback_duration).timeout.connect(func():
		is_being_knocked_back = false
		knockback_velocity = Vector2.ZERO
	)
	
	if max_health <= 0:
		die()

func apply_knockback(delta):
	# Smooth knockback deceleration
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 6 * delta)
	velocity = knockback_velocity
	move_and_slide()

func recover_from_hurt():
	if is_dead:
		return
		
	if player and is_instance_valid(player):
		change_to_chase()
	else:
		change_to_idle()

# ============ DEATH ============
func die():
	is_dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	is_being_knocked_back = false
	current_state = State.HURT

	if sfx_death:
		sfx_death.play()

	# Disable all interactions immediately
	collision_layer = 0
	collision_mask = 0
	wall_raycast.enabled = false
	left_raycast.enabled = false
	right_raycast.enabled = false
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)
	
	GameData.set_enemy_killed(enemy_id)
	var reward_message = try_drop_item()
	
	# Death animation - use "died" prefix for animation names
	var death_anim_name = "died" + get_direction_suffix(last_direction)
	
	if animated_sprite.sprite_frames.has_animation(death_anim_name):
		animated_sprite.play(death_anim_name)
		await animated_sprite.animation_finished
	else:
		# Fallback to hurt animation if death animation not found
		play_animation("hurt")
		await get_tree().create_timer(0.5).timeout
	
	# Smooth fade out
	var visual_fade_tween = create_tween()
	visual_fade_tween.set_ease(Tween.EASE_IN)
	visual_fade_tween.set_trans(Tween.TRANS_CUBIC)
	visual_fade_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	await visual_fade_tween.finished
	
	# Show reward message
	hud.text = reward_message
	hud.visible = true
	hud.modulate.a = 1.0
	
	var wait_duration = 2.5 if reward_message.contains("Silver Key") else 2.0
	await get_tree().create_timer(wait_duration).timeout
	
	# Fade out HUD
	var hud_tween = create_tween()
	hud_tween.tween_property(hud, "modulate:a", 0.0, 0.3)
	await hud_tween.finished
	
	queue_free()

func try_drop_item() -> String:
	var reward = randi_range(3, 8)
	GameData.add_coin(reward)
	
	var message = "You gained %s coins!" % reward
	var drop_chance = 1.0
	
	if randf() <= drop_chance:
		GameData.add_silver_key(skyes)
		message += "\nYou received 2 Silver Key!"
	
	return message

# ============ ANIMATION HELPER ============
func play_animation(anim_type: String):
	var direction_suffix = get_direction_suffix(last_direction)
	var anim_name = anim_type + direction_suffix
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func get_direction_suffix(direction: Vector2) -> String:
	if direction.length() < 0.1:
		return "_down"
	
	if abs(direction.x) > abs(direction.y):
		return "_right" if direction.x > 0 else "_left"
	else:
		return "_down" if direction.y > 0 else "_up"

# ============ DETECTION ============
func _on_detection_body_entered(body):
	if body.is_in_group("Player") and not is_dead:
		player = body
		if current_state != State.HURT:
			change_to_chase()

func _on_detection_body_exited(body):
	if body == player and current_state == State.CHASE:
		player = null
		change_to_idle()
