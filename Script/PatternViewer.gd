extends CanvasLayer

signal viewer_closed

@export var section_index: int = 0
const CELL_SIZE := 36
const SECTION_ROWS := 9
const SECTION_COLS := 3

const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.7, 0.7, 0.7)
const HOVER_MODULATE: Color = Color(1.0, 0.84, 0.0)  # Gold color
const ANIMATION_DURATION: float = 0.15

@onready var title_label: Label = $Panel/VBoxContainer/VBoxContainer/TitleLabel
@onready var instructions_label: Label = $Panel/VBoxContainer/VBoxContainer/InstructionsLabel
@onready var pattern_grid: GridContainer = $Panel/VBoxContainer/PatternGrid
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready():
	show_pattern_section()
	
	# Setup close button
	close_button.modulate = HOVER_MODULATE
	close_button.scale = HOVER_SCALE
	
	# HAPUS: Koneksi signal pressed (mouse click)
	# close_button.pressed.connect(_on_close_button_pressed)

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

func _on_close_button_pressed():
	_animate_button_press(close_button)
	await get_tree().create_timer(ANIMATION_DURATION).timeout
	viewer_closed.emit()
	queue_free()

func _animate_button_press(btn: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION * 0.5)
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION * 0.5)

# Handle keyboard input
func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
