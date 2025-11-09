extends Control

@onready var health: Control = $"."

var heart_images = [
	preload("res://Assets/collecitions/Health/Cuore1.png"),
	preload("res://Assets/collecitions/Health/Cuore2.png"),
	preload("res://Assets/collecitions/Health/Cuore3.png"),
	preload("res://Assets/collecitions/Health/Cuore4.png"),
	preload("res://Assets/collecitions/Health/Cuore5.png"),
	preload("res://Assets/collecitions/Health/Cuore6.png"),	
]

func _ready():
	_update_hearts()
	GameData.connect("stats_updated", Callable(self, "_on_stats_updated"))

func _on_stats_updated():
	_update_hearts()

func _update_hearts():
	# hapus gambar hati lama
	for child in health.get_children():
		child.queue_free()

	# pastikan health minimal 1 agar tidak error
	var current_health = clamp(GameData.health, 1, heart_images.size())

	# tampilkan gambar sesuai health
	for i in range(current_health):
		var heart = TextureRect.new()

		# pastikan index tidak melebihi jumlah gambar
		if i < heart_images.size():
			heart.texture = heart_images[i]
		else:
			# kalau health lebih dari jumlah gambar (misal max 6)
			heart.texture = heart_images[-1]  # pakai gambar terakhir

		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		health.add_child(heart)
