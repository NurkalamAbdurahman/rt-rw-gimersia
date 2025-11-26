extends CanvasLayer

@onready var control: Control = $Control
@onready var label: Label = $Control/Panel/MarginContainer/VBoxContainer/Label
@onready var no: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/no
@onready var yes: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/yes
@onready var margin_container: MarginContainer = $Control/Panel/MarginContainer
@onready var panel: Panel = $Control/Panel

signal confirmed
signal cancelled

var _tween: Tween
var buttons: Array[Button] = []
var selected_index: int = 0

# Animation and color variables - now consistent with fountain
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.6, 0.65, 0.7) 
const HOVER_MODULATE: Color = Color(0.9, 0.95, 1.0)
const ANIMATION_DURATION: float = 0.15

# Animation variables
var original_margin_position: Vector2
var is_animating: bool = false

func _ready():
	hide()
	
	buttons = [yes, no]
	
	# Simpan posisi asli margin_container
	original_margin_position = margin_container.position
	
	yes.pressed.connect(_on_confirm_pressed)
	no.pressed.connect(_on_cancel_pressed)
	
	# Setup button focus mode and signals
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
	
	_update_button_focus()

func show_popup(message: String = ""):
	if is_animating:
		return
		
	is_animating = true
	
	# Only set label text if message is provided, otherwise use default from node
	if message != "":
		label.text = message
	
	show()
	
	# Reset margin_container position ke atas
	margin_container.position.y = -margin_container.size.y
	margin_container.modulate.a = 0.0
	
	# Fade in background
	if _tween and _tween.is_running():
		_tween.kill()
	
	control.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 1.0, 0.3)
	
	await _tween.finished
	
	# Animasi margin_container turun dari atas
	var margin_tween = create_tween()
	margin_tween.set_parallel(true)
	
	# Animasi posisi - turun dari atas
	margin_tween.tween_property(margin_container, "position:y", original_margin_position.y, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animasi fade in
	margin_tween.tween_property(margin_container, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await margin_tween.finished
	
	is_animating = false

func _on_confirm_pressed():
	if is_animating:
		return
		
	confirmed.emit()

func _on_cancel_pressed():
	if is_animating:
		return
		
	cancelled.emit()
	hide_popup()

func hide_popup():
	if is_animating:
		return
		
	is_animating = true
	
	if _tween and _tween.is_running():
		_tween.kill()
	
	# Animasi margin_container naik ke atas sebelum menutup
	var hide_tween = create_tween()
	hide_tween.set_parallel(true)
	
	# Animasi posisi - naik ke atas
	hide_tween.tween_property(margin_container, "position:y", -margin_container.size.y, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Animasi fade out
	hide_tween.tween_property(margin_container, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await hide_tween.finished
	
	# Fade out background
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 0.0, 0.2)
	
	await _tween.finished
	
	queue_free()

func _input(event: InputEvent):
	if not visible or is_animating:
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
	if is_animating:
		return
		
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
		
		btn.pivot_offset = btn.size / 2

		
		if i == selected_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _play_hover_sound():
	# You can add hover sound here if needed
	pass
