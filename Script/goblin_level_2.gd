extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var attack_area: Area2D = $AttackArea2D
@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Attacked
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var sfx_walk: AudioStreamPlayer2D = $SFX_Walk

# Raycasts untuk deteksi tembok
var wall_raycast: RayCast2D
var left_raycast: RayCast2D
var right_raycast: RayCast2D

# Speed settings
@export var patrol_speed = 30.0
@export var chase_speed = 90.0
@export var attack_speed = 30.0

# Area settings
@export var wander_range = 200.0
@export var detection_radius = 180.0
@export var attack_range = 50.0

# AI settings
@export var wall_check_distance = 30.0
@export var stuck_threshold = 5.0  # Jika gerak kurang dari ini, dianggap stuck

@export var enemy_id: String = "SceneA_Goblin_2"

@export var max_health = 10
@onready var hud: Label = $"../Hud/Label"
var is_dead = false
var skyes = 0

# State machine
enum State { IDLE, PATROL, CHASE, ATTACK, HURT }
var current_state = State.IDLE
var last_direction = Vector2.DOWN

# Timers
var idle_timer = 0.0
var patrol_timer = 0.0
var attack_cooldown = 0.0
var stuck_timer = 0.0

# Targets
var target_position = Vector2.ZERO
var player = null
var patrol_center = Vector2.ZERO
var last_position = Vector2.ZERO

func _ready():
	randomize()
	patrol_center = global_position
	last_position = global_position
	
	if GameData.is_enemy_killed(enemy_id):
		# Jika statusnya TRUE (sudah mati), hapus musuh
		print("Enemy ", enemy_id, " sudah dikalahkan sebelumnya. Menghapus...")
		queue_free()
		return # Keluar dari _ready agar tidak ada setup yang berjalan
		
	# Setup raycasts untuk deteksi tembok
	setup_raycasts()
	
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
	
	# SOLUSI: Tambahkan collision exception untuk player
	call_deferred("setup_player_exception")
	
	change_to_idle()

func setup_player_exception():
	# Cari player dan tambahkan sebagai exception
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if p is CharacterBody2D:
			add_collision_exception_with(p)  # Goblin tidak collision dengan player
			p.add_collision_exception_with(self)  # Player tidak collision dengan goblin
			print("Added collision exception with player")

func setup_raycasts():
	# Raycast depan
	wall_raycast = RayCast2D.new()
	wall_raycast.enabled = true
	wall_raycast.exclude_parent = true
	wall_raycast.target_position = Vector2(wall_check_distance, 0)
	wall_raycast.collision_mask = 1  # Layer 1 = environment/walls
	add_child(wall_raycast)
	
	# Raycast kiri
	left_raycast = RayCast2D.new()
	left_raycast.enabled = true
	left_raycast.exclude_parent = true
	left_raycast.target_position = Vector2(-wall_check_distance * 0.7, 0)
	left_raycast.collision_mask = 1
	add_child(left_raycast)
	
	# Raycast kanan
	right_raycast = RayCast2D.new()
	right_raycast.enabled = true
	right_raycast.exclude_parent = true
	right_raycast.target_position = Vector2(wall_check_distance * 0.7, 0)
	right_raycast.collision_mask = 1
	add_child(right_raycast)

func _physics_process(delta):
	# Update raycasts sesuai arah gerak
	update_raycasts()
	
	# Cek apakah stuck
	check_if_stuck(delta)
	
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

func update_raycasts():
	# Rotate raycast sesuai arah last_direction
	if last_direction.length() > 0.1:
		var angle = last_direction.angle()
		wall_raycast.target_position = Vector2(wall_check_distance, 0).rotated(angle)
		left_raycast.target_position = Vector2(-wall_check_distance * 0.7, 0).rotated(angle)
		right_raycast.target_position = Vector2(wall_check_distance * 0.7, 0).rotated(angle)

func check_if_stuck(delta):
	# Cek apakah posisi hampir tidak berubah
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < stuck_threshold:
		stuck_timer += delta
		
		# Kalau stuck lebih dari 1 detik, pick target baru
		if stuck_timer > 1.0:
			if current_state == State.PATROL:
				pick_patrol_target()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func is_wall_ahead() -> bool:
	# Cek apakah ada tembok di depan
	return wall_raycast.is_colliding()

func get_clear_direction() -> Vector2:
	# Cari arah yang tidak ada tembok
	var directions = [
		last_direction,  # Arah sekarang
		last_direction.rotated(PI / 4),  # 45 derajat kanan
		last_direction.rotated(-PI / 4),  # 45 derajat kiri
		last_direction.rotated(PI / 2),  # 90 derajat kanan
		last_direction.rotated(-PI / 2),  # 90 derajat kiri
		-last_direction  # Balik arah
	]
	
	for dir in directions:
		if is_direction_clear(dir):
			return dir
	
	# Kalau semua arah tertutup, pick random
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func is_direction_clear(direction: Vector2) -> bool:
	# Test raycast ke arah tertentu
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
	velocity = Vector2.ZERO
	idle_timer -= delta
	play_animation("idle")

	# 🔇 Matikan suara jalan
	if sfx_walk and sfx_walk.playing:
		sfx_walk.stop()
	
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
	
	if is_wall_ahead():
		last_direction = get_clear_direction()
		pick_patrol_target()
		return
	
	var direction = (target_position - global_position).normalized()
	if not is_direction_clear(direction):
		pick_patrol_target()
		return
	
	velocity = direction * patrol_speed
	last_direction = direction
	
	play_animation("walk")
	move_and_slide()

	# 🔊 Nyalakan suara jalan
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
		# Generate random target
		var random_offset = Vector2(
			randf_range(-wander_range, wander_range),
			randf_range(-wander_range, wander_range)
		)
		var potential_target = patrol_center + random_offset
		
		# Check if path is clear
		if is_direction_clear((potential_target - global_position).normalized()):
			target_position = potential_target
			valid_target = true
			break
	
	# Fallback: pick direction yang clear
	if not valid_target:
		var clear_dir = get_clear_direction()
		target_position = global_position + clear_dir * wander_range * 0.5

# ============ CHASE STATE ============
func handle_chase(delta):
	if not player or not is_instance_valid(player):
		change_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Too far, return to patrol
	if distance_to_player > detection_radius * 1.2:
		player = null
		change_to_idle()
		return
	
	# Close enough to attack
	if distance_to_player < attack_range:
		change_to_attack()
		return
	
	# Chase direction
	var direction = (player.global_position - global_position).normalized()
	
	# SMART CHASE: Kalau ada tembok di depan, cari jalan memutar
	if is_wall_ahead():
		
		# Coba kiri atau kanan
		if not left_raycast.is_colliding():
			direction = direction.rotated(-PI / 4)  # Belok kiri
		elif not right_raycast.is_colliding():
			direction = direction.rotated(PI / 4)  # Belok kanan
		else:
			# Kalau kiri kanan tertutup, cari arah clear
			direction = get_clear_direction()
	
	velocity = direction * chase_speed
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
	
	# Player moved away
	if distance_to_player > attack_range * 1.5:
		change_to_chase()
		return
	
	# Kalau terlalu dekat, mundur sedikit
	var too_close_distance = 20.0
	if distance_to_player < too_close_distance:
		var push_away = (global_position - player.global_position).normalized()
		velocity = push_away * attack_speed * 0.5
	else:
		# Move slowly towards player while attacking
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * attack_speed
	
	last_direction = (player.global_position - global_position).normalized()
	
	# Attack animation
	if attack_cooldown <= 0:
		play_animation("attack")
		attack_cooldown = 1.0
		perform_attack()
	else:
		play_animation("walk_attack")
		
	
	move_and_slide()

func change_to_attack():
	current_state = State.ATTACK
	attack_cooldown = 0.5

func perform_attack():

	if sfx_attack and not sfx_attack.playing:
		sfx_attack.play()

	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)

# ============ HURT STATE ============
func handle_hurt(delta):
	# Velocity di handle_hurt akan berkurang seiring waktu, mensimulasikan gesekan setelah knockback
	velocity = velocity * 0.9
	move_and_slide()

# ➡️ FUNGSI TAKE_DAMAGE DENGAN KNOCKBACK YANG DIPERBAIKI 💥
func take_damage(amount: int, damage_source_position: Vector2):
	if current_state == State.HURT or is_dead: # Tambah proteksi agar tidak double hit saat knockback
		return

	# Nonaktifkan serangan dan patrol saat terluka
	current_state = State.HURT

	if sfx_attacked and not sfx_attacked.playing:
		sfx_attacked.play()

	play_animation("hurt")
	max_health -= amount
	
	# 1. Hitung arah Knockback
	# Arah dari penyerang (damage_source_position) ke Goblin (global_position)
	var knockback_dir = (global_position - damage_source_position).normalized() 
	
	# 2. Terapkan Knockback Velocity
	velocity = knockback_dir * 250 # Kekuatan knockback
	
	# Cek kematian setelah damage diterima
	if max_health <= 0:
		die()
		return # Keluar jika mati
		
	move_and_slide()
	
	# 3. Tunggu durasi Knockback
	await get_tree().create_timer(0.3).timeout # Durasi Knockback (0.3 detik)
	
	# Reset velocity dan kembali ke state CHASE atau IDLE
	velocity = Vector2.ZERO
	
	# Jika masih ada pemain yang dikejar, kembali mengejar
	if player and is_instance_valid(player):
		change_to_chase()
	else:
		change_to_idle()
# ⬅️ AKHIR FUNGSI TAKE_DAMAGE YANG DIPERBAIKI

func die():
	is_dead = true
	velocity = Vector2.ZERO
	current_state = State.HURT

	if sfx_death:
		sfx_death.play()

	# --- PENTING: HENTIKAN INTERAKSI SEGERA! ---
	
	collision_layer = 0
	collision_mask = 0
	wall_raycast.enabled = false
	left_raycast.enabled = false
	right_raycast.enabled = false
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)
	
	# --- LOGIKA REWARD ---
	
	GameData.set_enemy_killed(enemy_id)
	print("Goblin died and saved persistence!")
	
	var reward_message = try_drop_item() # Panggil dan dapatkan pesan reward
	
	# --- ANIMASI KEMATIAN ---

	# Mainkan animasi death
	var death_anim_name = "death" + get_direction_suffix(last_direction)
	
	if animated_sprite.sprite_frames.has_animation(death_anim_name):
		animated_sprite.play(death_anim_name)
		await animated_sprite.animation_finished
	else:
		play_animation("hurt")
		await get_tree().create_timer(0.5).timeout
	
	# =======================================================
	# ➡️ PERBAIKAN UTAMA: HILANGKAN VISUAL MUSUH SEKARANG! 👻
	# =======================================================
	
	# Fade out musuh (membuatnya transparan/tidak terlihat)
	var visual_fade_tween = create_tween()
	visual_fade_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
	await visual_fade_tween.finished
	
	# --- TAMPIL PESAN DI HUD (Saat musuh sudah hilang) ---
	
	hud.text = reward_message
	hud.visible = true
	hud.modulate.a = 1.0
	
	var wait_duration = 2.0
	if reward_message.contains("Silver Key"):
		wait_duration = 3.0
	
	# Musuh sudah hilang dari sini, hanya notifikasi yang tampil
	await get_tree().create_timer(wait_duration).timeout
	
	# Sembunyikan labelnya
	hud.modulate.a = 0.0
	
	# --- PENGHAPUSAN AKHIR ---
	# Hapus goblin dari scene setelah notifikasi selesai
	queue_free()

func try_drop_item() -> String:
	var reward = randi_range(3, 8)
	GameData.add_coin(reward)
	
	# Pesan koin adalah pesan dasar
	var message = "You gained %s coins!" % reward
	
	var drop_chance = 1 # Ganti 1.0 menjadi 0.5 jika maksudmu 50%
	var got_key = false
	
	if randf() <= drop_chance:
		GameData.add_silver_key(skyes)
		got_key = true
		
	print("Enemy reward:", reward, " | Dropped Key:", "")
	
	# Jika dapat kunci, tambahkan pesan ke baris baru
	if got_key:
		message += "\nYou received 2 Silver Key!"
		
	return message # <-- Kembalikan pesan reward


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
	if body.is_in_group("Player"):
		print("Player detected!")
		player = body
		change_to_chase()

func _on_detection_body_exited(body):
	if body == player:
		if current_state == State.CHASE:
			player = null
			change_to_idle()
