extends Node2D

var drawing := false
var strokes: Array = []
var current_stroke: Array = []
var brush_color := Color.BLACK
var brush_size := 2.0

@onready var color_rect := $"../ColorRect"  # ambil referensi ke kanvas putih
var canvas_size: Vector2

func _ready():
	set_process_input(false)
	queue_redraw()
	if color_rect:
		canvas_size = color_rect.size
	else:
		canvas_size = Vector2(400, 300)  # fallback kalau ColorRect tidak ditemukan

func set_drawing_enabled(enabled: bool):
	set_process_input(enabled)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_inside_canvas(event.position):
				drawing = true
				current_stroke = []
				current_stroke.append(to_local(event.position))
		else:
			drawing = false
			if current_stroke.size() > 0:
				strokes.append(current_stroke)
				current_stroke = []
				queue_redraw()

	elif event is InputEventMouseMotion and drawing:
		if _is_inside_canvas(event.position):
			current_stroke.append(to_local(event.position))
			queue_redraw()

func _draw():
	for stroke in strokes:
		if stroke.size() > 1:
			for i in range(stroke.size() - 1):
				draw_line(stroke[i], stroke[i + 1], brush_color, brush_size)
	if current_stroke.size() > 1:
		for i in range(current_stroke.size() - 1):
			draw_line(current_stroke[i], current_stroke[i + 1], brush_color, brush_size)

func undo_last_stroke():
	if strokes.size() > 0:
		strokes.pop_back()
		queue_redraw()

# 🟩 Deteksi apakah kursor masih di dalam area putih (ColorRect)
func _is_inside_canvas(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	return local_pos.x >= 0 and local_pos.x <= canvas_size.x and local_pos.y >= 0 and local_pos.y <= canvas_size.y
