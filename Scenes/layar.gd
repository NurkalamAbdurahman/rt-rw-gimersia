extends CanvasLayer

# ====================== NODE REFERENCES ======================
@onready var start_game: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var control_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Control
@onready var exit_controls_btn: Button = $Control/Panel/HBoxContainer/exit  # tombol exit panel controls
@onready var controls_menu: Control = $Control  # panel controls

# ====================== READY ======================
func _ready():
	# Hubungkan tombol langsung
	start_game.pressed.connect(_on_start_pressed)
	control_button.pressed.connect(_on_control_pressed)
	exit_controls_btn.pressed.connect(_on_exit_pressed)

	# Awal: panel controls tersembunyi
	controls_menu.visible = false

# ====================== BUTTON FUNCTIONS ======================s
func _on_start_pressed() -> void:
	start_game.disabled = true
	
	# Muat scene transisi secara dinamis
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
		# Jalankan fade-out dulu, baru pindah ke stage1ss
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")

func _on_control_pressed() -> void:
	# Buka panel controls
	controls_menu.visible = true

func _on_exit_pressed() -> void:	
	# Tutup panel controls
	controls_menu.visible = false
