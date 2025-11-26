extends Node2D

@onready var pintu_terkunci : Sprite2D = $Terkunci
@onready var anim_open: AnimatedSprite2D = $open_animation
@onready var pintu_terbuka: Sprite2D = $Terbuka
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_pintu_terkunci: AudioStreamPlayer2D = $SFX_DoorLocked

@export var popup_scene: PackedScene = preload("res://Scenes/ui/Next_Stage.tscn")
@onready var next_stage: CanvasLayer = $NextStage
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var player_2: CharacterBody2D = $"../Player2"
@export var pintu_ke_stage :int = 2
@onready var stand_point: Node2D = $StandPoint   # ← titik berdiri di depan pintu

var player_in_area = false
var pintu_terbuka_state = false


func _ready():
	pintu_terkunci.visible = true
	pintu_terbuka.visible = false
	anim_open.visible = false
	anim_open.stop()
	label.visible = false


func _process(delta):
	if player_in_area and not pintu_terbuka_state:
		if Input.is_action_just_pressed("e"):
			cek_buka_pintu()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not pintu_terbuka_state:
		player_in_area = true
		label.visible = true
		label.text = "[E] Enter"


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false


func cek_buka_pintu():
	if GameData.skull_keys > 0:
		GameData.skull_keys -= 1
		buka_pintu()
	else:
		sfx_pintu_terkunci.play()
		label.text = "You need a skull key!"
		label.visible = true

		await get_tree().create_timer(1.3).timeout
		if player_in_area and not pintu_terbuka_state:
			label.text = "[E] Enter"
		else:
			label.visible = false


func buka_pintu():
	if pintu_terbuka_state:
		return

	GameData.clear_data()
	GameData.is_popup_open = true
	pintu_terbuka_state = true

	label.visible = false
	pintu_terkunci.visible = false
	anim_open.visible = true
	anim_open.animation = "open"
	anim_open.play()

	await anim_open.animation_finished

	anim_open.visible = false
	pintu_terbuka.visible = true

	# --- Referensi player ---
	var player = get_tree().get_first_node_in_group("player")
	if player and animation_player:

		# ➤ Gerakkan player ke depan pintu dulu
		var target_pos = stand_point.global_position
		await move_player_to_position(player, target_pos)

		# Jalankan animasi pintu
		animation_player.play("Open_Door")
		await animation_player.animation_finished

		# Reset player setelah animasi
		reset_player_animation(player)


	# --- Celebration popup ---
	var celebration = preload("res://Scenes/ui/NextStageCelebration.tscn").instantiate()
	get_tree().current_scene.add_child(celebration)
	await celebration.show_celebration()

	var popup_instance = popup_scene.instantiate()
	popup_instance.pintu_to_stage = pintu_ke_stage
	get_tree().current_scene.add_child(popup_instance)
	popup_instance.show_popup()



# ====================================
# FUNGSI TAMBAHAN
# ====================================

func move_player_to_position(player: CharacterBody2D, target_pos: Vector2) -> void:
	player.set_physics_process(false)

	var direction = (target_pos - player.global_position).normalized()

	# 🔥 Mainkan animasi lari sesuai arah
	play_run_animation(player, direction)

	# Tween gerak
	var move_tween = create_tween()
	move_tween.tween_property(player, "global_position", target_pos, 0.6)

	await move_tween.finished

	# berhenti animasi setelah sampai
	var anim = player.get_node("AnimatedSprite2D") 
	anim.play("idle_down")  # atau idle sesuai arah terakhir


func reset_player_animation(player: CharacterBody2D):
	var initial_visible = false
	player.visible = initial_visible
	player.set_physics_process(true)

func play_run_animation(player: CharacterBody2D, direction: Vector2):
	var anim = player.get_node("AnimatedSprite2D") # sesuaikan jika nama node beda

	if abs(direction.x) > abs(direction.y):
		# Gerak horizontal
		if direction.x > 0:
			anim.play("run_right")
		else:
			anim.play("run_left")
	else:
		# Gerak vertical
		if direction.y > 0:
			anim.play("run_down")
		else:
			anim.play("run_up")
