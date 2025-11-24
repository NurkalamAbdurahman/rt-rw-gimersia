extends CharacterBody2D

const SPEED = 100.0
@onready var map_editor_ui: Control = $"../MapEditorLayer/MapEditorUI"
@onready var you_dead_ui: CanvasLayer = get_tree().get_current_scene().get_node("YouDead")

@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_run: AudioStreamPlayer2D = $SFX_Run_Stone
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Attacked
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var qte_system: CanvasLayer = $"../QTE_System"

var qte_damage_multiplier: float = 1.0
var qte_lock_position = Vector2.ZERO
var qte_engaged = false
var waiting_for_qte: bool = false
var qte_attack_playing = false
var qte_attack_duration = 0.6

var has_torch = false
var held_torch = null
var is_dead: bool = false	
var is_locked: bool = false

var last_direction: Vector2 = Vector2.DOWN
var current_anim_direction: String = "down"

var strength_buff_active: bool = false
var strength_buff_time: float = 0.0
var strength_buff_duration: float = 60.0
var strength_damage_multiplier: float = 2.0

var speed_buff_active: bool = false
var speed_buff_time: float = 0.0
var speed_buff_duration: float = 60.0
var speed_multiplier: float = 1.5

const WARNING_TIME: float = 10.0
const BLINK_INTERVAL: float = 0.3

var blink_timer: float = 0.0
var is_blinking: bool = false

func _ready() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_torch_picked_up"))
	
	add_to_group("Player")
	qte_system = get_tree().get_first_node_in_group("QTE_System")

	print("QTE system found:", qte_system)

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
	
	update_buff_timers(delta)
	
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
		var current_speed = SPEED * (speed_multiplier if speed_buff_active else 1.0)
		velocity = normalized_input * current_speed
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

func apply_strength_potion() -> bool:
	if GameData.use_strength_potion():
		if strength_buff_active:
			strength_buff_time += strength_buff_duration
		else:
			strength_buff_active = true
			strength_buff_time = strength_buff_duration
			apply_strength_visual()
		
		print("💪 Strength buff applied! Time:", strength_buff_time)
		return true
	return false

func apply_speed_potion() -> bool:
	if GameData.use_speed_potion():
		if speed_buff_active:
			speed_buff_time += speed_buff_duration
		else:
			speed_buff_active = true
			speed_buff_time = speed_buff_duration
			apply_speed_visual()
		
		print("⚡ Speed buff applied! Time:", speed_buff_time)
		return true
	return false

func update_buff_timers(delta: float):
	if strength_buff_active:
		strength_buff_time -= delta
		
		if strength_buff_time <= WARNING_TIME and not is_blinking:
			start_blinking_effect("strength")
		
		if strength_buff_time <= 0:
			deactivate_strength_buff()
	
	if speed_buff_active:
		speed_buff_time -= delta
		
		if speed_buff_time <= WARNING_TIME and not is_blinking:
			start_blinking_effect("speed")
		
		if speed_buff_time <= 0:
			deactivate_speed_buff()
	
	if is_blinking:
		blink_timer += delta
		if blink_timer >= BLINK_INTERVAL:
			blink_timer = 0.0
			toggle_buff_visual()

func apply_strength_visual():
	var base_color = Color(1, 1, 1)
	if speed_buff_active:
		player.modulate = Color(1.3, 0.7, 1.3)
	else:
		player.modulate = Color(1.3, 0.5, 0.5)

func apply_speed_visual():
	var base_color = Color(1, 1, 1)
	if strength_buff_active:
		player.modulate = Color(1.3, 0.7, 1.3)
	else:
		player.modulate = Color(0.5, 1.3, 1.3)

func start_blinking_effect(buff_type: String):
	is_blinking = true
	blink_timer = 0.0

func toggle_buff_visual():
	var target_color = Color(1, 1, 1)
	
	if strength_buff_active and speed_buff_active:
		if player.modulate == Color(1, 1, 1):
			target_color = Color(1.3, 0.7, 1.3)
		else:
			target_color = Color(1, 1, 1)
	elif strength_buff_active:
		if player.modulate == Color(1, 1, 1):
			target_color = Color(1.3, 0.5, 0.5)
		else:
			target_color = Color(1, 1, 1)
	elif speed_buff_active:
		if player.modulate == Color(1, 1, 1):
			target_color = Color(0.5, 1.3, 1.3)
		else:
			target_color = Color(1, 1, 1)
	
	player.modulate = target_color

func deactivate_strength_buff():
	strength_buff_active = false
	strength_buff_time = 0.0
	is_blinking = false
	update_combined_visual()
	print("❌ Strength buff expired!")

func deactivate_speed_buff():
	speed_buff_active = false
	speed_buff_time = 0.0
	is_blinking = false
	update_combined_visual()
	print("❌ Speed buff expired!")

func update_combined_visual():
	if not strength_buff_active and not speed_buff_active:
		player.modulate = Color(1, 1, 1)
	elif strength_buff_active and speed_buff_active:
		player.modulate = Color(1.3, 0.7, 1.3)
	elif strength_buff_active:
		player.modulate = Color(1.3, 0.5, 0.5)
	elif speed_buff_active:
		player.modulate = Color(0.5, 1.3, 1.3)

func lock_movement(enemy_position: Vector2 = Vector2.ZERO):
	is_locked = true
	velocity = Vector2.ZERO
	qte_lock_position = global_position
	
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
	qte_lock_position = Vector2.ZERO
	print("🔓 Player movement unlocked")

func face_towards_enemy(enemy_position: Vector2):
	var direction_to_enemy = (enemy_position - global_position).normalized()
	last_direction = direction_to_enemy
	
	if abs(direction_to_enemy.x) > abs(direction_to_enemy.y):
		current_anim_direction = "right" if direction_to_enemy.x > 0 else "left"
	else:
		current_anim_direction = "down" if direction_to_enemy.y > 0 else "up"
	
	player.flip_h = (current_anim_direction == "left")
	
	play_facing_animation()

func play_facing_animation():
	var anim_name = "idle_%s" % current_anim_direction
	if player.sprite_frames.has_animation(anim_name):
		player.play(anim_name)
	else:
		player.play("idle_" + current_anim_direction)

func update_facing_during_qte(enemy_position: Vector2):
	if is_locked:
		face_towards_enemy(enemy_position)

func update_animation(input_vector: Vector2):
	if qte_attack_playing:
		return
	
	if is_locked:
		play_facing_animation()
		return

	var anim_prefix = ""
	
	if input_vector.length() == 0:
		anim_prefix = "idle"
	else:
		anim_prefix = "run"
		
	var anim_name = "%s_%s" % [anim_prefix, current_anim_direction]
	
	player.play(anim_name)

func _on_qte_success():
	if not waiting_for_qte or not qte_engaged:
		return
		
	waiting_for_qte = false
	qte_engaged = false
	
	var final_multiplier = 1.0
	if strength_buff_active:
		final_multiplier *= strength_damage_multiplier
	
	qte_damage_multiplier = final_multiplier
	print("✨ QTE SUCCESS! Damage multiplier:", qte_damage_multiplier)
	
	play_qte_attack_animation()
	flash_green()
	
func play_qte_attack_animation():
	print("💥 Player playing attack animation!")
	qte_attack_playing = true
	
	var attack_anim_name = "attack_" + current_anim_direction
	print("Attempting to play:", attack_anim_name)
	print("Animation exists:", player.sprite_frames.has_animation(attack_anim_name))
	
	if player.sprite_frames.has_animation(attack_anim_name):
		player.play(attack_anim_name)
	else:
		print("⚠️ No attack animation found: ", attack_anim_name)
		player.play("attack")
	
	player.modulate = Color(1.2, 1.2, 1.0)
	var tween = create_tween()
	tween.tween_property(player, "modulate", Color(1, 1, 1), 0.3)
	
	await get_tree().create_timer(qte_attack_duration).timeout
	qte_attack_playing = false
	update_combined_visual()

func _on_qte_failed():
	if not waiting_for_qte or not qte_engaged:
		return
		
	waiting_for_qte = false
	qte_engaged = false
	qte_damage_multiplier = 0.5
	print("❌ QTE FAILED! Player takes damage!")
	flash_red()

func take_damage(amount: int):
	print("🎯 Player take_damage called - dead:", is_dead)
	
	if is_dead:
		print("🎯 Player damage blocked - already dead")
		return

	sfx_attacked.play()
	
	var new_health = GameData.health - amount
	GameData.set_health(new_health)
	print("🎯 Player health decreased to:", GameData.health)
	map_editor_ui.close()
	
	flash_red()

	if new_health <= 0:
		die()

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

	var frames = player.sprite_frames
	if frames.has_animation(death_anim_name):
		player.play(death_anim_name)
		await player.animation_finished
	else:
		print("⚠️ Tidak ada animasi", death_anim_name, "pakai default death_d. Menggunakan fallback timer.")
		player.play("death_d")
		await get_tree().create_timer(1.0).timeout 

	if you_dead_ui:
		you_dead_ui.show_you_dead()

func _on_respawn_selected():
	print("⚡ Respawn pressed — respawn player!")
	GameData.reset()
	GameData.set_death(true)
	get_tree().reload_current_scene()

func flash_green():
	var original_color = player.modulate
	$AnimatedSprite2D.modulate = Color(0.4, 1, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = original_color

func flash_red():
	print("FLASH CALLED")
	var original_color = player.modulate
	$AnimatedSprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D.modulate = original_color

func _on_Button_Map_pressed() -> void:
	pass

func ghost_success():
	print("Player selamat! +3 coins")
	GameData.add_coin(3)

func ghost_failed():
	print("Player tertangkap! -1 coin")
	if GameData.coins > 0:
		GameData.coins -= 1
		GameData.emit_signal("stats_updated")
