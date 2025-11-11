extends Node2D # Root node dari maze-01.tscn

# ⭐️ Perubahan di sini: Menggunakan $Player2 sesuai Scene Tree Anda
@onready var player_node = $Player2 

# KOORDINAT TARGET DI SCENE maze-01.tscn
# Ganti angka di bawah ini dengan koordinat X dan Y yang tepat di mana Anda ingin 
# karakter 'Player2' muncul saat keluar dari pintu besi.
const IRON_DOOR_SPAWN_POSITION = Vector2(-1045, -254) 
@onready var tuta: Area2D = $tutorial_welcome
@onready var tutb: Area2D = $tutorial_interract
@onready var tutc: Area2D = $tutorial_goal
@onready var tutd: Area2D = $tutorial_chest

func _ready():
	
	# 1. Periksa dari mana karakter datang (dari skrip Global.gd)
	if GameData.next_spawn_location == "IRON_DOOR_EXIT":
		
		# 2. Atur posisi karakter 'Player2' ke posisi yang telah ditentukan
		player_node.global_position = IRON_DOOR_SPAWN_POSITION
		print(IRON_DOOR_SPAWN_POSITION)
		print(GameData.next_spawn_location)
		# 3. Reset variabel global
		GameData.next_spawn_location = "" 
		
	# Lanjutkan dengan kode _ready() lainnya (jika ada)
	if GameData.has_dead == true:
		tuta.queue_free()
		tutb.queue_free()
		tutc.queue_free()
		tutd.queue_free()
