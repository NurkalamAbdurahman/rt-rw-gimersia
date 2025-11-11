extends CanvasLayer

@onready var buy_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/buy_button
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/close_button
@onready var sfx_buy_potion = get_tree().root.get_node("bonus_stage/sfx_buyPotion")
@onready var sfx_buy_not_enough = get_tree().root.get_node("bonus_stage/sfx_buyNotEnough")
@onready var sfx_close = get_tree().root.get_node("bonus_stage/sfx_close")

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
		
	_update_button_focus()

func _input(event: InputEvent) -> void:
	# 1. Navigasi ke Atas (menu_up, ui_up, atau W)
	if event.is_action_pressed("menu_up") or event.is_action_pressed("ui_up") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_move_selection(-1) # Pindah ke atas berarti mengurangi indeks
		get_viewport().set_input_as_handled()
		
	# 2. Navigasi ke Bawah (menu_down, ui_down, atau S)
	elif event.is_action_pressed("menu_down") or event.is_action_pressed("ui_down") or \
		 (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_move_selection(1) # Pindah ke bawah berarti menambah indeks
		get_viewport().set_input_as_handled()
		
	# 3. Tekan Tombol (ui_accept)
	elif event.is_action_pressed("ui_accept"):
		navigable_buttons[selected_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()


# --- FUNGSI NAVIGASI YANG DISAMAKAN DARI SKRIP MAIN MENU ---
func _move_selection(direction: int) -> void:
	selected_index += direction

	# Looping (samakan: jika arah -1, artinya tombol ke atas)
	if selected_index < 0:
		selected_index = navigable_buttons.size() - 1 # Loop ke bawah
	elif selected_index >= navigable_buttons.size():
		selected_index = 0 # Loop ke atas

	# 🔊 Mainkan sound effect (jika node sfx_hover ada di scene Anda)
	# if sfx_hover and sfx_hover.playing:
	#     sfx_hover.stop()
	# if sfx_hover:
	#     sfx_hover.play()

	_update_button_focus()


# --- FUNGSI UPDATE FOKUS YANG DISAMAKAN DARI SKRIP MAIN MENU ---
func _update_button_focus() -> void:
	for i in range(navigable_buttons.size()):
		var btn = navigable_buttons[i]

		if i == selected_index:
			# ⭐️ Terapkan Modulasi Warna dan Skala untuk tombol yang fokus
			btn.modulate = Color(1.0, 0.84, 0.0)    # emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			# ⭐️ Terapkan Modulasi Warna dan Skala untuk tombol yang tidak fokus
			btn.modulate = Color(0.7, 0.7, 0.7)      # abu-abu
			btn.scale = Vector2(1, 1)

func _on_buy_pressed():
	var ui = get_tree().root.get_node("bonus_stage/ui_coin/coins_bonus")
	
	if GameData.coins >= potion_price:
		GameData.coins -= potion_price
		GameData.add_potion(addition)
		GameData.check_if_max_health()
		GameData.emit_signal("stats_updated")
		ui.show_message("You bought a potion!", 2.0)
		if sfx_buy_potion:
			sfx_buy_potion.play()
	else:
		ui.show_message("Not enough gold!", 2.0)
		if sfx_buy_not_enough:
			sfx_buy_not_enough.play()

func _on_close_pressed():
	if sfx_close:
		sfx_close.play()
	queue_free()
