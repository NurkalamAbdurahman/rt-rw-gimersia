extends ColorRect

@onready var color_rect: ColorRect = $"."
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var fade_timer: Timer = $Fade_Timer

signal fade_finished

func fade_out():
	color_rect.show()
	anim_player.play("fade_out")
	await anim_player.animation_finished
	emit_signal("fade_finished")

func fade_in():
	color_rect.show()
	anim_player.play("fade_in")
	await anim_player.animation_finished
	color_rect.hide()
