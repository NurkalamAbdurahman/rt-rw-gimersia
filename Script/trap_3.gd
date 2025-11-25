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

	# pastikan animasi tidak looping
	anim.sprite_frames.set_animation_loop("aktif", false)
	anim.sprite_frames.set_animation_loop("off", false)
	
	point_light.visible = false

	_start_cycle()


func _start_cycle():
	# mulai ke mode aktif
	state = "aktif"
	fire_trap.play()
	anim.play("aktif")
	_enable_hitbox()
	
	point_light.visible = true
	

	# setelah animasi aktif selesai → masuk fase bahaya 3 detik
	await anim.animation_finished
	await get_tree().create_timer(0.0).timeout

	# nonaktifkan hitbox dan masuk mode off
	_disable_hitbox()
	state = "off"
	anim.play("off")
	point_light.visible = false

	# tunggu 3 detik mode aman → ulangi cycle
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
