extends Node2D

var strokes: Array = [] # Data sapuan yang sudah selesai
var drawing := false    # Status apakah mouse sedang diklik
var current_stroke: Array = [] # Sapuan yang sedang dikerjakan
var brush_color := Color.BLACK
var brush_size := 2.0

# Asumsi: ColorRect adalah sibling dari Node2D ini.
@onready var color_rect: TextureRect = $"../ColorRect"
var canvas_size: Vector2

func _ready():
	# --- 1. Memuat Data dari Autoload ---
	if GameData.saved_strokes.size() > 0:
		var loaded_data = GameData.load_drawing_data()
		strokes = loaded_data.strokes
		brush_color = loaded_data.color
		brush_size = loaded_data.size
		print("Drawing data loaded!")
	# --- Akhir Pemuaatan ---
	
	# --- 2. Inisialisasi Kanvas ---
	if color_rect and is_instance_valid(color_rect):
		# Gunakan ukuran ColorRect yang sebenarnya
		# Kami menggunakan RectSize karena Node2D perlu tahu batas gambar
		canvas_size = Vector2(669, 321)
		print("Canvas Size set from ColorRect:", canvas_size)
	else:
		# Fallback ke ukuran yang Anda tentukan jika ColorRect tidak ditemukan
		canvas_size = Vector2(669, 321) 
		print("Canvas Size set to fallback:", canvas_size)
	
	# --- 3. Mengaktifkan Input ---
	# Kita aktifkan input langsung di sini agar bisa langsung menggambar
	set_drawing_enabled(true)
	
	# Panggil _draw()
	queue_redraw()

func set_drawing_enabled(enabled: bool):
	set_process_input(enabled)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		
		if event.pressed:
			if _is_inside_canvas(mouse_pos):
				drawing = true
				current_stroke = []
				# Simpan posisi lokal
				current_stroke.append(to_local(mouse_pos)) 
		else:
			drawing = false
			if current_stroke.size() > 0:
				# PENTING: Tambahkan current_stroke ke strokes hanya jika ada sapuan yang valid
				strokes.append(current_stroke)
				current_stroke = []
				queue_redraw()

	elif event is InputEventMouseMotion and drawing:
		var mouse_pos = event.position
		if _is_inside_canvas(mouse_pos):
			# Tambahkan titik berikutnya ke sapuan saat ini
			current_stroke.append(to_local(mouse_pos))
			queue_redraw()

func _draw():
	# 1. Gambar sapuan yang sudah selesai
	for stroke in strokes:
		if stroke.size() > 1:
			for i in range(stroke.size() - 1):
				# Kami asumsikan stroke sudah menyimpan Color dan Size
				# Jika Anda ingin menyimpan Color/Size per stroke, Anda harus mengubah 
				# struktur array 'strokes' menjadi array Dictionary.
				draw_line(stroke[i], stroke[i + 1], brush_color, brush_size, true)
				
	# 2. Gambar sapuan yang sedang berjalan
	if current_stroke.size() > 1:
		for i in range(current_stroke.size() - 1):
			draw_line(current_stroke[i], current_stroke[i + 1], brush_color, brush_size, true)


# 🟩 Deteksi apakah kursor masih di dalam area kanvas
func _is_inside_canvas(global_pos: Vector2) -> bool:
	# Transformasi posisi global (layar) ke posisi lokal (relatif terhadap Node2D ini)
	var local_pos = to_local(global_pos)
	
	# Asumsi: ColorRect berada pada posisi (0, 0) relatif terhadap Node2D ini.
	return (local_pos.x >= 0 and 
			local_pos.x <= canvas_size.x and 
			local_pos.y >= 0 and 
			local_pos.y <= canvas_size.y)


func undo_last_stroke():
	if strokes.size() > 0:
		strokes.pop_back()
		queue_redraw()

# Dipanggil saat scene ini akan diganti/dihapus (untuk menyimpan data)
func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		# Hanya simpan data jika tidak sedang pindah scene
		if not GameData.is_scene_changing:
			GameData.save_drawing_data(strokes, brush_color, brush_size)
			print("Drawing data saved!")
