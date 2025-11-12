extends Node2D

# ⭐️ Perubahan di sini: Menggunakan $Player2 sesuai Scene Tree Anda
@onready var player_node = $Player2 

# KOORDINAT TARGET DI SCENE maze-01.tscn
# Ganti angka di bawah ini dengan koordinat X dan Y yang tepat di mana Anda ingin 
# karakter 'Player2' muncul saat keluar dari pintu besi.
const IRON_DOOR_SPAWN_POSITION = Vector2(1524, 59) 

func _ready():
	
	# 1. Periksa dari mana karakter datang (dari skrip Global.gd)
	if GameData.next_spawn_location == "IRON_DOOR_EXIT":
		
		# 2. Atur posisi karakter 'Player2' ke posisi yang telah ditentukan
		player_node.global_position = IRON_DOOR_SPAWN_POSITION
		print(IRON_DOOR_SPAWN_POSITION)
		print(GameData.next_spawn_location)
		# 3. Reset variabel global
		GameData.next_spawn_location = "" 
