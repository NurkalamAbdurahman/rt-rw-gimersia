extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var qte_trigger_area: Area2D = $AttackArea2D
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Hurt
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var sfx_walk: AudioStreamPlayer2D = $SFX_Walk
@onready var hud: Label = $"../Hud/Label"
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX_Hurt
@onready var qte_system: CanvasLayer = get_node_or_null("/root/Game/QTE_System")  # Adjust path to your scene structure
@onready var qte_bgm: AudioStreamPlayer = $QteBgm
@onready var player_2: AudioStreamPlayer2D = $"../Player2/BGM"

# QTE variables
var is_qte_active = false
var qte_target_player = null
var qte_engagement_count = 0
var max_qte_engagements = 3
var qte_cooldown_timer = 0.0
var qte_cooldown_duration = 1.0
var qte_start_position = Vector2.ZERO
var is_position_locked = false
var qte_windup_timer = 0.0
var qte_windup_duration = 0.8
var qte_attack_playing = false
var qte_attack_timer = 0.0
var qte_attack_duration = 0.6

# Export variables
@export var max_silver_keys_dropped = 3
@export var qte_speed = 300
@export var hb_size: float = 35
@export var patrol_speed = 30.0
@export var chase_speed = 80.0
@export var wander_range = 200.0
@export var detection_radius = 150.0
@export var qte_trigger_range = 60.0
@export var wall_check_distance = 30.0
@export var stuck_threshold = 5.0
@export var enemy_id: String = "SceneA_Goblin_1"
@export var max_health = 3
@export var min_coin = 1
@export var max_coin = 5
@export var level = 1
@export var qte_damage = 1
@export var skyes = 1

# State variables
var is_dead = false
var is_invulnerable = false
var current_health: int

# Raycasts
var wall_raycast: RayCast2D
var left_raycast: RayCast2D
var right_raycast: RayCast2D

# Signals
signal goblin_die
signal battle

# State machine
enum State { IDLE, PATROL, CHASE, HURT, QTE_ENGAGE, QTE_WINDUP }
var current_state = State.IDLE
var last_direction = Vector2.DOWN

# Timers
var idle_timer = 0.0
var patrol_timer = 0.0
var stuck_timer = 0.0
var hurt_timer = 0.0
var invulnerability_timer = 0.0
var interlude_timer = 0.0
var interlude_duration = 0.5

# Targets
var target_position = Vector2.ZERO
var player = null
var patrol_center = Vector2.ZERO
var last_position = Vector2.ZERO

# Movement smoothing
var movement_enabled = true
var physics_enabled = true

func _ready():
	randomize()
	add_to_group("Enemies")
	patrol_center = global_position
	last_position = global_position
	current_health = max_health
	
	if GameData.is_enemy_killed(enemy_id):
		print("Enemy ", enemy_id, " already defeated. Removing...")
		queue_free()
		return
	
	setup_raycasts()
	setup_areas()
	call_deferred("setup_player_exception")
	
	# Try to find QTE system if not already set
	if not qte_system:
		print("⚠️ QTE System not found with @onready, searching...")
		# Try different paths
		var possible_paths = [
			"/root/Game/QTE_System",
			"../QTE_System",
			"/root/QTE_System",
			"../../QTE_System"
		]
		
		for path in possible_paths:
			qte_system = get_node_or_null(path)
			if qte_system:
				print("✅ Found QTE System at:", path)
				break
		
		# Last resort: search for it
		if not qte_system:
			var qte_nodes = get_tree().get_nodes_in_group("QTE_System")
			if qte_nodes.size() > 0:
				qte_system = qte_nodes[0]
				print("✅ Found QTE System in group")
			else:
				print("❌ QTE System not found anywhere!")
	
	change_to_idle()

func setup_player_exception():
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if p is CharacterBody2D:
			add_collision_exception_with(p)
			p.add_collision_exception_with(self)

func setup_areas():
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
	print("🎯 QTE Trigger entered by: ", body.name)
	if body.is_in_group("Player") and not is_dead and not is_qte_active and qte_cooldown_timer <= 0 and movement_enabled:
		print("✅ QTE conditions met! Starting QTE...")
		if qte_bgm:
			qte_bgm.play()
		if player_2:
			player_2.stop()
		player = body
		engage_qte(player)
	else:
		print("❌ QTE blocked - Dead:", is_dead, " Active:", is_qte_active, " Cooldown:", qte_cooldown_timer, " Movement:", movement_enabled)

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
	update_timers(delta)
	
	# Enforce position lock during QTE but still process state machine
	if is_position_locked and qte_start_position != Vector2.ZERO:
		global_position = qte_start_position
		velocity = Vector2.ZERO
		# Don't return early - continue to state machine
	
	# Only skip raycasts and stuck checking if not moving
	if not is_position_locked:
		update_raycasts()
		check_if_stuck(delta)
	
	# State machine - ALWAYS process this
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
	# Hurt timer
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and current_state == State.HURT:
			recover_from_hurt()
	
	# Invulnerability timer with proper flashing
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		var flash_speed = 10.0  # Reduced from 20 to prevent seizure-inducing flashing
		animated_sprite.modulate.a = 0.5 if int(invulnerability_timer * flash_speed) % 2 == 0 else 1.0
		
		if invulnerability_timer <= 0:
			is_invulnerable = false
			animated_sprite.modulate = Color(1, 1, 1, 1)
	
	# QTE cooldown timer
	if qte_cooldown_timer > 0:
		qte_cooldown_timer -= delta
	
	# Interlude timer (between QTE engagements)
	if interlude_timer > 0:
		interlude_timer -= delta

# ============ QTE SYSTEM ============
func engage_qte(player_target):
	if is_dead or is_qte_active or qte_cooldown_timer > 0 or not movement_enabled:
		return
	
	# Configure QTE system
	qte_system.target_speed = qte_speed
	qte_system.hitbox_size = hb_size
	
	# Lock all movement and position
	current_state = State.QTE_WINDUP
	is_qte_active = true
	is_position_locked = true
	physics_enabled = false
	movement_enabled = false
	qte_target_player = player_target
	velocity = Vector2.ZERO
	
	# Save locked position
	qte_start_position = global_position
	
	# Lock the player
	if player_target.has_method("lock_movement"):
		player_target.lock_movement(global_position)
	
	if player_target.has_method("engage_qte"):
		player_target.engage_qte()
	
	# Face the player
	last_direction = (player_target.global_position - global_position).normalized()
	
	play_animation("idle")
	qte_windup_timer = qte_windup_duration
	emit_signal("battle")

func handle_qte_windup(delta):
	# Keep position absolutely locked
	if qte_start_position != Vector2.ZERO:
		global_position = qte_start_position
	velocity = Vector2.ZERO
	
	# Keep facing the player
	if qte_target_player and is_instance_valid(qte_target_player):
		last_direction = (qte_target_player.global_position - global_position).normalized()
		
		if qte_target_player.has_method("update_facing_during_qte"):
			qte_target_player.update_facing_during_qte(global_position)
	
	# Countdown
	qte_windup_timer -= delta
	
	# Debug output every 0.2 seconds
	if int(qte_windup_timer * 5) != int((qte_windup_timer + delta) * 5):
		print("⏱️ QTE Windup timer:", qte_windup_timer, " State:", State.keys()[current_state])
	
	# Visual feedback with smooth pulsing
	var pulse = (sin(qte_windup_timer * 8.0) * 0.15) + 0.85
	animated_sprite.modulate = Color(1, pulse, pulse, 1)
	
	play_animation("idle")
	
	if qte_windup_timer <= 0:
		print("✅ Windup complete! Starting QTE sequence...")
		animated_sprite.modulate = Color(1, 1, 1, 1)
		start_qte_sequence()

func start_qte_sequence():
	current_state = State.QTE_ENGAGE
	
	# Start QTE system
	if qte_system and not qte_system.is_qte_active():
		qte_system.start_qte()
		qte_system.connect("qte_success", Callable(self, "_on_enemy_qte_success"))
		qte_system.connect("qte_failed", Callable(self, "_on_enemy_qte_failed"))
	
	play_animation("attack" + get_direction_suffix(last_direction))

func _on_enemy_qte_success():
	print("💥 QTE Success! Enemy takes damage!")
	
	var final_damage = calculate_player_damage_to_enemy()
	print("🎯 Player deals damage: ", final_damage)
	take_damage(final_damage, qte_target_player.global_position if qte_target_player else global_position)
	
	if is_dead:
		end_qte_engagement()
	else:
		prepare_next_qte_engagement()

func calculate_player_damage_to_enemy() -> int:
	if not qte_target_player:
		return qte_damage
	
	var base_damage = 1
	
	# Check for strength buff
	if qte_target_player.has_method("has_strength_buff") and qte_target_player.has_strength_buff():
		print("💪 Strength buff active! Player damage doubled")
		return base_damage * 2
	elif qte_target_player.get("strength_buff_active"):
		print("💪 Strength buff active! Player damage doubled")
		return base_damage * 2
	
	return base_damage

func _on_enemy_qte_failed():
	print("❌ QTE Failed! Enemy attacks player!")
	
	qte_attack_playing = true
	play_qte_attack_animation()
	
	# Apply damage to player
	if qte_target_player and qte_target_player.has_method("take_damage"):
		qte_target_player.take_damage(qte_damage)
	
	# Wait for attack animation
	await get_tree().create_timer(qte_attack_duration).timeout
	
	qte_attack_playing = false
	qte_engagement_count += 1
	
	prepare_next_qte_engagement()

func play_qte_attack_animation():
	play_animation("attack" + get_direction_suffix(last_direction))
	
	# Smooth flash effect
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2)

func prepare_next_qte_engagement():
	reset_qte_attack_state()
	
	if is_dead:
		end_qte_engagement()
		return
	
	# Check engagement limit
	if qte_engagement_count >= max_qte_engagements:
		print("⏳ QTE sequence completed, starting cooldown")
		qte_cooldown_timer = qte_cooldown_duration
		end_qte_engagement()
		return
	
	# Start interlude period - goblin stays completely still
	interlude_timer = interlude_duration
	is_position_locked = true
	velocity = Vector2.ZERO
	play_animation("idle")
	
	# Wait for interlude to complete
	await get_tree().create_timer(interlude_duration).timeout
	
	if not is_dead and qte_target_player and is_instance_valid(qte_target_player):
		var current_player = qte_target_player
		end_qte_engagement()
		engage_qte(current_player)

func end_qte_engagement():
	is_qte_active = false
	is_position_locked = false
	physics_enabled = true
	movement_enabled = true
	qte_windup_timer = 0.0
	qte_start_position = Vector2.ZERO
	qte_attack_playing = false
	interlude_timer = 0.0
	
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
	# Absolute position lock
	if qte_start_position != Vector2.ZERO:
		global_position = qte_start_position
	velocity = Vector2.ZERO
	
	# Keep facing player
	if qte_target_player and is_instance_valid(qte_target_player):
		last_direction = (qte_target_player.global_position - global_position).normalized()
	
	# Animation based on state
	if qte_attack_playing:
		play_animation("attack" + get_direction_suffix(last_direction))
	else:
		play_animation("idle" + get_direction_suffix(last_direction))

func reset_qte_attack_state():
	qte_attack_playing = false
	animated_sprite.modulate = Color(1, 1, 1, 1)

func update_raycasts():
	if last_direction.length() > 0.1:
		var angle = last_direction.angle()
		wall_raycast.target_position = Vector2(wall_check_distance, 0).rotated(angle)
		left_raycast.target_position = Vector2(-wall_check_distance * 0.7, 0).rotated(angle)
		right_raycast.target_position = Vector2(wall_check_distance * 0.7, 0).rotated(angle)

func check_if_stuck(delta):
	if not movement_enabled or is_position_locked:
		return
	
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < stuck_threshold * delta:
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
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	
	velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
	idle_timer -= delta
	play_animation("idle")
	
	if sfx_walk and sfx_walk.playing:
		sfx_walk.stop()
	
	if player and is_instance_valid(player) and not is_qte_active:
		change_to_chase()
		return
	
	if idle_timer <= 0:
		change_to_patrol()

func change_to_idle():
	if is_qte_active:
		return
	current_state = State.IDLE
	idle_timer = randf_range(1.0, 3.0)
	velocity = Vector2.ZERO

# ============ PATROL STATE ============
func handle_patrol(delta):
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	
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
	velocity = velocity.lerp(target_velocity, 5.0 * delta)
	last_direction = direction
	
	play_animation("walk")
	move_and_slide()
	
	if sfx_walk and not sfx_walk.playing and not is_dead:
		sfx_walk.play()
	
	if is_dead and sfx_walk:
		sfx_walk.stop()
	
	if global_position.distance_to(target_position) < 10.0 or patrol_timer <= 0:
		change_to_idle()

func change_to_patrol():
	if is_qte_active:
		return
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
		var direction_to_target = (potential_target - global_position).normalized()
		
		if is_direction_clear(direction_to_target):
			target_position = potential_target
			valid_target = true
			break
	
	if not valid_target:
		var clear_dir = get_clear_direction()
		target_position = global_position + clear_dir * wander_range * 0.5

# ============ CHASE STATE ============
func handle_chase(delta):
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	
	if not player or not is_instance_valid(player):
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_radius * 1.2:
		player = null
		change_to_idle()
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	# Smart pathfinding
	if is_wall_ahead():
		if not left_raycast.is_colliding():
			direction = direction.rotated(-PI / 4)
		elif not right_raycast.is_colliding():
			direction = direction.rotated(PI / 4)
		else:
			direction = get_clear_direction()
	
	# Smooth acceleration
	var target_velocity = direction * chase_speed
	velocity = velocity.lerp(target_velocity, 8.0 * delta)
	last_direction = direction
	
	play_animation("run")
	move_and_slide()

func change_to_chase():
	if is_qte_active:
		return
	current_state = State.CHASE

# ============ HURT STATE & DAMAGE SYSTEM ============
func handle_hurt(delta):
	# Smooth deceleration during hurt
	velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
	
	if movement_enabled and not is_position_locked:
		move_and_slide()

func take_damage(amount: int, damage_source_position: Vector2):
	print("🎯 Enemy taking damage: ", amount, " current health: ", current_health)
	
	if is_invulnerable or is_dead:
		print("🛡️ Damage blocked - invulnerable or dead")
		return
	
	# Prevent multiple damage calls in same frame
	if hurt_timer > 0:
		return
	
	# Enter hurt state
	current_state = State.HURT
	is_invulnerable = true
	invulnerability_timer = 0.5
	hurt_timer = 0.3
	
	sfx_hurt.play()
	play_animation("hurt")
	current_health -= amount
	
	print("🎯 Enemy health after damage: ", current_health)
	
	if current_health <= 0:
		print("💀 Enemy should die now!")
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
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	current_state = State.HURT
	physics_enabled = false
	movement_enabled = false
	
	qte_bgm.stop()
	player_2.play()
	emit_signal("goblin_die")
	
	sfx_death.play()
	
	# Disable all interactions
	collision_layer = 0
	collision_mask = 0
	wall_raycast.enabled = false
	left_raycast.enabled = false
	right_raycast.enabled = false
	detection_area.set_deferred("monitoring", false)
	qte_trigger_area.set_deferred("monitoring", false)
	
	# End QTE if active
	if is_qte_active:
		end_qte_engagement()
	
	GameData.set_enemy_killed(enemy_id)
	var reward_message = try_drop_item()
	
	# Play death animation
	var death_anim_name = "died" + get_direction_suffix(last_direction)
	
	if animated_sprite.sprite_frames.has_animation(death_anim_name):
		animated_sprite.play(death_anim_name)
		await animated_sprite.animation_finished
	else:
		print("⚠️ No death animation: ", death_anim_name)
		play_animation("hurt")
		await get_tree().create_timer(0.5).timeout
	
	# Smooth fade out
	var visual_fade_tween = create_tween()
	visual_fade_tween.set_ease(Tween.EASE_IN)
	visual_fade_tween.set_trans(Tween.TRANS_CUBIC)
	visual_fade_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	await visual_fade_tween.finished
	
	# Show reward message
	if hud:
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
	var reward = randi_range(min_coin, max_coin)
	GameData.add_coin(reward)
	
	var message = ""
	var drop_chance := 1.0
	
	if randf() <= drop_chance:
		match level:
			1:
				if GameData.has_method("get_silver_key_drop_count"):
					if GameData.get_silver_key_drop_count() < max_silver_keys_dropped:
						GameData.add_silver_key(skyes)
						GameData.increment_silver_key_drop_count(skyes)
						message += ""
					else:
						print("🔒 Silver key drop limit reached")
				else:
					GameData.add_silver_key(skyes)
					message += ""
			2:
				GameData.add_golden_key(skyes)
				message += ""
			_:
				pass
	
	return message

# ============ ANIMATION HELPER ============
func play_animation(anim_type: String):
	if is_dead and not anim_type.begins_with("died") and not anim_type.begins_with("hurt"):
		return
	
	var direction_suffix = get_direction_suffix(last_direction)
	var anim_name = anim_type + direction_suffix
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
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
	if body.is_in_group("Player") and not is_dead and movement_enabled:
		player = body
		if current_state != State.HURT and current_state != State.QTE_ENGAGE and current_state != State.QTE_WINDUP:
			change_to_chase()

func _on_detection_body_exited(body):
	if body == player and current_state == State.CHASE:
		player = null
		change_to_idle()
