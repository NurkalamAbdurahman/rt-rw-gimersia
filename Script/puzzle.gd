extends CanvasLayer

signal puzzle_solved
signal puzzle_failed

const CELL_COUNT := 81
const GRID_COLS := 9
const CELL_SIZE := 36

var solution: Array[bool] = []
var player_input: Array[bool] = []
var buttons: Array = []

func _ready():
	print("=== PUZZLE 9x9 LOADED (godot4 fixes) ===")
	layer = 100
	randomize()

	# Main panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-500, -300)
	panel.size = Vector2(900, 750)
	add_child(panel)

	# Main VBox layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(860, 710)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PUZZLE LOCK 9×9"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Memorize the pattern!\n(Watch for 3 seconds)"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 18)
	vbox.add_child(instructions)

	# Horizontal container for both grids
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)

	# Pattern grid (SOAL)
	var pattern_grid = GridContainer.new()
	pattern_grid.columns = GRID_COLS
	pattern_grid.custom_minimum_size = Vector2(420, 420)
	pattern_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_child(pattern_grid)

	# Input grid (JAWABAN)
	var input_grid = GridContainer.new()
	input_grid.columns = GRID_COLS
	input_grid.custom_minimum_size = Vector2(420, 420)
	input_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_child(input_grid)

	# Generate solution + init player_input
	for i in range(CELL_COUNT):
		solution.append(randi() % 2 == 0)
		player_input.append(false)

	# Create pattern display using Panel (so we can style borders/background)
	for i in range(CELL_COUNT):
		var cell_panel = Panel.new()
		cell_panel.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		var style = StyleBoxFlat.new()
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_width_left = 1
		style.border_color = Color.BLACK

		if solution[i]:
			style.bg_color = Color(1.0, 0.84, 0.0) # gold-like
		else:
			style.bg_color = Color(0.15, 0.15, 0.15) # dark gray

		# apply style with Godot4 method
		cell_panel.add_theme_stylebox_override("panel", style)
		pattern_grid.add_child(cell_panel)

	# Wait 3 seconds then hide pattern
	await get_tree().create_timer(3.0).timeout

	for child in pattern_grid.get_children():
		if child is Panel:
			var s = StyleBoxFlat.new()
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_width_left = 1
			s.border_color = Color.BLACK
			s.bg_color = Color(0.15, 0.15, 0.15)
			child.add_theme_stylebox_override("panel", s)

	instructions.text = "Click to recreate the pattern!"

	# Create input buttons with style overrides for normal/pressed/hover
	for i in range(CELL_COUNT):
		var btn = Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

		var normal = StyleBoxFlat.new()
		normal.border_width_top = 1
		normal.border_width_right = 1
		normal.border_width_bottom = 1
		normal.border_width_left = 1
		normal.border_color = Color.BLACK
		normal.bg_color = Color(1, 1, 1, 0) # transparent

		var pressed = StyleBoxFlat.new()
		pressed.border_width_top = 1
		pressed.border_width_right = 1
		pressed.border_width_bottom = 1
		pressed.border_width_left = 1
		pressed.border_color = Color.BLACK
		pressed.bg_color = Color(1.0, 0.84, 0.0) # gold for pressed

		# apply overrides with correct Godot4 method
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover", normal)

		# connect pressed signal with index bound
		btn.connect("pressed", Callable(self, "_on_button_pressed").bind(i))

		input_grid.add_child(btn)
		buttons.append(btn)

	# Submit & Close
	var submit = Button.new()
	submit.text = "SUBMIT"
	submit.add_theme_font_size_override("font_size", 20)
	submit.connect("pressed", Callable(self, "_on_submit"))
	vbox.add_child(submit)

	var close = Button.new()
	close.text = "CLOSE"
	close.connect("pressed", Callable(self, "_on_close"))
	vbox.add_child(close)

	print("=== PUZZLE 9x9 UI CREATED (godot4 fixes) ===")


func _on_button_pressed(index: int):
	# read pressed state from button
	player_input[index] = buttons[index].pressed

	# visual feedback — rely on style override but keep modulation to ensure color if engine theme interferes
	if buttons[index].pressed:
		buttons[index].modulate = Color(1.0, 0.84, 0.0)
	else:
		buttons[index].modulate = Color(1,1,1,1)


func _on_submit():
	var correct = true
	for i in range(CELL_COUNT):
		if solution[i] != player_input[i]:
			correct = false
			break

	if correct:
		print("PUZZLE SOLVED!")
		puzzle_solved.emit()
		queue_free()
	else:
		print("Wrong pattern, try again")
		# optional: highlight wrong cells briefly (bisa ditambah kalau mau)


func _on_close():
	print("PUZZLE CLOSED")
	puzzle_failed.emit()
	queue_free()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
