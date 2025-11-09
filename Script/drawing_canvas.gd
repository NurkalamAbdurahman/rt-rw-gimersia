extends Control

var drawing = false
var brush_color = Color.BLACK
var brush_size = 5
var points = []

func _ready():
	# Set ukuran 80% screen, centered
	set_anchors_preset(PRESET_CENTER)
	anchor_left = 0.1
	anchor_top = 0.1
	anchor_right = 0.9
	anchor_bottom = 0.9
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	print("DrawingCanvas ready!")

func _process(_delta):
	# Toggle dengan M
	if Input.is_action_just_pressed("map"):
		visible = !visible
		print("Canvas visible: ", visible)
		if visible:
			points.clear()
			queue_redraw()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
			if drawing:
				points.append(event.position)
				queue_redraw()
	
	elif event is InputEventMouseMotion:
		if drawing:
			points.append(event.position)
			queue_redraw()

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.9, 0.9, 1.0))
	
	# Draw border untuk keliatan batasnya
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, false, 2.0)
	
	# Draw lines (tanpa titik merah)
	if points.size() > 1:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], brush_color, brush_size, true)
