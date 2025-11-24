extends CanvasLayer

signal puzzle_solved
signal puzzle_failed

const CELL_COUNT := 81
const GRID_COLS := 9
const CELL_SIZE := 36

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

var player_input: Array[bool] = []
var buttons: Array = []

func _ready():
	print("FAILED SFX:", sfx_puzzle_failed)
	print("FAILED STREAM:", sfx_puzzle_failed.stream if sfx_puzzle_failed else null)
	print("=== GOLD CHEST PUZZLE SCENE READY ===")
	layer = 100
	print("THIS NODE:", self)
	print("CHILDREN:", get_children())

	# Update instructions
	var revealed_count = PuzzleManager.get_revealed_count()
	instructions.text = "Recreate the pattern!\nRevealed sections: %d/3" % revealed_count

	# Hint label
	hint_label.visible = revealed_count > 0

	# Create Input Grid
	_create_input_grid()

	# Connect buttons
	submit_btn.pressed.connect(_on_submit)
	reset_btn.pressed.connect(_on_reset)
	close_btn.pressed.connect(_on_close)

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
	player_input[index] = buttons[index].button_pressed
	buttons[index].modulate = (
		Color(1.0, 0.84, 0.0) if buttons[index].button_pressed else Color.WHITE
	)

func _on_submit():
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
		btn.modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	for i in range(buttons.size()):
		buttons[i].modulate = Color(1.0, 0.84, 0.0) if player_input[i] else Color.WHITE

func _on_reset():
	for i in range(CELL_COUNT):
		player_input[i] = false
		buttons[i].button_pressed = false
		buttons[i].modulate = Color.WHITE

func _on_close():
	puzzle_failed.emit()
	GameData.is_popup_open = false
	queue_free()
