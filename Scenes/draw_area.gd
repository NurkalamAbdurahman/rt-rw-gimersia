extends Node2D

# Drawing data
var strokes: Array = []
var drawing := false
var current_stroke: Array = []

# Brush settings
var brush_color := Color.BLACK
var brush_size := 2.0

# Player tracking settings
var record_player_path := true
var player_stroke: Array = []
var player_color := Color.DARK_SLATE_GRAY
var player_line_width := 4.0
var player_max_points := 500       # 🔥 Batasi jumlah titik agar tidak berat
var player_record_interval := 0.10 # 🔥 Hanya rekam 1 titik per 0.1 detik
var player_record_timer := 0.0

# Tracking settings
enum TrackingMode { CANVAS_CENTER, CUSTOM_POINT, PLAYER_POSITION }
var tracking_mode: TrackingMode = TrackingMode.CANVAS_CENTER
var custom_tracking_point := Vector2.ZERO
var tracking_offset := Vector2.ZERO

# References
@onready var player: CharacterBody2D = $"../../../Player2"
@onready var color_rect: TextureRect = $"../ColorRect"

var canvas_size: Vector2

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
	canvas_size = Vector2(669, 321)

	update_tracking_offset()
	set_process(true)

	# 🔥 Initialize player path — ALWAYS start fresh
	player_stroke.clear()
	if record_player_path:
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
				current_stroke = [to_local(mouse_pos)]
		else:
			if drawing and current_stroke.size() > 0:
				strokes.append({
					"points": current_stroke,
					"color": brush_color,
					"width": brush_size
				})
				queue_redraw()
			drawing = false

	elif event is InputEventMouseMotion and drawing:
		var mouse_pos = event.position
		if _is_inside_canvas(mouse_pos):
			current_stroke.append(to_local(mouse_pos))
			queue_redraw()


func _process(delta):
	if record_player_path:
		player_record_timer += delta
		if player_record_timer >= player_record_interval:
			player_record_timer = 0.0

			var mapped = world_to_map(player.global_position)
			player_stroke.append(mapped)

			# 🔥 Batasi jumlah titik agar tetap ringan
			#if player_stroke.size() > player_max_points:
				#player_stroke.pop_front()

			queue_redraw()


func _draw():
	# Draw saved strokes FIRST (behind everything)
	for stroke_data in strokes:
		var points = stroke_data.get("points", [])
		var color = stroke_data.get("color", Color.BLACK)
		var width = stroke_data.get("width", 2.0)

		if points.size() > 1:
			draw_polyline(points, color, width)

	# Draw current stroke being drawn
	if current_stroke.size() > 1:
		draw_polyline(current_stroke, brush_color, brush_size)

	# 🔥 Draw live player path (on top of saved strokes)
	if player_stroke.size() > 1:
		draw_polyline(player_stroke, player_color, player_line_width)

	# Player indicator (red circle) — ALWAYS ON TOP
	var player_pos = world_to_map(player.global_position)
	draw_circle(player_pos, 6, Color.RED)


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
			return canvas_size / 2
	return canvas_size / 2


func update_tracking_offset():
	if tracking_mode == TrackingMode.PLAYER_POSITION:
		tracking_offset = player.global_position
	else:
		tracking_offset = Vector2.ZERO


func cycle_tracking_mode():
	tracking_mode = (tracking_mode + 1) % 3
	update_tracking_offset()
	queue_redraw()


func set_brush_color(color: Color):
	brush_color = color


func set_brush_size(size: float):
	brush_size = clamp(size, 1.0, 20.0)


func clear_all_strokes():
	strokes.clear()
	player_stroke.clear()
	queue_redraw()


func undo_last_stroke():
	if strokes.size() > 0:
		strokes.pop_back()
		queue_redraw()


func _is_inside_canvas(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	return local_pos.x >= 0 and local_pos.x <= canvas_size.x and local_pos.y >= 0 and local_pos.y <= canvas_size.y


func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		if not GameData.is_scene_changing:

			# 🔥 Tambahkan player path ke strokes sebagai stroke terpisah
			if player_stroke.size() > 1:
				var path_copy := player_stroke.duplicate(true)
				strokes.append({
					"points": path_copy,
					"color": player_color,
					"width": player_line_width
				})

			# 🔥 Save semua strokes lengkap
			var strokes_copy := []
			for s in strokes:
				strokes_copy.append({
					"points": s.points.duplicate(true),
					"color": s.color,
					"width": s.width
				})

			GameData.save_drawing_data(strokes_copy, brush_color, brush_size)
			print("Drawing data saved!")
		
		# 🔥 ALWAYS clear player stroke when leaving scene
		player_stroke.clear()
