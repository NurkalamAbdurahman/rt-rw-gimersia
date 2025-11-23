extends CanvasLayer

signal puzzle_solved
signal puzzle_failed

const CELL_COUNT := 81
const GRID_COLS := 9
const CELL_SIZE := 36

var player_input: Array[bool] = []
var buttons: Array = []

func _ready():
	print("=== GOLD CHEST PUZZLE LOADED ===")
	print("Revealed sections: ", PuzzleManager.revealed_sections)
	layer = 100

	# Main panel - bigger to fit everything
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -300)
	panel.size = Vector2(500, 650)
	add_child(panel)

	# Main VBox layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(460, 610)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "GOLDEN CHEST PUZZLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Instructions
	var instructions = Label.new()
	var revealed_count = PuzzleManager.get_revealed_count()
	instructions.text = "Recreate the pattern!\nSections revealed: %d/3" % revealed_count
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 16)
	vbox.add_child(instructions)

	# Hint info
	if revealed_count > 0:
		var hint_label = Label.new()
		hint_label.text = "✓ Hints shown for revealed sections"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.add_theme_color_override("font_color", Color.GREEN)
		vbox.add_child(hint_label)

	# Input grid (player answers here)
	var input_grid = GridContainer.new()
	input_grid.columns = GRID_COLS
	input_grid.custom_minimum_size = Vector2(420, 420)
	input_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(input_grid)

	# Initialize player input
	for i in range(CELL_COUNT):
		player_input.append(false)

	# Create input buttons with hints for revealed sections
	for i in range(CELL_COUNT):
		var row = i / GRID_COLS
		var col = i % GRID_COLS
		var section = col / 3  # Which section (0, 1, or 2)
		
		var btn = Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		var normal = StyleBoxFlat.new()
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_width_left = 2
		normal.border_color = Color.BLACK
		
		# Show hint if this section is revealed
		if PuzzleManager.is_section_revealed(section):
			# Show the correct answer as a hint
			if PuzzleManager.puzzle_solution[i]:
				normal.bg_color = Color(1.0, 0.84, 0.0, 0.3)  # Faded gold hint
			else:
				normal.bg_color = Color(0.15, 0.15, 0.15, 0.3)  # Faded dark gray hint
		else:
			# No hint - locked section
			normal.bg_color = Color(0.3, 0.3, 0.3, 0.5)  # Gray locked

		var pressed = StyleBoxFlat.new()
		pressed.border_width_top = 2
		pressed.border_width_right = 2
		pressed.border_width_bottom = 2
		pressed.border_width_left = 2
		pressed.border_color = Color.BLACK
		pressed.bg_color = Color(1.0, 0.84, 0.0)  # Full gold when pressed

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover", normal)

		btn.connect("pressed", Callable(self, "_on_button_pressed").bind(i))

		input_grid.add_child(btn)
		buttons.append(btn)

	# Buttons
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var submit = Button.new()
	submit.text = "SUBMIT"
	submit.add_theme_font_size_override("font_size", 18)
	submit.connect("pressed", Callable(self, "_on_submit"))
	hbox.add_child(submit)

	var reset = Button.new()
	reset.text = "RESET"
	reset.connect("pressed", Callable(self, "_on_reset"))
	hbox.add_child(reset)

	var close = Button.new()
	close.text = "CLOSE"
	close.connect("pressed", Callable(self, "_on_close"))
	hbox.add_child(close)

	print("=== GOLD CHEST PUZZLE UI CREATED ===")

func _on_button_pressed(index: int):
	player_input[index] = buttons[index].button_pressed

	if buttons[index].button_pressed:
		buttons[index].modulate = Color(1.0, 0.84, 0.0)
	else:
		buttons[index].modulate = Color(1, 1, 1, 1)

func _on_submit():
	var correct = true
	for i in range(CELL_COUNT):
		if PuzzleManager.puzzle_solution[i] != player_input[i]:
			correct = false
			break

	if correct:
		print("PUZZLE SOLVED!")
		puzzle_solved.emit()
		queue_free()
	else:
		print("Wrong pattern, try again")
		# Flash wrong feedback
		for btn in buttons:
			btn.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		for i in range(buttons.size()):
			if player_input[i]:
				buttons[i].modulate = Color(1.0, 0.84, 0.0)
			else:
				buttons[i].modulate = Color(1, 1, 1, 1)

func _on_reset():
	for i in range(player_input.size()):
		player_input[i] = false
		buttons[i].button_pressed = false
		buttons[i].modulate = Color(1, 1, 1, 1)

func _on_close():
	print("PUZZLE CLOSED")
	puzzle_failed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
