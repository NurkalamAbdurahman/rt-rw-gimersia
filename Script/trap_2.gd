extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

# SFX
@onready var open_sfx: AudioStreamPlayer2D = $BatuTrap     # suara saat anim close

@export var damage := 1

var active := false
var state := "idle"


func _ready():
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_entered)
	
	anim.sprite_frames.set_animation_loop("open", false)
	anim.sprite_frames.set_animation_loop("close", false)
	
	_start_cycle()


func _start_cycle():
	state = "opening"
	open_sfx.play()            # 🔊 PLAY SFX saat OPEN
	anim.play("open")


func _process(_delta):
	# OPEN selesai
	if state == "opening" and anim.frame == anim.sprite_frames.get_frame_count("open") - 1:
		state = "pause-open"
		_enable_hitbox()

		await get_tree().create_timer(3.0).timeout   # jeda berbahaya

		_disable_hitbox()
		state = "closing"

		open_sfx.play()       # 🔊 PLAY SFX saat CLOSE
		anim.play("close")

	# CLOSE selesai
	if state == "closing" and anim.frame == anim.sprite_frames.get_frame_count("close") - 1:
		state = "pause-close"
		await get_tree().create_timer(1.0).timeout   # jeda aman (tidak hitbox)
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
