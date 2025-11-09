extends Control

@onready var icon = $Sprite2D
@onready var label = $Label

func _ready():
	# Set tampilan awal dari GameData
	_update_silver_key()

	# Dengarkan sinyal perubahan dari GameData
	GameData.stats_updated.connect(_on_stats_updated)

func _on_stats_updated():
	_update_silver_key()

func _update_silver_key():
	# Perbarui label jumlah
	label.text = str(GameData.silver_keys)

	# Ubah warna ikon berdasarkan jumlah kunci
	if GameData.silver_keys > 0:
		icon.modulate = Color(1, 1, 1, 1)  # terang (aktif)
	else:
		icon.modulate = Color(0.5, 0.5, 0.5, 0.7)  # gelap (belum punya)
