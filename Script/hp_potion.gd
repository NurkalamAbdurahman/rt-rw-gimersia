extends Control

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var backgroung_menu: Sprite2D = $BackgroungMenu
@onready var label: Label = $Label
@onready var click_deep: AudioStreamPlayer = $ClickDeep
@onready var potion_used: AudioStreamPlayer = $PotionUsed

var label_default_color := Color.WHITE
var default_scale := Vector2(0.5, 0.5)

const ANIM_DURATION_FAST: float = 0.1
const ANIM_DURATION_NORMAL: float = 0.15
const SUCCESS_SCALE_MULTIPLIER: float = 1.3
const ERROR_SCALE_MAX: float = 1.2
const ERROR_SCALE_MIN: float = 0.9

func _ready() -> void:
	label_default_color = label.modulate
	default_scale = sprite_2d.scale

func _process(_delta: float) -> void:
	label.text = str(GameData.hp_potion)
	
	if Input.is_action_just_pressed("ui_hp_potion"): 
		if GameData.use_hp_potion():
			print("darah nambah")
			_play_success_animation()
			potion_used.play()
		else:
			print("nggak bisa minum potion")
			_play_error_animation()
			click_deep.play()

func _play_success_animation():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite_2d, "scale", default_scale * SUCCESS_SCALE_MULTIPLIER, ANIM_DURATION_NORMAL)
	tween.tween_property(sprite_2d, "scale", default_scale, ANIM_DURATION_NORMAL)

func _play_error_animation():
	_bounce_icon(sprite_2d)
	_flash_label(label)

func _bounce_icon(node: Node2D):
	var tween = create_tween()
	tween.tween_property(node, "scale", default_scale * ERROR_SCALE_MAX, ANIM_DURATION_FAST)
	tween.tween_property(node, "scale", default_scale * ERROR_SCALE_MIN, ANIM_DURATION_FAST)
	tween.tween_property(node, "scale", default_scale, ANIM_DURATION_FAST)

func _flash_label(lb: Label):
	var tween := create_tween()
	tween.tween_property(lb, "modulate", Color(1, 0.2, 0.2), ANIM_DURATION_FAST)
	tween.tween_property(lb, "modulate", label_default_color, ANIM_DURATION_NORMAL)
