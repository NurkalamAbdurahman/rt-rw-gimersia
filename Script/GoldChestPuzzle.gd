extends CanvasLayer

signal puzzle_solved
signal puzzle_failed

const CELL_COUNT := 81
const GRID_COLS := 9
const CELL_SIZE := 36

const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.7, 0.7, 0.7)
const HOVER_MODULATE: Color = Color(1.0, 0.84, 0.0)  # Gold color
const ANIMATION_DURATION: float = 0.15

@onready var sfx_puzzle_failed: AudioStreamPlayer2D = $SFX_Puzzle_Failed
@onready var sfx_puzzle_solved: AudioStreamPlayer2D = $SFX_Puzzle_Solved
@onready var title = $Panel/VBoxContainer/Title
@onready var instructions = $Panel/VBoxContainer/Instructions
@onready var hint_label = $Panel/VBoxContainer/Hint
@onready var input_grid = $Panel/VBoxContainer/InputGrid
@onready var submit_btn = $Panel/VBoxContainer/HBoxContainer/Submit
@onready var reset_btn = $Panel/VBoxContainer/HBoxContainer/Reset
@onready var close_btn = $Panel/VBoxContainer/HBoxContainer/Close
@onready var notif_label: Label = $Panel/VBoxContainer/NotificationLabel
@onready var sfx_button_click: AudioStreamPlayer2D = $SFX_Button_Click
@onready var sfx_puzzle_klik: AudioStreamPlayer2D = $SFX_Puzzle_Klik

var player_input: Array[bool] = []
var buttons: Array = []
var action_buttons: Array[Button] = []
var selected_action_index := 0

func _ready():
	print("FAILED SFX:", sfx_puzzle_failed)
	print("FAILED STREAM:", sfx_puzzle_failed.stream if sfx_puzzle_failed else null)
	print("=== GOLD CHEST PUZZLE SCENE READY ===")
	layer = 100
	print("THIS NODE:", self)
	print("CHILDREN:", get_children())

	# Initialize action buttons
	action_buttons = [submit_btn, reset_btn, close_btn]
	
	# Setup action buttons - disable mouse interaction
	for btn in action_buttons:
		btn.modulate = NORMAL_MODULATE
		btn.scale = NORMAL_SCALE
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Update instructions
	var revealed_count = PuzzleManager.get_revealed_count()
	instructions.text = "Recreate the pattern!\nRevealed sections: %d/3" % revealed_count

	# Hint label
	hint_label.visible = revealed_count > 0

	# Create Input Grid
	_create_input_grid()
	
	# Set action buttons langsung aktif dari awal
	_update_action_button_focus()

func show_notification(text: String):
	notif_label.text = text
	notif_label.visible = true
	notif_label.modulate.a = 1.0

	# Fade out
	var tween = get_tree().create_tween()
	tween.tween_property(notif_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): notif_label.visible = false)

func _create_input_grid():
	input_grid.columns = GRID_COLS

	for i in range(CELL_COUNT):
		player_input.append(false)

		var row = i / GRID_COLS
		var col = i % GRID_COLS
		var section = col / 3

		var btn = Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		# Style
		var normal = StyleBoxFlat.new()
		normal.border_width_top = 2
		normal.border_width_bottom = 2
		normal.border_width_left = 2
		normal.border_width_right = 2

		normal.border_color = Color.BLACK

		if PuzzleManager.is_section_revealed(section):
			if PuzzleManager.puzzle_solution[i]:
				normal.bg_color = Color(1.0, 0.84, 0.0, 0.3)
			else:
				normal.bg_color = Color(0.15, 0.15, 0.15, 0.3)
		else:
			normal.bg_color = Color(0.3, 0.3, 0.3, 0.5)

		var pressed = StyleBoxFlat.new()
		pressed.border_width_top = 2
		pressed.border_width_bottom = 2
		pressed.border_width_left = 2
		pressed.border_width_right = 2

		pressed.border_color = Color.BLACK
		pressed.bg_color = Color(1.0, 0.84, 0.0)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover", normal)

		btn.pressed.connect(_on_button_pressed.bind(i))

		input_grid.add_child(btn)
		buttons.append(btn)

func _on_button_pressed(index: int):
	sfx_puzzle_klik.play()
	player_input[index] = buttons[index].button_pressed
	
	# Animate button press
	var btn = buttons[index]
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION * 0.5)
	
	btn.modulate = (
		Color(1.0, 0.84, 0.0) if buttons[index].button_pressed else Color.WHITE
	)

func _on_submit():
	_animate_action_button_press(submit_btn)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	
	for i in range(CELL_COUNT):
		if PuzzleManager.puzzle_solution[i] != player_input[i]:
			_wrong_feedback()
			return
	sfx_puzzle_solved.max_distance = 4000
	sfx_puzzle_solved.play()
	await sfx_puzzle_solved.finished
	puzzle_solved.emit()
	queue_free()

func _wrong_feedback():
	sfx_puzzle_failed.max_distance = 4000
	sfx_puzzle_failed.play()
	for btn in buttons:
		# Animate wrong feedback
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(btn, "modulate", Color.RED, ANIMATION_DURATION)
		tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION)
		
	await get_tree().create_timer(0.3).timeout
	
	# Restore button states with animation
	for i in range(buttons.size()):
		var btn = buttons[i]
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(btn, "modulate", 
			Color(1.0, 0.84, 0.0) if player_input[i] else Color.WHITE, 
			ANIMATION_DURATION
		)
		tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _on_reset():
	_animate_action_button_press(reset_btn)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	
	for i in range(CELL_COUNT):
		player_input[i] = false
		buttons[i].button_pressed = false
		
		# Animate reset
		var btn = buttons[i]
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(btn, "modulate", Color.WHITE, ANIMATION_DURATION)
		tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _on_close():
	_animate_action_button_press(close_btn)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	
	puzzle_failed.emit()
	GameData.is_popup_open = false
	queue_free()

func _update_action_button_focus():
	for i in range(action_buttons.size()):
		var btn = action_buttons[i]
		var tween = create_tween()
		tween.set_parallel(true)
		
		if i == selected_action_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _animate_action_button_press(btn: Button):
	sfx_button_click.play()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION * 0.5)
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION * 0.5)

# Handle keyboard navigation untuk action buttons
func _input(event):
	# Navigation between action buttons
	if event.is_action_pressed("menu_left"):
		selected_action_index = wrapi(selected_action_index - 1, 0, action_buttons.size())
		_update_action_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_right"):
		selected_action_index = wrapi(selected_action_index + 1, 0, action_buttons.size())
		_update_action_button_focus()
		get_viewport().set_input_as_handled()
	
	# Actions - manual trigger functions instead of emit pressed signal
	elif event.is_action_pressed("ui_accept"):
		if selected_action_index == 0:  # Submit
			_on_submit()
		elif selected_action_index == 1:  # Reset
			_on_reset()
		elif selected_action_index == 2:  # Close
			_on_close()
		get_viewport().set_input_as_handled()
