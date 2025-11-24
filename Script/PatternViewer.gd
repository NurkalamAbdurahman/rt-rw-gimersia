extends CanvasLayer

signal viewer_closed

@export var section_index: int = 0
const CELL_SIZE := 36
const SECTION_ROWS := 9
const SECTION_COLS := 3

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var instructions_label: Label = $Panel/VBoxContainer/InstructionsLabel
@onready var pattern_grid: GridContainer = $Panel/VBoxContainer/PatternGrid
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready():
	show_pattern_section()
	close_button.connect("pressed", Callable(self, "_on_close"))

func show_pattern_section():
	title_label.text = "PUZZLE PATTERN - PART %d/3" % (section_index + 1)
	instructions_label.text = "Memorize this section!\nColumns %d-%d" % [(section_index * 3) + 1, (section_index * 3) + 3]

	# Hapus semua cell lama dulu
	for child in pattern_grid.get_children():
		child.queue_free()


	for row in range(SECTION_ROWS):
		for col in range(SECTION_COLS):
			var global_col = section_index * SECTION_COLS + col
			var index = row * 9 + global_col  # 9 = total columns full puzzle

			var cell_panel = Panel.new()
			cell_panel.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)

			var style = StyleBoxFlat.new()
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.border_width_left = 1
			style.border_width_right = 1

			style.border_color = Color.BLACK
			style.bg_color = Color(1,0.84,0) if PuzzleManager.puzzle_solution[index] else Color(0.15,0.15,0.15)

			cell_panel.add_theme_stylebox_override("panel", style)
			pattern_grid.add_child(cell_panel)

func _on_close():
	emit_signal("viewer_closed")
	queue_free()
