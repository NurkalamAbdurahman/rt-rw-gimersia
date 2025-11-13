extends Node2D

@onready var terkunci : Sprite2D = $Terkunci
@onready var anim_sprite: AnimatedSprite2D = $open_animation
@onready var terbuka: Sprite2D = $Terbuka
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label
@onready var sfx_chest_locked: AudioStreamPlayer2D = $SFX_ChestLocked
@export var popup_scene: PackedScene = preload("res://Scenes/ui/Next_Stage_2.tscn")

var player_in_area = false
var chest_opened = false

func _ready():
	if popup_scene == null:
		push_error("⚠️ popup_scene masih null! Path mungkin salah atau belum di-assign.")
	else:
		print("✅ popup_scene loaded:", popup_scene.resource_path)

	terkunci.visible = true
	terbuka.visible = false
	anim_sprite.visible = false
	anim_sprite.stop()
	label.visible = false

func _process(delta):
	if player_in_area and not chest_opened:
		if Input.is_action_just_pressed("e"):
			cek_buka_chest()
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false
		
func cek_buka_chest():
	if GameData.skull_keys > 0:
		# Punya silver key ✅
		GameData.skull_keys -= 1
		buka_pintu()
	else:
		# Tidak punya ❌ → munculkan warning
		sfx_chest_locked.play()
		label.text = "You need a skull Key!"
		label.visible = true
		await get_tree().create_timer(1.3).timeout
		if player_in_area and not chest_opened:
			label.text = "Press E to open"
		else:
			label.visible = false
		
func buka_pintu():
	if chest_opened:
		return

	chest_opened = true
	label.visible = false
	terkunci.visible = false
	anim_sprite.visible = true
	anim_sprite.animation = "open"
	anim_sprite.play()

	await anim_sprite.animation_finished

	anim_sprite.visible = false
	terbuka.visible = true

	# --- Tampi8lkan celebration dulu ---
	var celebration = preload("res://Scenes/ui/NextStageCelebration2.tscn").instantiate()
	get_tree().current_scene.add_child(celebration)
	await celebration.show_celebration()  # pause game otomatis dan animasi teks selesai

	# --- Setelah celebration selesai, tampilkan popup tombol next stage ---
	var popup_instance = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup_instance)
	popup_instance.show_popup()  # pause game + tombol interaktif
