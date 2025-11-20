extends Node2D

# Drawing data
var strokes: Array = [] # Completed strokes
var drawing := false    # Mouse drawing status
var current_stroke: Array = [] # Current mouse stroke being drawn

# Brush settings
var brush_color := Color.BLACK
var brush_size := 2.0

# Player tracking settings
var record_player_path := true
var player_stroke: Array = []
var player_color := Color.DARK_SLATE_GRAY
var player_line_width := 3.0

# Tracking settings
enum TrackingMode { CANVAS_CENTER, CUSTOM_POINT, PLAYER_POSITION }
var tracking_mode: TrackingMode = TrackingMode.CANVAS_CENTER
var custom_tracking_point := Vector2.ZERO
var tracking_offset := Vector2.ZERO

# References
@onready var player: CharacterBody2D = $"../../../Player2"
@onready var color_rect: TextureRect = $"../ColorRect"
var canvas_size: Vector2

# Color palette for quick access
var color_palette := [
	Color.BLACK,
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE,
	Color.CYAN,
	Color.MAGENTA,
	Color.WHITE
]

func _ready():
	canvas_size = color_rect.size
	GameData.connect("drawing_cleared", Callable(self, "_on_drawing_cleared"))
	# Load saved data
	if GameData.saved_strokes.size() > 0:
		var loaded_data = GameData.load_drawing_data()
		strokes = loaded_data.strokes
		brush_color = loaded_data.color
		brush_size = loaded_data.size
		print("Drawing data loaded!")
	
	# Initialize canvas
	if color_rect and is_instance_valid(color_rect):
		canvas_size = Vector2(669, 321)
		print("Canvas Size set from ColorRect:", canvas_size)
	else:
		canvas_size = Vector2(669, 321)
		print("Canvas Size set to fallback:", canvas_size)
	
	# Calculate initial tracking offset
	update_tracking_offset()
	
	# Enable drawing
	set_drawing_enabled(true)
	set_process(true)
	
	# Initialize player stroke
	if record_player_path:
		player_stroke = []
		player_stroke.append(world_to_map(player.global_position))
	
	queue_redraw()

func _on_drawing_cleared():
	clear_all_strokes()

func set_drawing_enabled(enabled: bool):
	set_process_input(enabled)

func _input(event):
	# Mouse drawing
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		if event.pressed:
			if _is_inside_canvas(mouse_pos):
				drawing = true
				current_stroke = []
				current_stroke.append(to_local(mouse_pos))
		else:
			drawing = false
			if current_stroke.size() > 0:
				strokes.append({
					"points": current_stroke,
					"color": brush_color,
					"width": brush_size
				})
				current_stroke = []
				queue_redraw()
	
	elif event is InputEventMouseMotion and drawing:
		var mouse_pos = event.position
		if _is_inside_canvas(mouse_pos):
			current_stroke.append(to_local(mouse_pos))
			queue_redraw()
	
	# Keyboard shortcuts for colors (1-9 keys + 0)
	elif event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index = event.keycode - KEY_1
			if index < color_palette.size():
				brush_color = color_palette[index]
				print("Brush color changed to:", brush_color)
		elif event.keycode == KEY_0:
			if color_palette.size() > 9:
				brush_color = color_palette[9]
				print("Brush color changed to:", brush_color)
		
		# Brush size controls
		elif event.keycode == KEY_BRACKETLEFT: # [
			brush_size = max(1.0, brush_size - 1.0)
			print("Brush size:", brush_size)
		elif event.keycode == KEY_BRACKETRIGHT: # ]
			brush_size = min(10.0, brush_size + 1.0)
			print("Brush size:", brush_size)
		
		# Tracking mode controls
		elif event.keycode == KEY_T:
			cycle_tracking_mode()

func _process(delta):
	if record_player_path:
		player_stroke.append(world_to_map(player.global_position))
		queue_redraw()

func _draw():
	# Draw current player position
	var player_pos = world_to_map(player.global_position)
	draw_circle(player_pos, 4, Color.RED)
	
	# Draw saved strokes (with their individual colors)
	for stroke_data in strokes:
		if typeof(stroke_data) == TYPE_DICTIONARY:
			var points = stroke_data.points
			var color = stroke_data.get("color", Color.BLACK)
			var width = stroke_data.get("width", 2.0)
			
			if points.size() > 1:
				for i in range(points.size() - 1):
					draw_line(points[i], points[i + 1], color, width, true)
		else:
			# Legacy support for old stroke format
			if stroke_data.size() > 1:
				for i in range(stroke_data.size() - 1):
					draw_line(stroke_data[i], stroke_data[i + 1], brush_color, brush_size, true)
	
	# Draw current stroke being drawn
	if current_stroke.size() > 1:
		for i in range(current_stroke.size() - 1):
			draw_line(current_stroke[i], current_stroke[i + 1], brush_color, brush_size, true)
	
	# Draw player path with gradient effect
	if player_stroke.size() > 1:
		for i in range(player_stroke.size() - 1):
			var alpha = float(i) / player_stroke.size() # Fade older parts
			var color = player_color
			color.a = lerp(0.3, 1.0, alpha)
			draw_line(player_stroke[i], player_stroke[i + 1], color, player_line_width, true)

func world_to_map(world_pos: Vector2) -> Vector2:
	var scale := 0.1
	var center := get_tracking_center()
	return ((world_pos - tracking_offset) * scale) + center

func get_tracking_center() -> Vector2:
	match tracking_mode:
		TrackingMode.CANVAS_CENTER:
			return canvas_size / 2
		TrackingMode.CUSTOM_POINT:
			return custom_tracking_point
		TrackingMode.PLAYER_POSITION:
			return canvas_size / 2 # Player stays centered
		_:
			return canvas_size / 2

func update_tracking_offset():
	match tracking_mode:
		TrackingMode.CANVAS_CENTER:
			tracking_offset = Vector2.ZERO
		TrackingMode.CUSTOM_POINT:
			tracking_offset = Vector2.ZERO
		TrackingMode.PLAYER_POSITION:
			tracking_offset = player.global_position

func cycle_tracking_mode():
	tracking_mode = (tracking_mode + 1) % 3
	update_tracking_offset()
	
	match tracking_mode:
		TrackingMode.CANVAS_CENTER:
			print("Tracking mode: Canvas Center")
		TrackingMode.CUSTOM_POINT:
			print("Tracking mode: Custom Point")
		TrackingMode.PLAYER_POSITION:
			print("Tracking mode: Player Position (follows player)")
	
	queue_redraw()

func set_tracking_mode(mode: TrackingMode):
	tracking_mode = mode
	update_tracking_offset()
	queue_redraw()

func set_custom_tracking_point(point: Vector2):
	custom_tracking_point = point
	if tracking_mode == TrackingMode.CUSTOM_POINT:
		queue_redraw()

func set_brush_color(color: Color):
	brush_color = color

func set_brush_size(size: float):
	brush_size = clamp(size, 1.0, 20.0)

func set_player_color(color: Color):
	player_color = color
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		if not GameData.is_scene_changing:
			# Add player stroke to strokes before saving
			if player_stroke.size() > 1:
				strokes.append({
					"points": player_stroke,
					"color": player_color,
					"width": player_line_width
				})
			GameData.save_drawing_data(strokes, brush_color, brush_size)
			print("Drawing data saved!")

func _is_inside_canvas(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	return (local_pos.x >= 0 and local_pos.x <= canvas_size.x
			and local_pos.y >= 0 and local_pos.y <= canvas_size.y)

func undo_last_stroke():
	if strokes.size() > 0:
		strokes.pop_back()
		queue_redraw()

func clear_all_strokes():
	strokes.clear()
	player_stroke.clear()
	queue_redraw()

func clear_player_path():
	player_stroke.clear()
	queue_redraw()
