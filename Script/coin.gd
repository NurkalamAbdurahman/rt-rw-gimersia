extends Control

@onready var label = $Label

func _ready():
	# Set awal dari GameData
	label.text = str(GameData.coins)
	
	# Dengarkan sinyal global untuk update otomatis
	GameData.stats_updated.connect(_on_stats_updated)

func _on_stats_updated():
	# Setiap kali GameData berubah, update teks label
	label.text = str(GameData.coins)
