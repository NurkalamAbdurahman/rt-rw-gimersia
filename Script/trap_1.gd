extends Node2D

@onready var flame_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var physical_detector = $PhysicalCollider

@onready var step_sfx: AudioStreamPlayer = $StepTrap
@onready var fire_sfx: AudioStreamPlayer = $FireTrap
@onready var point_light: PointLight2D = $AnimatedSprite2D/PointLight2D

var is_running := false
var active := false
@export var damage := 1

func _ready():
	active = false
	hitbox.monitoring = false
	point_light.visible = false

	if not flame_anim.animation_finished.is_connected(_on_animation_finished):
		flame_anim.animation_finished.connect(_on_animation_finished)

	physical_detector.body_entered.connect(_on_detector_entered)
	hitbox.body_entered.connect(_on_hitbox_entered)


func _on_detector_entered(body):
	if not body.is_in_group("Player"):
		return
	if is_running:
		return

	is_running = true

	# 🔊 SFX saat trap diinjak (StepTrap)
	if step_sfx:
		step_sfx.play()

	if flame_anim.sprite_frames.has_animation("spirit2D"):
		flame_anim.sprite_frames.set_animation_loop("spirit2D", false)
		flame_anim.play("spirit2D")
	else:
		_enable_fire()


func _on_animation_finished():
	match flame_anim.animation:
		"spirit2D":
			_enable_fire()

		"trapFire":
			_disable_trap()


func _enable_fire():
	active = true
	hitbox.monitoring = true

	if fire_sfx:
		fire_sfx.play()

	# ---- FADE IN POINT LIGHT ----
	point_light.visible = true
	var tween := create_tween()
	point_light.energy = 0.0
	tween.tween_property(point_light, "energy", 1.5, 0.25) # 0.25 detik, bisa diatur

	if flame_anim.sprite_frames.has_animation("trapFire"):
		flame_anim.sprite_frames.set_animation_loop("trapFire", false)

	flame_anim.play("trapFire")


func _disable_trap():
	active = false
	hitbox.monitoring = false
	is_running = false

	# ---- FADE OUT POINT LIGHT ----
	var tween := create_tween()
	tween.tween_property(point_light, "energy", 0.0, 0.25)
	tween.finished.connect(func():
		point_light.visible = false
	)

	flame_anim.stop()



func _on_hitbox_entered(body):
	if active and body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
