extends Node2D

@onready var tertutup = $silver_chest
@onready var animasi = $silver_chest_openanimation
@onready var terbuka = $silver_chest_open
@onready var area = $Area2D
@onready var label = $Label

var player_in_area = false
var chest_opened = false  # cek apakah chest sudah dibuka

func _ready():
	tertutup.visible = true
	terbuka.visible = false
	label.visible = false
	animasi.play("open")  # pastikan animasi default
	animasi.stop()        # hentikan supaya tidak looping

# Signal body entered
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened:
		player_in_area = true
		label.visible = true
		buka_chest()

# Signal body exited

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false
		# Fungsi buka chest
func buka_chest():
	chest_opened = true
	label.visible = false
	tertutup.visible = false
	terbuka.visible = true
	animasi.play("open")  # pastikan animasi hanya dimainkan sekali
