extends Node2D

@onready var terkunci : Sprite2D = $Terkunci
@onready var area: Area2D = $Area2D
@onready var label: Label = $Label

# --- NODE TIMER ---
@onready var duration_timer: Timer = $DurationTimer # Timer untuk durasi muncul (20 detik)
@onready var wait_timer: Timer = $WaitTimer          # Timer untuk durasi hilang (5 detik)

var player_in_area = false
var is_door_visible = false
var chest_opened = false

func _ready():
	# PASTIKAN DI EDITOR, KEDUA TIMER DISETEL ONE-SHOT DAN AUTOSTART NONAKTIF
	
	label.visible = false
	
	# Sambungkan sinyal timer
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	
	# 1. ATUR KONDISI AWAL (Hilang/Disabled)
	set_door_visible(false)
	
	# 2. MULAI SIKLUS: Tunggu 5 detik sebelum muncul pertama kali
	print("[SYSTEM] Memulai siklus pintu...")
	wait_timer.start(5.0)

# --- FUNGSI UTAMA UNTUK MENGONTROL PINTU ---
func set_door_visible(visible_state: bool):
	is_door_visible = visible_state
	
	# Mengontrol Visibilitas
	terkunci.visible = visible_state
	
	# Mengontrol Interaksi/Collision (Area2D)
	area.monitoring = visible_state
	area.monitorable = visible_state
	
	# Pastikan label hilang jika pintu hilang
	if not visible_state:
		label.visible = false
		player_in_area = false
	
	# Debug Output yang Jelas
	print("--- Pintu Status: ", "MUNCUL (Durasi 20s)" if visible_state else "HILANG (Tunggu 5s)")

# --- 1. Pintu Muncul (20 Detik) Berakhir ---
func _on_duration_timer_timeout():
	print("[TIMER] 20 detik Durasi berakhir. Menghentikan DurationTimer.")
	duration_timer.stop() # Eksplisit stop (walaupun one-shot harusnya berhenti)
	
	# Pintu Hilang
	set_door_visible(false)
	
	# Mulai timer menunggu 5 detik
	print("[TIMER] Memulai WaitTimer (5 detik).")
	wait_timer.start(5.0)

# --- 2. Pintu Hilang (5 Detik) Berakhir ---
func _on_wait_timer_timeout():
	print("[TIMER] 5 detik Tunggu berakhir. Menghentikan WaitTimer.")
	wait_timer.stop() # Eksplisit stop
	
	# Pintu Muncul
	set_door_visible(true)
	
	# Mulai timer durasi muncul 20 detik
	print("[TIMER] Memulai DurationTimer (20 detik).")
	duration_timer.start(20.0)

# --- LOGIKA INTERAKSI (TIDAK ADA PERUBAHAN) ---
func _process(delta):
	if player_in_area and not chest_opened and is_door_visible: 
		if Input.is_action_just_pressed("e"):
			buka_pintu()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not chest_opened and is_door_visible: 
		player_in_area = true
		label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		label.visible = false

func buka_pintu():
	label.visible = false
	# Hentikan semua timer saat pintu dibuka
	duration_timer.stop()
	wait_timer.stop()
	print("[SISTEM] Pintu dibuka. Timer dihentikan.")
	GameData.next_spawn_location = "IRON_DOOR_EXIT"
	get_tree().change_scene_to_file("res://Scenes/maze-03.tscn")
