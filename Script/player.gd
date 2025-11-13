extends CharacterBody2D

const SPEED = 100.0
const ATTACK_DURATION = 0.25
const ATTACK_OFFSET = 15.0
@onready var map_editor_ui: Control = $MapEditorLayer/MapEditorUI
@onready var you_dead_ui: CanvasLayer = get_tree().get_current_scene().get_node("YouDead")

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
var is_dead: bool = false	

var is_locked: bool = false

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var current_anim_direction: String = "down" 

var is_knocked_back: bool = false
const KNOCKBACK_STRENGTH = 200.0 # Kecepatan dorongan
const KNOCKBACK_DURATION = 0.2 # Durasi dorongan (detik)

# --- FUNGSI INIT ---
func _ready() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_torch_picked_up"))
		
	attack_shape.disabled = true
	
	# PENTING: Tambahkan player ke group "Player"
	add_to_group("Player")
	
	# Debug: print untuk cek apakah attack_area ada
	if attack_area:
		print("✅ AttackArea2D found!")
	else:
		print("❌ AttackArea2D NOT FOUND!")
	
#	fungsi you dead
	if you_dead_ui:
		you_dead_ui.connect("respawn_pressed", Callable(self, "_on_respawn_selected"))

func _on_torch_picked_up(torch_node):
	if not has_torch:
		held_torch = torch_node
		has_torch = true
		held_torch.get_parent().remove_child(held_torch)
		add_child(held_torch)
		held_torch.position = Vector2(0, 10)

# --- FUNGSI FISIKA & INPUT ---
func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# ⚠️ TIDAK PERLU CEK GameData.health di sini. Cukup andalkan is_dead.
	# if GameData.health <= 1:
	# 	velocity = Vector2.ZERO
	# 	move_and_slide()
	# 	return
		
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO)
		return
	
	# >>> KNOCKBACK LOGIC <<<
	if is_knocked_back:
		# Pergerakan sudah diatur di take_damage, hanya perlu geser
		move_and_slide()
		return
	# <<< END KNOCKBACK >>>
	
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
	sfx_attack.play()

	var attack_position = last_direction * ATTACK_OFFSET
	attack_shape.position = attack_position
	attack_shape.disabled = false

	var attack_anim_name = "attack_%s" % current_anim_direction
	player.play(attack_anim_name)

	# --- Tunggu sedikit agar area aktif ---
	await get_tree().create_timer(0.1).timeout
	if is_dead:
		is_attacking = false
		attack_shape.disabled = true
		return

	var enemies_in_range = attack_area.get_overlapping_bodies()
	for enemy in enemies_in_range:
		if enemy.has_method("take_damage") and enemy != self:
			enemy.take_damage(1, global_position)

	# --- Tunggu durasi serangan ---
	await get_tree().create_timer(ATTACK_DURATION).timeout
	if is_dead:
		is_attacking = false
		attack_shape.disabled = true
		return

	if player.is_playing() and player.animation == attack_anim_name:
		await player.animation_finished
		if is_dead:
			is_attacking = false
			attack_shape.disabled = true
			return

	is_attacking = false
	attack_shape.disabled = true
	update_animation(Vector2.ZERO)


# --- FUNGSI KERUSAKAN ---
func take_damage(amount, damage_source_position: Vector2):
	sfx_attacked.play()
	if invincible or is_dead: # ✅ Cek is_dead di awal
		return

	var new_health = GameData.health - amount
	GameData.set_health(new_health)
	print("Player health:", GameData.health)
	map_editor_ui.close()
	
	flash_red()

	if new_health <= 1:
		die()
		return # ✅ PENTING: Segera keluar setelah memanggil die()
		
	# --- LOGIKA KNOCKBACK ---
	# 1. Hitung arah dorongan (dari sumber damage ke pemain)
	var knockback_direction = (global_position - damage_source_position).normalized()
	
	# 2. Terapkan velocity dan set state knockback
	velocity = knockback_direction * KNOCKBACK_STRENGTH
	is_knocked_back = true
	is_attacking = false # Batalkan serangan jika sedang menyerang
	sfx_run.stop()
	
	# 3. Nonaktifkan knockback setelah durasi
	await get_tree().create_timer(KNOCKBACK_DURATION).timeout
	
	# Reset state dan velocity
	if is_knocked_back and not is_dead: # ✅ Cek is_dead lagi sebelum reset
		is_knocked_back = false
		velocity = Vector2.ZERO

func die():
	if is_dead:
		return
		
	is_dead = true # ✅ Atur status mati segera
	print("💀 Player died")

	is_locked = true
	velocity = Vector2.ZERO
	move_and_slide()

	if sfx_death:
		sfx_death.play()

	# 🎬 Tentukan nama animasi sesuai arah
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

	# 🎞️ Cek apakah animasi tersebut ada di AnimatedSprite2D
	var frames = player.sprite_frames
	if frames.has_animation(death_anim_name):
		player.play(death_anim_name)
		await player.animation_finished
	else:
		print("⚠️ Tidak ada animasi", death_anim_name, "pakai default death_d. Menggunakan fallback timer.")
		player.play("death_d")
		# ⏱️ Fallback timer: Tunggu 1.0 detik jika animasi bermasalah
		await get_tree().create_timer(1.0).timeout 

	# 🩸 Tampilkan UI "You Dead"
	if you_dead_ui:
		you_dead_ui.show_you_dead()


func _on_respawn_selected():
	print("⚡ Respawn pressed — respawn player!")
	GameData.reset()
	GameData.set_death(true)
	get_tree().reload_current_scene()


func flash_red():
	print("FLASH CALLED")  # Debug
	$AnimatedSprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

var map_scene_instance = null

func _on_Button_Map_pressed() -> void:
	pass # Replace with function body.as
