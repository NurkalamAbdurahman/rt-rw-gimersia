extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var qte_trigger_area: Area2D = $AttackArea2D
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Hurt
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var sfx_walk: AudioStreamPlayer2D = $SFX_Walk
@onready var hud: Label = $"../Hud/Label"
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX_Hurt
@onready var qte_system: CanvasLayer = $"../QTE_System"

# QTE variables
var is_qte_active = false
var qte_target_player = null
var qte_engagement_count = 0
var max_qte_engagements = 3  # Number of QTEs before cooldown
var qte_cooldown_timer = 0.0
var qte_cooldown_duration = 1.0  # Seconds between QTE sequences
# Add this with your other QTE variables
# Add with other QTE variables
var qte_start_position = Vector2.ZERO
var is_position_locked = false

# Add with other QTE variables
var qte_attack_playing = false
var qte_attack_timer = 0.0
var qte_attack_duration = 0.6  # Duration of attack animation
# Raycasts for wall detection
var wall_raycast: RayCast2D
var left_raycast: RayCast2D
var right_raycast: RayCast2D

# Speed settings
@export var patrol_speed = 30.0
@export var chase_speed = 80.0

# Area settings
@export var wander_range = 200.0
@export var detection_radius = 150.0
@export var qte_trigger_range = 60.0  # Range to trigger QTE

# AI settings
@export var wall_check_distance = 30.0
@export var stuck_threshold = 5.0

@export var enemy_id: String = "SceneA_Goblin_1"
@export var max_health = 5
@export var qte_damage = 1  # Damage per successful QTE

var is_dead = false
var skyes = 2
var is_invulnerable = false

# State machine - REMOVED ATTACK STATE
# Add to existing QTE variables
var qte_windup_timer = 0.0
var qte_windup_duration = 0.8  # Time to face each other before QTE starts

# Add this new state
enum State { IDLE, PATROL, CHASE, HURT, QTE_ENGAGE, QTE_WINDUP }
var current_state = State.IDLE
var last_direction = Vector2.DOWN

# Timers - REMOVED ATTACK COOLDOWN
var idle_timer = 0.0
var patrol_timer = 0.0
var stuck_timer = 0.0
var hurt_timer = 0.0
var invulnerability_timer = 0.0

# Targets
var target_position = Vector2.ZERO
var player = null
var patrol_center = Vector2.ZERO
var last_position = Vector2.ZERO

func _ready():
	randomize()
	add_to_group("Enemies")
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
	
	# Setup QTE trigger area (replaces attack area)
	if not qte_trigger_area:
		qte_trigger_area = Area2D.new()
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = qte_trigger_range
		collision.shape = circle
		qte_trigger_area.add_child(collision)
		add_child(qte_trigger_area)
	
	qte_trigger_area.body_entered.connect(_on_qte_trigger_body_entered)

func _on_qte_trigger_body_entered(body):
	if body.is_in_group("Player") and not is_dead and not is_qte_active and qte_cooldown_timer <= 0:
		player = body
		engage_qte(player)

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
	# 🔥 NEW: Enforce position lock in all QTE states
	if is_position_locked:
		enforce_qte_position()
	
	update_raycasts()
	check_if_stuck(delta)
	update_timers(delta)
	
	# State machine - NO KNOCKBACK HANDLING
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.PATROL:
			handle_patrol(delta)
		State.CHASE:
			handle_chase(delta)
		State.QTE_WINDUP:
			handle_qte_windup(delta)
		State.HURT:
			handle_hurt(delta)
		State.QTE_ENGAGE:
			handle_qte_engage(delta)

func update_timers(delta):
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and current_state == State.HURT:
			recover_from_hurt()
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		animated_sprite.modulate.a = 0.5 if int(invulnerability_timer * 20) % 2 == 0 else 1.0
		
		if invulnerability_timer <= 0:
			is_invulnerable = false
			animated_sprite.modulate.a = 1.0
	
	# QTE cooldown timer
	if qte_cooldown_timer > 0:
		qte_cooldown_timer -= delta

# ============ QTE SYSTEM ============
func engage_qte(player_target):
	if is_dead or is_qte_active or qte_cooldown_timer > 0:
		return
	
	current_state = State.QTE_WINDUP
	is_qte_active = true
	is_position_locked = true
	qte_target_player = player_target
	velocity = Vector2.ZERO
	
	# Save the enemy's position when QTE starts
	qte_start_position = global_position
	
	# Lock the player and make them face this enemy
	if player_target.has_method("lock_movement"):
		player_target.lock_movement(global_position)
	
	# 🔥 NEW: Notify player that QTE is starting
	if player_target.has_method("engage_qte"):
		player_target.engage_qte()
	
	# Face the player
	last_direction = (player_target.global_position - global_position).normalized()
	
	play_animation("idle")
	print("🎯 Enemy facing player before QTE...")
	
	# Start windup timer
	qte_windup_timer = qte_windup_duration

# Add this function to enforce position during QTE
func enforce_qte_position():
	if is_qte_active and qte_start_position != Vector2.ZERO:
		global_position = qte_start_position

func handle_qte_windup(delta):
	# 🔥 NEW: Keep enemy in position
	enforce_qte_position()
	
	# Keep facing the player during windup
	if qte_target_player and is_instance_valid(qte_target_player):
		last_direction = (qte_target_player.global_position - global_position).normalized()
		
		# Make player keep facing this enemy
		if qte_target_player.has_method("update_facing_during_qte"):
			qte_target_player.update_facing_during_qte(global_position)
	
	# Countdown windup timer
	qte_windup_timer -= delta
	
	# Optional: Play a special windup animation
	play_animation("idle")  # Or "prepare_attack" if you have it
	
	# Visual effect: pulsating glow during windup
	var pulse = sin(qte_windup_timer * 20) * 0.3 + 0.7
	animated_sprite.modulate = Color(1, pulse, pulse)
	
	if qte_windup_timer <= 0:
		# Reset visual effect
		animated_sprite.modulate = Color(1, 1, 1)
		start_qte_sequence()

func start_qte_sequence():
	current_state = State.QTE_ENGAGE
	print("⚡ QTE sequence starting!")
	
	# Start QTE system
	if qte_system and not qte_system.is_qte_active():
		qte_system.start_qte()
		qte_system.connect("qte_success", Callable(self, "_on_enemy_qte_success"))
		qte_system.connect("qte_failed", Callable(self, "_on_enemy_qte_failed"))
	
	play_animation("attack" + get_direction_suffix(last_direction))
func _on_enemy_qte_success():
	# Player succeeded QTE - enemy takes damage
	print("💥 QTE Success! Enemy takes damage!")
	take_damage(qte_damage, qte_target_player.global_position)
	
	# Check if enemy died from damage
	if is_dead:
		end_qte_engagement()
	else:
		prepare_next_qte_engagement()

func _on_enemy_qte_failed():
	# Player failed QTE - enemy attacks player
	print("❌ QTE Failed! Enemy attacks player!")
	
	# Set attack state and play attack animation
	qte_attack_playing = true
	play_qte_attack_animation()
	
	# Apply damage to player
	if qte_target_player and qte_target_player.has_method("take_damage"):
		qte_target_player.take_damage(qte_damage)
	
	# Wait for attack animation to complete before continuing
	await get_tree().create_timer(qte_attack_duration).timeout
	
	# Reset attack state
	qte_attack_playing = false
	
	# Increment engagement count
	qte_engagement_count += 1
	
	# Continue QTE engagements even on failure
	prepare_next_qte_engagement()

func play_qte_attack_animation():
	print("💥 Enemy playing attack animation!")
	play_animation("attack" + get_direction_suffix(last_direction))
	
	# Optional: Add visual effects for attack
	animated_sprite.modulate = Color(1.5, 1.5, 1.5)  # Bright flash
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.2)

func prepare_next_qte_engagement():
	# Reset attack state first
	reset_qte_attack_state()
	
	# Check if we should continue QTE engagements
	if is_dead:
		end_qte_engagement()
		return
	
	# Check if we've reached max engagements for this sequence
	if qte_engagement_count >= max_qte_engagements:
		print("⏳ QTE sequence completed, starting cooldown")
		qte_cooldown_timer = qte_cooldown_duration
		end_qte_engagement()
		return
	
	# Brief pause before next QTE
	get_tree().create_timer(0.8).timeout.connect(func():
		if not is_dead and player and is_instance_valid(player):
			# Re-engage QTE with same player
			var current_player = qte_target_player
			end_qte_engagement()  # Clean up current engagement
			engage_qte(current_player)  # Start new engagement
	)

func end_qte_engagement():
	is_qte_active = false
	is_position_locked = false
	qte_windup_timer = 0.0
	qte_start_position = Vector2.ZERO
	qte_attack_playing = false  # Reset attack state
	
	# Unlock the player
	if qte_target_player and qte_target_player.has_method("unlock_movement"):
		qte_target_player.unlock_movement()
	
	# Disconnect QTE signals
	if qte_system:
		if qte_system.is_connected("qte_success", Callable(self, "_on_enemy_qte_success")):
			qte_system.disconnect("qte_success", Callable(self, "_on_enemy_qte_success"))
		if qte_system.is_connected("qte_failed", Callable(self, "_on_enemy_qte_failed")):
			qte_system.disconnect("qte_failed", Callable(self, "_on_enemy_qte_failed"))
	
	# Reset QTE tracking
	qte_target_player = null
	qte_engagement_count = 0
	
	# Return to appropriate state
	if player and is_instance_valid(player) and not is_dead:
		change_to_chase()
	else:
		change_to_idle()

func handle_qte_engage(delta):
	# Keep enemy in position
	enforce_qte_position()
	
	# Complete stop during QTE
	velocity = Vector2.ZERO
	
	# Keep facing the player
	if player and is_instance_valid(player):
		last_direction = (player.global_position - global_position).normalized()
	
	# Only play attack animation if we're specifically in an attack state
	if qte_attack_playing:
		play_animation("attack" + get_direction_suffix(last_direction))
	else:
		# Default to idle or prepare animation during normal QTE
		play_animation("idle" + get_direction_suffix(last_direction))

func reset_qte_attack_state():
	qte_attack_playing = false
	animated_sprite.modulate = Color(1, 1, 1)

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
	velocity = velocity.lerp(Vector2.ZERO, 10 * delta)
	idle_timer -= delta
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
	
	# No traditional attack check - QTE is triggered by area instead
	
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

# ============ HURT STATE & DAMAGE SYSTEM ============
func handle_hurt(delta):
	# Smooth deceleration during hurt state
	velocity = velocity.lerp(Vector2.ZERO, 8 * delta)
	move_and_slide()

func take_damage(amount: int, damage_source_position: Vector2):
	print("🎯 Enemy taking damage: ", amount, " current health: ", max_health)
	
	if is_invulnerable or is_dead:
		print("🎯 Enemy damage blocked - invulnerable or dead")
		return

	# Enter hurt state
	current_state = State.HURT
	is_invulnerable = true
	invulnerability_timer = 0.5
	hurt_timer = 0.3

	sfx_hurt.play()
	play_animation("hurt")
	max_health -= amount
	
	print("🎯 Enemy health after damage: ", max_health)
	
	if max_health <= 0:
		print("🎯 Enemy should die now!")
		die()

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
	qte_trigger_area.set_deferred("monitoring", false)
	
	# If in QTE, end it immediately
	if is_qte_active:
		end_qte_engagement()
	
	GameData.set_enemy_killed(enemy_id)
	var reward_message = try_drop_item()
	
	# Death animation - use "died" prefix for animation names
	var death_anim_name = "died" + get_direction_suffix(last_direction)
	
	# Play death animation
	if animated_sprite.sprite_frames.has_animation(death_anim_name):
		animated_sprite.play(death_anim_name)
		await animated_sprite.animation_finished
	else:
		# Fallback to hurt animation if death animation not found
		print("⚠️ No death animation found: ", death_anim_name, " - using hurt animation")
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
	# Don't change animation if dead (except for death animations)
	if is_dead and not anim_type.begins_with("died") and not anim_type.begins_with("hurt"):
		return
	
	var direction_suffix = get_direction_suffix(last_direction)
	var anim_name = anim_type + direction_suffix
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		# Try fallback animations
		if anim_type.begins_with("attack"):
			anim_name = "attack" + direction_suffix
		elif anim_type.begins_with("died"):
			anim_name = "died" + direction_suffix
		elif anim_type == "hurt":
			anim_name = "hurt"
		else:
			anim_name = "idle" + direction_suffix
	
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
		if current_state != State.HURT and current_state != State.QTE_ENGAGE:
			change_to_chase()

func _on_detection_body_exited(body):
	if body == player and current_state == State.CHASE:
		player = null
		change_to_idle()
