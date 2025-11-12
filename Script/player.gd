extends CharacterBody2D

const SPEED = 130.0
const ATTACK_DURATION = 0.25
const ATTACK_OFFSET = 20.0
@onready var map_editor_ui: Control = $MapEditorLayer/MapEditorUI

# --- ONREADY VARIAN ---
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_run: AudioStreamPlayer2D = $SFX_Run_Stone
@onready var attack_area: Area2D = $AttackArea2D
@onready var attack_shape: CollisionShape2D = $AttackArea2D/CollisionShape2D
@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Attacked
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death

# --- VARIABEL STATE ---
var invincible := false
var invincible_time := 0.4
var has_torch = false
var held_torch = null

var is_locked: bool = false

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var current_anim_direction: String = "down" 

# --- FUNGSI INIT ---
func _ready() -> void:
	attack_shape.disabled = true
	
	# PENTING: Tambahkan player ke group "Player"
	add_to_group("Player")
	
	# Debug: print untuk cek apakah attack_area ada
	if attack_area:
		print("✅ AttackArea2D found!")
	else:
		print("❌ AttackArea2D NOT FOUND!")

# --- FUNGSI FISIKA & INPUT ---
func _physics_process(delta):
	if GameData.health <= 1:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO)
		return
	
	var input_vector = Vector2.ZERO
	
	if is_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
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

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
		
	update_animation(normalized_input)

	if input_vector.x != 0:
		player.flip_h = input_vector.x < 0
		
	if normalized_input.length() > 0 and not is_attacking:
		if not sfx_run.playing:
			sfx_run.play()
	else:
		if sfx_run.playing:
			sfx_run.stop()

func lock_movement():
	is_locked = true
	
func unlock_movement():
	is_locked = false

# --- FUNGSI ANIMASI ---
func update_animation(input_vector: Vector2):
	if is_attacking:
		return

	var anim_prefix = ""
	
	if input_vector.length() == 0:
		anim_prefix = "idle"
	else:
		anim_prefix = "run"
		
	var anim_name = "%s_%s" % [anim_prefix, current_anim_direction]
	
	player.play(anim_name)

# --- FUNGSI ATTACK ---
func attack():
	is_attacking = true
	velocity = Vector2.ZERO
	sfx_run.stop()
	
	print("🗡️ Player attacking!")
	sfx_attack.play()  # 🔊 mainkan suara serangan di sini
	
	# Atur Hitbox
	var attack_position = last_direction * ATTACK_OFFSET
	attack_shape.position = attack_position
	attack_shape.disabled = false 

	
	# Mainkan Animasi
	var attack_anim_name = "attack_%s" % current_anim_direction
	player.play(attack_anim_name)
	
	# === DEAL DAMAGE KE ENEMIES ===
	# Tunggu sebentar agar hitbox sempat detect
	await get_tree().create_timer(0.1).timeout
	
	var enemies_in_range = attack_area.get_overlapping_bodies()
	
	print("📊 Enemies detected: ", enemies_in_range.size())
	
	for enemy in enemies_in_range:
		print("  - Found body: ", enemy.name, " | Has take_damage: ", enemy.has_method("take_damage"))
		
		if enemy.has_method("take_damage") and enemy != self:
			print("💥 Hitting enemy: ", enemy.name)
			enemy.take_damage(1)
	# ================================

	# Tunggu Durasi Serangan
	await get_tree().create_timer(ATTACK_DURATION).timeout
	
	if player.is_playing() and player.animation == attack_anim_name:
		await player.animation_finished
	
	# Reset
	is_attacking = false
	attack_shape.disabled = true
	update_animation(Vector2.ZERO)

# --- FUNGSI KERUSAKAN ---
func take_damage(amount: int = 1):
	if invincible:
		return
	
	invincible = true
	
	map_editor_ui.close()
	
	var new_health = GameData.health - amount
	GameData.set_health(new_health)
	print("Player health:", GameData.health)

	# 🔊 Mainkan suara ketika player kena serangan
	if sfx_attacked and not sfx_attacked.playing:
		sfx_attacked.play()
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("hurt")
		flash_red()
	
	if new_health > 1:
		await get_tree().create_timer(invincible_time).timeout
		invincible = false
	
	if new_health <= 1:
		var death_anim_name = "death_%s" % current_anim_direction
		$AnimatedSprite2D.play(death_anim_name)

		# 🔊 Mainkan suara kematian di sini
		if sfx_death:
			sfx_death.play()
		
		velocity = Vector2.ZERO
		move_and_slide()
		
		await $AnimatedSprite2D.animation_finished
		
		Engine.time_scale = 1.0
		
		GameData.set_death(true)
		
		get_tree().reload_current_scene()
		GameData.health = 6
		
		return


func flash_red():
	$AnimatedSprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)
			

var map_scene_instance = null



func _on_Button_Map_pressed() -> void:
	pass # Replace with function body.
