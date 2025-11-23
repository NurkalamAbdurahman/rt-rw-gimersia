# PatternViewer.gd - Shows a section of the puzzle pattern
extends CanvasLayer

signal viewer_closed

var section_index: int = 0
const CELL_SIZE := 36
const SECTION_ROWS := 9  # All 9 rows
const SECTION_COLS := 3  # 3 columns per section

func _ready():
	layer = 100
	show_pattern_section()

func show_pattern_section():
	# Main panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -250)
	panel.size = Vector2(400, 500)
	add_child(panel)

	# VBox layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(360, 460)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PUZZLE PATTERN - PART %d/3" % (section_index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Memorize this section!\nColumns %d-%d" % [(section_index * 3) + 1, (section_index * 3) + 3]
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	# Pattern grid (3 columns x 9 rows for this section)
	var pattern_grid = GridContainer.new()
	pattern_grid.columns = SECTION_COLS
	pattern_grid.custom_minimum_size = Vector2(SECTION_COLS * CELL_SIZE + 20, SECTION_ROWS * CELL_SIZE + 20)
	pattern_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(pattern_grid)

	# Display the section of the puzzle
	for row in range(SECTION_ROWS):
		for col in range(SECTION_COLS):
			var global_col = section_index * SECTION_COLS + col
			var index = row * 9 + global_col  # 9 is total columns in full puzzle
			
			var cell_panel = Panel.new()
			cell_panel.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

			var style = StyleBoxFlat.new()
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_width_left = 1
			style.border_color = Color.BLACK

			if PuzzleManager.puzzle_solution[index]:
				style.bg_color = Color(1.0, 0.84, 0.0)  # Gold
			else:
				style.bg_color = Color(0.15, 0.15, 0.15)  # Dark gray

			cell_panel.add_theme_stylebox_override("panel", style)
			pattern_grid.add_child(cell_panel)

	# Close button
	var close = Button.new()
	close.text = "CLOSE (I've Memorized It)"
	close.add_theme_font_size_override("font_size", 16)
	close.connect("pressed", Callable(self, "_on_close"))
	vbox.add_child(close)

	print("=== PATTERN SECTION ", section_index, " DISPLAYED ===")

func _on_close():
	print("PATTERN VIEWER CLOSED")
	viewer_closed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
