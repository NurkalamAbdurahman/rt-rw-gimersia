extends CanvasLayer

@onready var control: Control = $Control
@onready var label: Label = $Control/Panel/MarginContainer/VBoxContainer/Label
@onready var no: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/no
@onready var yes: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/yes

signal confirmed
signal cancelled

var _tween: Tween
var buttons: Array[Button] = []
var selected_index: int = 0

# Animation and color variables - now consistent with fountain
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.7, 0.7, 0.7)
const HOVER_MODULATE: Color = Color(1.0, 0.84, 0.0)  # Gold color
const ANIMATION_DURATION: float = 0.15

func _ready():
	hide()
	
	buttons = [yes, no]
	
	yes.pressed.connect(_on_confirm_pressed)
	no.pressed.connect(_on_cancel_pressed)
	
	# Setup button focus mode and signals
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
	
	_update_button_focus()

func show_popup(message: String = ""):
	# Only set label text if message is provided, otherwise use default from node
	if message != "":
		label.text = message
	show()
	
	if _tween and _tween.is_running():
		_tween.kill()
	
	control.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 1.0, 0.2)

func _on_confirm_pressed():
	confirmed.emit()
	hide_popup()

func _on_cancel_pressed():
	cancelled.emit()
	hide_popup()

func hide_popup():
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 0.0, 0.2)
	_tween.finished.connect(func(): queue_free())

func _input(event: InputEvent):
	if not visible:
		return
	
	if Input.is_action_just_pressed("menu_right"):
		selected_index = (selected_index + 1) % buttons.size()
		_play_hover_sound()
		_update_button_focus()
	elif Input.is_action_just_pressed("menu_left"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_play_hover_sound()
		_update_button_focus()
	elif Input.is_action_just_pressed("ui_accept"):
		_press_selected_button()

func _press_selected_button():
	var btn: Button = buttons[selected_index]
	_animate_button_press(btn)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	btn.emit_signal("pressed")

func _animate_button_press(btn: Button):
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)

func _update_button_focus():
	for i in range(buttons.size()):
		var btn = buttons[i]
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if i == selected_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _play_hover_sound():
	# You can add hover sound here if needed
	pass
