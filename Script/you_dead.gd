extends CanvasLayer

signal respawn_pressed

@onready var root_control: Control = $Control
@onready var respawn: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Respawn
@onready var quit: Button = $"Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Main menu"
@onready var kontainer: MarginContainer = $Control/Panel/MarginContainer
@onready var panel: Panel = $Control/Panel
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array[Button]
var selected_index := 0

const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.6, 0.65, 0.7) 
const HOVER_MODULATE: Color = Color(0.9, 0.95, 1.0)
const DISABLED_MODULATE: Color = Color(0.3, 0.3, 0.3, 0.5)
const ANIMATION_DURATION: float = 0.15

func _ready() -> void:
	_init_ui()
	_connect_signals()

func show_you_dead() -> void:
	GameData.is_popup_open = true
	get_tree().paused = true
	root_control.show()
	
	await _animate_show()
	_enable_buttons()

func hide_you_dead() -> void:
	GameData.is_popup_open = false
	await _animate_hide()
	root_control.hide()

func _init_ui() -> void:
	root_control.hide()
	root_control.modulate.a = 0.0
	
	# Set posisi awal margin container di atas layar
	kontainer.position.y = -500
	kontainer.modulate.a = 0.0
	
	buttons = [respawn, quit]
	for btn in buttons:
		btn.modulate = NORMAL_MODULATE
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
		# ✅ NONAKTIFKAN INTERAKSI MOUSE
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_update_button_focus()

func _connect_signals() -> void:
	respawn.pressed.connect(_on_respawn_pressed)
	quit.pressed.connect(_on_quit_pressed)
	
	# ❌ HAPUS KONEKSI MOUSE SIGNALS
	# for btn in buttons:
	#     btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))

func _animate_show() -> void:
	_disable_buttons()
	
	# Fade in background
	var bg_tween := create_tween()
	bg_tween.set_trans(Tween.TRANS_CUBIC)
	bg_tween.set_ease(Tween.EASE_OUT)
	bg_tween.tween_property(root_control, "modulate:a", 1.0, 0.3)
	
	await bg_tween.finished
	
	# Animate margin container dari atas ke tengah
	var container_tween := create_tween().set_parallel(true)
	container_tween.set_trans(Tween.TRANS_BACK)
	container_tween.set_ease(Tween.EASE_OUT)
	
	container_tween.tween_property(kontainer, "position:y", 0, 0.5)
	container_tween.tween_property(kontainer, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.3).timeout
	_animate_buttons_in()
	
	await container_tween.finished

func _animate_buttons_in() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		
		btn.pivot_offset = btn.size / 2
		
		tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "scale", NORMAL_SCALE, 0.4).set_delay(i * 0.1)

func _animate_hide() -> void:
	# Animate buttons out
	for i in buttons.size():
		var btn := buttons[i]
		var btn_tween := create_tween().set_parallel(true)
		btn_tween.set_trans(Tween.TRANS_CUBIC)
		btn_tween.set_ease(Tween.EASE_IN)
		
		btn_tween.tween_property(btn, "modulate:a", 0.0, 0.2)
		btn_tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.2)
	
	await get_tree().create_timer(0.2).timeout
	
	# Animate margin container ke atas
	var container_tween := create_tween().set_parallel(true)
	container_tween.set_trans(Tween.TRANS_BACK)
	container_tween.set_ease(Tween.EASE_IN)
	
	container_tween.tween_property(kontainer, "position:y", -500, 0.3)
	container_tween.tween_property(kontainer, "modulate:a", 0.0, 0.3)
	
	await container_tween.finished
	
	# Fade out background
	var bg_tween := create_tween()
	bg_tween.tween_property(root_control, "modulate:a", 0.0, 0.2)
	
	await bg_tween.finished

func _enable_buttons() -> void:
	for btn in buttons:
		btn.disabled = false
		btn.modulate = NORMAL_MODULATE
	_update_button_focus()

func _disable_buttons() -> void:
	for btn in buttons:
		btn.disabled = true
		btn.modulate = DISABLED_MODULATE

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if event.is_action_pressed("menu_left"):
		_move_selection(-1)
	elif event.is_action_pressed("menu_right"):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_press_selected_button()

func _move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, buttons.size())
	sfx_hover.play()
	_animate_button_focus()

func _press_selected_button() -> void:
	var btn := buttons[selected_index]
	_animate_button_press(btn)
	await get_tree().create_timer(ANIMATION_DURATION * 0.5).timeout
	btn.emit_signal("pressed")

func _update_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		if i == selected_index:
			btn.modulate = HOVER_MODULATE
			btn.scale = HOVER_SCALE
		else:
			btn.modulate = NORMAL_MODULATE
			btn.scale = NORMAL_SCALE

func _animate_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		btn.pivot_offset = btn.size / 2
		
		if i == selected_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION).set_trans(Tween.TRANS_BACK)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)

func _on_respawn_pressed() -> void:
	get_tree().paused = false
	await hide_you_dead()
	GameData.set_death(true)
	respawn_pressed.emit()

func _on_quit_pressed() -> void:
	var fade_node := get_tree().root.get_node_or_null("ScreenFade")
	if fade_node and fade_node.has_method("fade_out"):
		await fade_node.fade_out()
	
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")
