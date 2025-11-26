extends CharacterBody2D

const SPEED = 100.0
const WARNING_TIME: float = 10.0
const BLINK_INTERVAL: float = 0.3

@export var invincible_default_duration: float = 2.0
@export var invincible_forever: bool = false

var is_invincible := false
var invincible_timer := 0.0

@onready var map_editor_ui: Control = $"../MapEditorLayer/MapEditorUI"
@onready var you_dead_ui: CanvasLayer = get_tree().get_current_scene().get_node("YouDead")
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_run: AudioStreamPlayer2D = $SFX_Run_Stone
@onready var sfx_attacked: AudioStreamPlayer2D = $SFX_Attacked
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death
@onready var qte_system: CanvasLayer = $"../QTE_System"

var qte_damage_multiplier: float = 1.0
var qte_lock_position := Vector2.ZERO
var qte_engaged := false
var waiting_for_qte := false
var qte_attack_playing := false
var qte_attack_duration := 0.6

var has_torch := false
var held_torch = null
var is_dead := false	
var is_locked := false

var last_direction := Vector2.DOWN
var current_anim_direction := "down"

var strength_buff_active := false
var strength_buff_time := 0.0
var strength_buff_duration := 60.0
var strength_damage_multiplier := 2.0

var speed_buff_active := false
var speed_buff_time := 0.0
var speed_buff_duration := 60.0
var speed_multiplier := 1.5

var blink_timer := 0.0
var is_blinking := false
var is_flashing := false

func _ready() -> void:
	add_to_group("Player")
	_connect_signals()
	
	# ✅ LOAD PERSISTENT BUFFS DARI GAMEDATA
	strength_buff_active = GameData.persistent_strength_buff_active
	strength_buff_time = GameData.persistent_strength_buff_time
	speed_buff_active = GameData.persistent_speed_buff_active  
	speed_buff_time = GameData.persistent_speed_buff_time
	
	update_buff_visuals()
	if strength_buff_active or speed_buff_active:
		print("🎯 Persistent buffs loaded! Strength:", strength_buff_time, "s Speed:", speed_buff_time, "s")

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	_update_buffs(delta)
	
	if is_locked:
		_enforce_lock()
		return
	
	_update_invincibility(delta)
	_handle_movement()
	_update_animation_state()
	_handle_footstep_sfx()

func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	if invincible_forever:
		return  # Tak pernah habis

	invincible_timer -= delta

	if invincible_timer <= 0:
		remove_invincible()

func apply_strength_potion() -> bool:
	if not GameData.use_strength_potion():
		return false
	
	if strength_buff_active:
		strength_buff_time += strength_buff_duration
	else:
		strength_buff_active = true
		strength_buff_time = strength_buff_duration
	
	update_buff_visuals()  # ✅ STANDARDIZED NAME
	print("💪 Strength buff applied! Time:", strength_buff_time)
	return true

func apply_speed_potion() -> bool:
	if not GameData.use_speed_potion():
		return false
	
	if speed_buff_active:
		speed_buff_time += speed_buff_duration
	else:
		speed_buff_active = true
		speed_buff_time = speed_buff_duration
	
	update_buff_visuals()  # ✅ STANDARDIZED NAME
	print("⚡ Speed buff applied! Time:", speed_buff_time)
	return true

func lock_movement(enemy_position: Vector2 = Vector2.ZERO) -> void:
	is_locked = true
	velocity = Vector2.ZERO
	qte_lock_position = global_position
	
	if enemy_position != Vector2.ZERO:
		_face_enemy(enemy_position)
	
	print("🔒 Player locked")

func unlock_movement() -> void:
	is_locked = false
	qte_lock_position = Vector2.ZERO
	print("🔓 Player unlocked")

func engage_qte() -> void:
	waiting_for_qte = true
	qte_engaged = true
	sfx_run.stop()
	print("🎯 QTE engaged")

func take_damage(amount: int) -> void:
	if is_dead:
		return
	if is_invincible:
		sfx_attacked.play()
		return

	sfx_attacked.play()
	GameData.set_health(GameData.health - amount)
	map_editor_ui.close()
	
	_flash_damage()
	
	if GameData.health <= 0:
		_die()

func ghost_success() -> void:
	print("Player selamat! +3 coins")
	GameData.add_coin(3)

func ghost_failed() -> void:
	print("Player tertangkap! -1 coin")
	if GameData.coins > 0:
		GameData.coins -= 1
		GameData.emit_signal("stats_updated")

func _connect_signals() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_torch_picked_up"))
	
	qte_system = get_tree().get_first_node_in_group("QTE_System")
	if qte_system:
		qte_system.qte_success.connect(_on_qte_success)
		qte_system.qte_failed.connect(_on_qte_failed)
	
	if you_dead_ui:
		you_dead_ui.respawn_pressed.connect(_on_respawn_selected)

func _update_buffs(delta: float) -> void:
	_update_buff_timer(delta, "strength")
	_update_buff_timer(delta, "speed")
	
	# ✅ SAVE PERSISTENT BUFFS KE GAMEDATA
	GameData.persistent_strength_buff_active = strength_buff_active
	GameData.persistent_strength_buff_time = strength_buff_time
	GameData.persistent_speed_buff_active = speed_buff_active
	GameData.persistent_speed_buff_time = speed_buff_time
	
	if is_blinking:
		blink_timer += delta
		if blink_timer >= BLINK_INTERVAL:
			blink_timer = 0.0
			_toggle_blink()

func _update_buff_timer(delta: float, buff_type: String) -> void:
	var is_active := strength_buff_active if buff_type == "strength" else speed_buff_active
	if not is_active:
		return
	
	if buff_type == "strength":
		strength_buff_time -= delta
		if strength_buff_time <= WARNING_TIME and not is_blinking:
			is_blinking = true
		if strength_buff_time <= 0:
			_deactivate_buff("strength")
	else:
		speed_buff_time -= delta
		if speed_buff_time <= WARNING_TIME and not is_blinking:
			is_blinking = true
		if speed_buff_time <= 0:
			_deactivate_buff("speed")

func _deactivate_buff(buff_type: String) -> void:
	if buff_type == "strength":
		strength_buff_active = false
		strength_buff_time = 0.0
	else:
		speed_buff_active = false
		speed_buff_time = 0.0
	
	is_blinking = false
	update_buff_visuals()  # ✅ STANDARDIZED NAME
	print("❌ %s buff expired!" % buff_type.capitalize())

# ✅ FUNCTION YANG BENAR - STANDARD NAME
func update_buff_visuals() -> void:
	if is_flashing:
		return
		
	if not strength_buff_active and not speed_buff_active:
		player.modulate = Color.WHITE
	elif strength_buff_active and speed_buff_active:
		player.modulate = Color(1.3, 0.7, 1.3)
	elif strength_buff_active:
		player.modulate = Color(1.3, 0.5, 0.5)
	else:
		player.modulate = Color(0.5, 1.3, 1.3)

func _toggle_blink() -> void:
	if is_flashing:
		return
		
	if player.modulate == Color.WHITE:
		update_buff_visuals()  # ✅ STANDARDIZED NAME
	else:
		player.modulate = Color.WHITE

func _handle_movement() -> void:
	var input := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	if input != Vector2.ZERO:
		var current_speed := SPEED * (speed_multiplier if speed_buff_active else 1.0)
		velocity = input * current_speed
		last_direction = input
		_update_direction(input)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _update_direction(input: Vector2) -> void:
	if abs(input.x) > abs(input.y):
		current_anim_direction = "right"
		player.flip_h = input.x < 0
	else:
		current_anim_direction = "up" if input.y < 0 else "down"

func _update_animation_state() -> void:
	if qte_attack_playing or is_locked:
		return
	
	var prefix := "run" if velocity.length() > 0 else "idle"
	player.play("%s_%s" % [prefix, current_anim_direction])

func _handle_footstep_sfx() -> void:
	if velocity.length() > 0:
		if not sfx_run.playing:
			sfx_run.play()
	else:
		sfx_run.stop()

func _enforce_lock() -> void:
	global_position = qte_lock_position
	velocity = Vector2.ZERO
	move_and_slide()

func _face_enemy(enemy_position: Vector2) -> void:
	var direction := (enemy_position - global_position).normalized()
	last_direction = direction
	
	if abs(direction.x) > abs(direction.y):
		current_anim_direction = "right"
		player.flip_h = direction.x < 0
	else:
		current_anim_direction = "down" if direction.y > 0 else "up"
	
	player.play("idle_%s" % current_anim_direction)

func _on_qte_success() -> void:
	if not waiting_for_qte or not qte_engaged:
		return
	
	waiting_for_qte = false
	qte_engaged = false
	
	qte_damage_multiplier = strength_damage_multiplier if strength_buff_active else 1.0
	print("✨ QTE SUCCESS! Multiplier:", qte_damage_multiplier)
	
	_play_attack_animation()

func _play_attack_animation() -> void:
	qte_attack_playing = true
	
	var attack_anim := "attack_%s" % current_anim_direction
	if player.sprite_frames.has_animation(attack_anim):
		player.play(attack_anim)
	else:
		player.play("attack")
	
	_flash_color(Color(1.2, 1.2, 1.0), 0.3)
	
	await get_tree().create_timer(qte_attack_duration).timeout
	qte_attack_playing = false

func _on_qte_failed() -> void:
	if not waiting_for_qte or not qte_engaged:
		return
	
	waiting_for_qte = false
	qte_engaged = false
	qte_damage_multiplier = 0.5
	print("❌ QTE FAILED!")
	
	_flash_color(Color(1.0, 0.4, 0.4), 0.15)

func _flash_damage() -> void:
	_flash_color(Color(1.0, 0.4, 0.4), 0.15)

func _flash_color(flash_color: Color, duration: float) -> void:
	is_flashing = true
	
	var buff_color := _get_current_buff_color()
	
	player.modulate = flash_color
	await get_tree().create_timer(duration).timeout
	player.modulate = buff_color
	
	is_flashing = false

func _get_current_buff_color() -> Color:
	if not strength_buff_active and not speed_buff_active:
		return Color.WHITE
	elif strength_buff_active and speed_buff_active:
		return Color(1.3, 0.7, 1.3)
	elif strength_buff_active:
		return Color(1.3, 0.5, 0.5)
	else:
		return Color(0.5, 1.3, 1.3)

func _die() -> void:
	if is_dead:
		return
	
	is_dead = true
	is_locked = true
	velocity = Vector2.ZERO
	PuzzleManager.reset_puzzle()
	PuzzleManager.reset_solved_chest()
	
	if sfx_death:
		sfx_death.play()
	
	var death_anim := "death_%s" % current_anim_direction
	if player.sprite_frames.has_animation(death_anim):
		player.play(death_anim)
		player.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	else:
		player.play("death_d")
		await get_tree().create_timer(1.0).timeout
		_show_death_ui()

func _on_death_animation_finished() -> void:
	player.stop()
	_show_death_ui()

func _show_death_ui() -> void:
	if you_dead_ui:
		you_dead_ui.show_you_dead()

func _on_torch_picked_up(torch_node) -> void:
	if has_torch:
		return
	
	held_torch = torch_node
	has_torch = true
	held_torch.get_parent().remove_child(held_torch)
	add_child(held_torch)
	held_torch.position = Vector2(0, 10)

func _on_respawn_selected() -> void:
	print("⚡ Respawn!")
	GameData.reset()
	GameData.set_death(true)
	get_tree().reload_current_scene()

func make_invincible(duration: float = -1.0) -> void:
	if invincible_forever:
		is_invincible = true
		is_blinking = true
		print("🛡️ Player Invincible FOREVER")
		return

	# Kalau duration = -1 → pakai default export
	if duration <= 0:
		duration = invincible_default_duration

	is_invincible = true
	invincible_timer = duration
	is_blinking = true
	print("🛡️ Player Invincible for ", duration, " seconds")

func remove_invincible() -> void:
	is_invincible = false
	invincible_timer = 0.0
	is_blinking = false
	update_buff_visuals()  # ✅ STANDARDIZED NAME
	print("🛑 Invincibility removed")
