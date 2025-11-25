extends CanvasLayer

# Node references
@onready var hp_button: Button = $Control/Panel/HP/buy_button
@onready var speed_button: Button = $Control/Panel/Speed/buy_button
@onready var strength_button: Button = $Control/Panel/Strength/buy_button
@onready var exit_button: Button = $Exit

@onready var not_enough_label: Label = $NotEnough
@onready var buy_potion_label: Label = $BuyPotion

# SFX references
@onready var sfx_buy_potion: AudioStreamPlayer = get_tree().root.get_node("bonus_stage/sfx_buyPotion")
@onready var sfx_buy_not_enough: AudioStreamPlayer = get_tree().root.get_node("bonus_stage/sfx_buyNotEnough")
@onready var sfx_hover: AudioStreamPlayer = get_tree().root.get_node("bonus_stage/sfx_hover")
@onready var sfx_close: AudioStreamPlayer = get_tree().root.get_node("bonus_stage/sfx_close")

# Shop configuration
@export var hp_potion_price: int = 10
@export var speed_potion_price: int = 15
@export var strength_potion_price: int = 20
@export var potion_amount: int = 1

# Animation constants
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.7, 0.7, 0.7)
const HOVER_MODULATE: Color = Color(1.0, 0.84, 0.0)  # Gold color
const ANIMATION_DURATION: float = 0.15

# Navigation
var navigable_buttons: Array[Button] = []
var selected_index: int = 0

func _ready() -> void:
	# Tandai bahwa popup sedang terbuka
	GameData.is_popup_open = true
	
	_setup_buttons()
	_connect_signals()
	_hide_messages()
	
	# Fokus input ke shop
	set_process_input(true)

func _setup_buttons() -> void:
	navigable_buttons = [hp_button, speed_button, strength_button, exit_button]
	
	for btn in navigable_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
	
	# Set labels as top level
	not_enough_label.top_level = true
	buy_potion_label.top_level = true
	
	_update_button_focus()

func _connect_signals() -> void:
	hp_button.pressed.connect(_on_buy_hp_pressed)
	speed_button.pressed.connect(_on_buy_speed_pressed)
	strength_button.pressed.connect(_on_buy_strength_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _hide_messages() -> void:
	not_enough_label.hide()
	buy_potion_label.hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Navigasi horizontal untuk potion (kiri/kanan)
	if event.is_action_pressed("menu_left"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("menu_right"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		
	# Navigasi vertikal untuk pindah ke exit (bawah) dan kembali (atas)
	elif event.is_action_pressed("menu_down"):
		# Langsung pindah ke exit
		selected_index = 3
		_play_hover_sound()
		_update_button_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("menu_up"):
		# Kembali ke potion pertama (HP)
		selected_index = 0
		_play_hover_sound()
		_update_button_focus()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_accept"):
		_press_selected_button()
		get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	# Jika sedang di exit, kembali ke potion terakhir
	if selected_index == 3:
		selected_index = 2  # Kembali ke strength potion
	
	selected_index = wrapi(selected_index + direction, 0, 3)  # Hanya 0-2 untuk potion
	_play_hover_sound()
	_update_button_focus()

func _update_button_focus() -> void:
	for i in range(navigable_buttons.size()):
		var btn: Button = navigable_buttons[i]
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if i == selected_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _press_selected_button() -> void:
	var btn: Button = navigable_buttons[selected_index]
	_animate_button_press(btn)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	btn.emit_signal("pressed")

func _animate_button_press(btn: Button) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)

func _on_button_mouse_entered(btn: Button) -> void:
	selected_index = navigable_buttons.find(btn)
	_play_hover_sound()
	_update_button_focus()

func _on_button_mouse_exited(btn: Button) -> void:
	# Reset to normal state when mouse exits
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
	tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _play_hover_sound() -> void:
	if sfx_hover:
		sfx_hover.play()

# Purchase functions
func _on_buy_hp_pressed() -> void:
	if GameData.coins >= hp_potion_price:
		GameData.coins -= hp_potion_price
		GameData.add_hp_potion(potion_amount)
		_show_success_message("HP Potion purchased!")
		_play_buy_sound()
	else:
		_show_error_message("Not enough gold!")
		_play_error_sound()

func _on_buy_speed_pressed() -> void:
	if GameData.coins >= speed_potion_price:
		GameData.coins -= speed_potion_price
		GameData.add_speed_potion(potion_amount)
		_show_success_message("Speed Potion purchased!")
		_play_buy_sound()
	else:
		_show_error_message("Not enough gold!")
		_play_error_sound()

func _on_buy_strength_pressed() -> void:
	if GameData.coins >= strength_potion_price:
		GameData.coins -= strength_potion_price
		GameData.add_strength_potion(potion_amount)
		_show_success_message("Strength Potion purchased!")
		_play_buy_sound()
	else:
		_show_error_message("Not enough gold!")
		_play_error_sound()

func _on_exit_pressed() -> void:
	_close_shop()

func _close_shop() -> void:
	print("Shop: Closing shop and resetting flag")
	# Reset flag sebelum menutup
	GameData.is_popup_open = false
	
	if sfx_close:
		sfx_close.play()
	queue_free()

# Cleanup ketika node dihapus
func _exit_tree() -> void:
	print("Shop: Exit tree, ensuring flag is reset")
	# Pastikan flag direset bahkan jika shop ditutup dengan cara lain
	GameData.is_popup_open = false

func _show_success_message(message: String) -> void:
	buy_potion_label.text = message
	show_temp_message(buy_potion_label, 2.0)

func _show_error_message(message: String) -> void:
	not_enough_label.text = message
	show_temp_message(not_enough_label, 2.0)

func _play_buy_sound() -> void:
	if sfx_buy_potion:
		sfx_buy_potion.play()

func _play_error_sound() -> void:
	if sfx_buy_not_enough:
		sfx_buy_not_enough.play()

# Helper function to show temporary message
func show_temp_message(label: Label, duration: float) -> void:
	label.show()
	
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		label.hide()
		timer.queue_free()
	)
	timer.start()
