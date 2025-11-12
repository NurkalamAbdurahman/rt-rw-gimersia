extends Control

@onready var icon = $Sprite2D

func _ready():
	# Set tampilan awal berdasarkan status GameData
	_update_key_icon()
	# Sambungkan sinyal agar update otomatis
	GameData.stats_updated.connect(_on_stats_updated)

func _on_stats_updated():
	_update_key_icon()

func _update_key_icon():
	# Jika punya minimal 1 golden key, tampilkan terang
	if GameData.skull_keys > 0:
		icon.modulate = Color(1, 1, 1, 1)
	else:
		icon.modulate = Color(0.5, 0.5, 0.5, 0.7)
