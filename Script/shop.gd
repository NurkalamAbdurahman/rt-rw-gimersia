extends CanvasLayer

@onready var buy_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/buy_button
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/close_button
@onready var sfx_buy_potion = get_tree().root.get_node("bonus_stage/sfx_buyPotion")
@onready var sfx_buy_not_enough = get_tree().root.get_node("bonus_stage/sfx_buyNotEnough")
@onready var sfx_close = get_tree().root.get_node("bonus_stage/sfx_close")
@onready var not_enough: Label = $NotEnough
@onready var buy_potion: Label = $BuyPotion

var potion_price = 10
var addition = 1
var navigable_buttons: Array[Button] = []
var selected_index: int = 0

func _ready():
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	
	navigable_buttons.append(buy_button)
	navigable_buttons.append(close_button)
	
	for btn in navigable_buttons:
		btn.focus_mode = Control.FOCUS_NONE
	
	# Pastikan label tersembunyi saat start
	not_enough.hide()
	buy_potion.hide()
	
	buy_potion.top_level = true
	not_enough.top_level = true

	
	_update_button_focus()

func _input(event: InputEvent) -> void:
	# Navigasi ke Atas
	if event.is_action_pressed("menu_up") or event.is_action_pressed("ui_up") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		
	# Navigasi ke Bawah
	elif event.is_action_pressed("menu_down") or event.is_action_pressed("ui_down") or \
		 (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		
	# Tekan Tombol
	elif event.is_action_pressed("ui_accept"):
		navigable_buttons[selected_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	selected_index += direction
	
	if selected_index < 0:
		selected_index = navigable_buttons.size() - 1
	elif selected_index >= navigable_buttons.size():
		selected_index = 0
	
	_update_button_focus()

func _update_button_focus() -> void:
	for i in range(navigable_buttons.size()):
		var btn = navigable_buttons[i]
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)
			btn.scale = Vector2(1, 1)

func _on_buy_pressed():
	if GameData.coins >= potion_price:
		GameData.coins -= potion_price
		GameData.add_potion(addition)
		GameData.check_if_max_health()
		show_temp_message(buy_potion, "You bought a potion!", 2.0)
		print("Anda membeli potion")
		GameData.emit_signal("stats_updated")
		if sfx_buy_potion:
			sfx_buy_potion.play()
	else:
		show_temp_message(not_enough, "Not enough gold!", 2.0)
		if sfx_buy_not_enough:
			sfx_buy_not_enough.play()

func _on_close_pressed():
	if sfx_close:
		sfx_close.play()
	queue_free()

# Fungsi helper untuk menampilkan pesan sementara
func show_temp_message(label: Label, message: String, duration: float) -> void:
	label.text = message
	await get_tree().process_frame
	label.show()
	
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		label.hide()
		timer.queue_free()
	)
	timer.start()
