extends Node

signal stats_updated

var health: int = 6
var max_health: int = 6
var coins: int = 0
var silver_keys: int = 0
var golden_keys: int = 0
var skull_keys: int = 1
var pity: int = 0
var max_pity: int = 3
var potion: int = 0
var chest_states = {}
var torch_states = {}
var enemy_states = {}
var next_spawn_location: String = ""
var has_dead: bool = false
var is_popup_open: bool = false
var saved_strokes: Array = []
var saved_brush_color: Color = Color.BLACK
var saved_brush_size: float = 2.0

# Fungsi untuk menyimpan data yang dikirim dari Node2D gambar
func save_drawing_data(strokes_to_save: Array, color: Color, size: float):
	saved_strokes = strokes_to_save.duplicate(true) # Penting: Gunakan duplicate(true)
	saved_brush_color = color
	saved_brush_size = size

# Fungsi untuk mengambil data saat Node2D gambar dimuat
func load_drawing_data() -> Dictionary:
	return {
		"strokes": saved_strokes.duplicate(true),
		"color": saved_brush_color,
		"size": saved_brush_size
	}

func clear_data():
	saved_strokes.clear()
	saved_brush_color = Color.BLACK
	saved_brush_size = 2.0

func set_enemy_killed(enemy_id: String):
	enemy_states[enemy_id] = true
	print("STATUS PERSISTED: Enemy ", enemy_id, " sudah mati.")

# Fungsi untuk mengecek apakah enemy sudah mati sebelumnya
func is_enemy_killed(enemy_id: String) -> bool:
	return enemy_states.get(enemy_id, false) # Defaultnya false (belum mati)

func set_chest_opened(chest_id: String):
	chest_states[chest_id] = true
	print("STATUS PERSISTED: Chest ", chest_id, " sudah dibuka.")
# Fungsi untuk mengecek apakah chest sudah dibuka sebelumnya
func is_chest_opened(chest_id: String) -> bool:
	return chest_states.get(chest_id, false)
	
func set_torch_lighted(torch_id: String):
	torch_states[torch_id] = true
	print("STATUS PERSISTED: Torch ", torch_id, " sudah dinyalakan.")

func is_torch_lighted(torch_id: String) -> bool:
	return torch_states.get(torch_id, false)


func set_health(value: int):
	health = clamp(value, 0, 100)
	emit_signal("stats_updated")

func add_coin(amount: int = 1):
	coins += amount
	emit_signal("stats_updated")

func add_potion(amount: int = 1):
	potion += amount
	health += 1
	emit_signal("stats_updated")

func check_if_max_health():
	if health >= max_health:
		health = 6
		print("true")
		print(health)
		emit_signal("stats_updated")

func add_golden_key(amount: int = 1):
	golden_keys += amount
	emit_signal("stats_updated")
	
func add_skull_key(amount: int = 1):
	skull_keys += amount
	emit_signal("stats_updated")
	
func add_silver_key(amount: int = 1):
	silver_keys += amount
	emit_signal("stats_updated")

func add_pity(amount: int) :
	pity += amount
	print(pity)
	emit_signal("stats_updated")

func set_death(bool):
	has_dead = true
	

func set_not_death(bool):
	has_dead = false

func reset() :
	health = max_health
	coins = 0
	silver_keys = 0
	golden_keys = 0
	skull_keys = 0
	pity = 0
	chest_states = {}
	torch_states = {}
	enemy_states = {}
