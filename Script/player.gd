extends CharacterBody2D

const SPEED = 100.0
@onready var map_editor_ui: Control = $"../MapEditorLayer/MapEditorUI"
@onready var you_dead_ui: CanvasLayer = get_tree().get_current_scene().get_node("YouDead")

# --- ONREADY VARIABLES ---
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_run: AudioStreamPlayer2D = $SFX_Run_Stone
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Attacked
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var qte_system: CanvasLayer = $"../QTE_System"

# QTE variables
var qte_damage_multiplier: float = 1.0
var qte_lock_position = Vector2.ZERO
var qte_engaged = false
var waiting_for_qte: bool = false
# Add with other QTE variables
var qte_attack_playing = false
var qte_attack_duration = 0.6  # Duration of attack animation

# --- STATE VARIABLES ---
var has_torch = false
var held_torch = null
var is_dead: bool = false	
var is_locked: bool = false

var last_direction: Vector2 = Vector2.DOWN
var current_anim_direction: String = "down" 

func _ready() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_torch_picked_up"))
	
	add_to_group("Player")
	
	if qte_system:
		qte_system.connect("qte_success", Callable(self, "_on_qte_success"))
		qte_system.connect("qte_failed", Callable(self, "_on_qte_failed"))
	
	if you_dead_ui:
		you_dead_ui.connect("respawn_pressed", Callable(self, "_on_respawn_selected"))

func _on_torch_picked_up(torch_node):
	if not has_torch:
		held_torch = torch_node
		has_torch = true
		held_torch.get_parent().remove_child(held_torch)
		add_child(held_torch)
		held_torch.position = Vector2(0, 10)

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_locked:
		enforce_qte_position()
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("left", "right")
	input_vector.y = Input.get_axis("up", "down")
	var normalized_input = input_vector.normalized()
	
	if normalized_input != Vector2.ZERO:
		velocity = normalized_input * SPEED
		last_direction = normalized_input
		
		if abs(last_direction.x) > abs(last_direction.y):
			current_anim_direction = "right"
		else:
			if last_direction.y < 0:
				current_anim_direction = "up"
			else:
				current_anim_direction = "down"
	else:
		velocity = Vector2.ZERO

	move_and_slide()
		
	update_animation(normalized_input)

	if input_vector.x != 0:
		player.flip_h = input_vector.x < 0
		
	if normalized_input.length() > 0:
		if not sfx_run.playing:
			sfx_run.play()
	else:
		if sfx_run.playing:
			sfx_run.stop()

# --- MOVEMENT CONTROL ---
func lock_movement(enemy_position: Vector2 = Vector2.ZERO):
	is_locked = true
	velocity = Vector2.ZERO
	qte_lock_position = global_position  # Save current position
	
	# Face towards enemy if position provided
	if enemy_position != Vector2.ZERO:
		face_towards_enemy(enemy_position)
	
	print("🔒 Player movement locked - facing enemy")

func engage_qte():
	waiting_for_qte = true
	qte_engaged = true
	print("🎯 Player QTE engaged - waiting for input...")

func enforce_qte_position():
	if is_locked and qte_lock_position != Vector2.ZERO:
		global_position = qte_lock_position

func unlock_movement():
	is_locked = false
	qte_lock_position = Vector2.ZERO  # Reset position tracking
	print("🔓 Player movement unlocked")

func face_towards_enemy(enemy_position: Vector2):
	var direction_to_enemy = (enemy_position - global_position).normalized()
	last_direction = direction_to_enemy
	
	# Update animation direction based on enemy position
	if abs(direction_to_enemy.x) > abs(direction_to_enemy.y):
		current_anim_direction = "right" if direction_to_enemy.x > 0 else "left"
	else:
		current_anim_direction = "down" if direction_to_enemy.y > 0 else "up"
	
	# Flip sprite if facing left
	player.flip_h = (current_anim_direction == "left")
	
	# Play facing animation
	play_facing_animation()

func play_facing_animation():
	var anim_name = "idle_%s" % current_anim_direction
	if player.sprite_frames.has_animation(anim_name):
		player.play(anim_name)
	else:
		# Fallback to regular idle animation
		player.play("idle_" + current_anim_direction)

func update_facing_during_qte(enemy_position: Vector2):
	if is_locked:
		face_towards_enemy(enemy_position)

# --- ANIMATION ---
func update_animation(input_vector: Vector2):
	# If playing QTE attack animation, don't override it
	if qte_attack_playing:
		return
	
	if is_locked:
		# During QTE, use facing animation instead of movement animation
		play_facing_animation()
		return

	var anim_prefix = ""
	
	if input_vector.length() == 0:
		anim_prefix = "idle"
	else:
		anim_prefix = "run"
		
	var anim_name = "%s_%s" % [anim_prefix, current_anim_direction]
	
	player.play(anim_name)

# --- QTE SYSTEM ---
func _on_qte_success():
	if not waiting_for_qte or not qte_engaged:
		return
		
	waiting_for_qte = false
	qte_engaged = false
	qte_damage_multiplier = 1.0
	print("✨ QTE SUCCESS! Critical Hit!")
	
	# Play attack animation
	play_qte_attack_animation()
	flash_green()
	
func play_qte_attack_animation():
	print("💥 Player playing attack animation!")
	qte_attack_playing = true
	
	# Play attack animation based on direction
	var attack_anim_name = "attack_" + current_anim_direction
	
	# Check if attack animation exists, fallback to regular attack animation
	if player.sprite_frames.has_animation(attack_anim_name):
		player.play(attack_anim_name)
	else:
		# Fallback to generic attack animation or use current animation
		print("⚠️ No attack animation found: ", attack_anim_name)
		player.play("attack")  # Try generic attack animation
	
	# Optional: Add visual effects for attack
	player.modulate = Color(1.2, 1.2, 1.0)  # Yellow-ish glow for success
	var tween = create_tween()
	tween.tween_property(player, "modulate", Color(1, 1, 1), 0.3)
	
	# Reset attack state after animation
	await get_tree().create_timer(qte_attack_duration).timeout
	qte_attack_playing = false

func _on_qte_failed():
	if not waiting_for_qte or not qte_engaged:
		return
		
	waiting_for_qte = false
	qte_engaged = false
	qte_damage_multiplier = 0.5
	print("❌ QTE FAILED! Player takes damage!")
	flash_red()
	#take_damage(1)

# --- DAMAGE SYSTEM ---
func take_damage(amount: int):
	print("🎯 Player take_damage called - dead:", is_dead)
	
	# Only check if dead - allow damage during QTE (when is_locked is true)
	if is_dead:
		print("🎯 Player damage blocked - already dead")
		return

	sfx_attacked.play()
	
	var new_health = GameData.health - amount
	GameData.set_health(new_health)
	print("🎯 Player health decreased to:", GameData.health)
	map_editor_ui.close()
	
	flash_red()

	if new_health <= 1:  # Changed to <= 0 for proper death
		die()

# --- DEATH SYSTEM ---
func die():
	if is_dead:
		return
		
	is_dead = true
	print("💀 Player died")

	is_locked = true
	velocity = Vector2.ZERO
	move_and_slide()

	if sfx_death:
		sfx_death.play()

	# Death animation based on direction
	var death_anim_name = ""
	match current_anim_direction:
		"up":
			death_anim_name = "death_up"
		"down":
			death_anim_name = "death_down"
		"left":
			death_anim_name = "death_left"
		"right":
			death_anim_name = "death_right"
		_:
			death_anim_name = "death_down"

	# Check if animation exists
	var frames = player.sprite_frames
	if frames.has_animation(death_anim_name):
		player.play(death_anim_name)
		await player.animation_finished
	else:
		print("⚠️ Tidak ada animasi", death_anim_name, "pakai default death_d. Menggunakan fallback timer.")
		player.play("death_d")
		await get_tree().create_timer(1.0).timeout 

	# Show "You Dead" UI
	if you_dead_ui:
		you_dead_ui.show_you_dead()

# --- RESPAWN SYSTEM ---
func _on_respawn_selected():
	print("⚡ Respawn pressed — respawn player!")
	GameData.reset()
	GameData.set_death(true)
	get_tree().reload_current_scene()

# --- VISUAL EFFECTS ---
func flash_green():
	$AnimatedSprite2D.modulate = Color(0.4, 1, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func flash_red():
	print("FLASH CALLED")
	$AnimatedSprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

# --- UI FUNCTIONS ---
func _on_Button_Map_pressed() -> void:
	pass # Replace with function body
