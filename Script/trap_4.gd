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

	# matikan lampu saat mulai
	point_light.visible = false

	_start_cycle()

func _start_cycle():
	# mode aktif
	state = "aktif"
	fire_trap.play()
	anim.play("aktif")
	_enable_hitbox()

	# HIDUPKAN CAHAYA SAAT AKTIF 🔥
	point_light.visible = true

	# tunggu animasi selesai
	await anim.animation_finished
	await get_tree().create_timer(0.0).timeout

	# masuk mode off
	_disable_hitbox()
	state = "off"
	anim.play("off")

	# MATIKAN CAHAYA SAAT OFF ❌
	point_light.visible = false

	# tunggu sebelum mengulang
	await get_tree().create_timer(0.8).timeout
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
