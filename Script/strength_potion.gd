extends Control

@onready var label: Label = $Label
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var background_menu: Sprite2D = $BackgroungMenu

var label_default_color: Color = Color.WHITE
var default_scale: Vector2 = Vector2(0.5, 0.5)

const ANIM_DURATION_FAST: float = 0.1
const ANIM_DURATION_NORMAL: float = 0.15
const SUCCESS_SCALE_MULTIPLIER: float = 1.3
const ERROR_SCALE_MAX: float = 1.2
const ERROR_SCALE_MIN: float = 0.9

func _ready() -> void:
	label_default_color = label.modulate
	default_scale = sprite_2d.scale

func _process(_delta: float) -> void:
	label.text = str(GameData.strength_potion)
	
	if Input.is_action_just_pressed("ui_strength_potion"):
		_try_use_strength_potion()

func _try_use_strength_potion() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	
	if not player:
		print("Player not found in scene!")
		_play_error_animation()
		return
	
	if player.has_method("apply_strength_potion"):
		var success = player.apply_strength_potion()
		
		if success:
			print("Strength Potion used successfully!")
			_play_success_animation()
		else:
			print("Cannot use Strength Potion")
			_play_error_animation()
	else:
		print("Player doesn't have apply_strength_potion method!")
		_play_error_animation()

func _play_success_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite_2d, "scale", default_scale * SUCCESS_SCALE_MULTIPLIER, ANIM_DURATION_NORMAL)
	tween.tween_property(sprite_2d, "scale", default_scale, ANIM_DURATION_NORMAL)

func _play_error_animation() -> void:
	_bounce_icon(sprite_2d)
	_flash_label(label)

func _bounce_icon(node: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property(node, "scale", default_scale * ERROR_SCALE_MAX, ANIM_DURATION_FAST)
	tween.tween_property(node, "scale", default_scale * ERROR_SCALE_MIN, ANIM_DURATION_FAST)
	tween.tween_property(node, "scale", default_scale, ANIM_DURATION_FAST)

func _flash_label(lb: Label) -> void:
	var tween = create_tween()
	tween.tween_property(lb, "modulate", Color(1, 0.2, 0.2), ANIM_DURATION_FAST)
	tween.tween_property(lb, "modulate", label_default_color, ANIM_DURATION_NORMAL)
