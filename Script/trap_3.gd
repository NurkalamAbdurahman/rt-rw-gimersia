extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var fire_trap: AudioStreamPlayer2D = $FireTrap
@onready var point_light: PointLight2D = $AnimatedSprite2D/PointLight2D

@export var damage := 1

var active := false
var state := "idle"

func _ready():
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_entered)

	anim.sprite_frames.set_animation_loop("aktif", false)
	anim.sprite_frames.set_animation_loop("off", false)
	
	point_light.visible = false
	point_light.energy = 0.0

	_start_cycle()


func _start_cycle():
	state = "aktif"
	fire_trap.play()
	anim.play("aktif")
	_enable_hitbox()

	# ---- FADE IN LIGHT ----
	point_light.visible = true
	var tw_in := create_tween()
	point_light.energy = 0.0
	tw_in.tween_property(point_light, "energy", 1.4, 0.25)  # smooth  

	await anim.animation_finished
	await get_tree().create_timer(0.0).timeout

	_disable_hitbox()
	state = "off"
	anim.play("off")

	# ---- FADE OUT LIGHT ----
	var tw_out := create_tween()
	tw_out.tween_property(point_light, "energy", 0.0, 0.25)
	tw_out.finished.connect(func():
		point_light.visible = false
	)

	await get_tree().create_timer(1).timeout
	_start_cycle()


func _enable_hitbox():
	active = true
	hitbox.monitoring = true


func _disable_hitbox():
	active = false
	hitbox.monitoring = false


func _on_hitbox_entered(body):
	if active and body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
