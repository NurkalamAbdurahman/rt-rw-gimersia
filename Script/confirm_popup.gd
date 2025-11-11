extends CanvasLayer

@onready var control: Control = $Control
@onready var label: Label = $Control/Panel/MarginContainer/VBoxContainer/Label
@onready var no: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/no
@onready var yes: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/yes

signal confirmed
signal cancelled

var _tween: Tween
var buttons: Array[Button] = []     # ← Array tombol navigasi
var selected_index: int = 0         # ← Indeks tombol yang sedang dipilih

func _ready():
	hide()
	label.text = "Are you sure?"
	yes.text = "Confirm"
	no.text = "Cancel"
	
	buttons = [yes, no]  # ← Tambahkan tombol ke array
	
	yes.pressed.connect(_on_confirm_pressed)
	no.pressed.connect(_on_cancel_pressed)
	
	_update_button_focus()

func show_popup(message: String = "Are you sure?"):
	label.text = message
	show()
	
	if _tween and _tween.is_running():
		_tween.kill()
	
	control.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 1.0, 0.2)

func _on_confirm_pressed():
	confirmed.emit()
	hide_popup()

func _on_cancel_pressed():
	cancelled.emit()
	hide_popup()

func hide_popup():
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(control, "modulate:a", 0.0, 0.2)
	_tween.finished.connect(func(): queue_free())

func _process(delta):
	if not visible:
		return
	
	if Input.is_action_just_pressed("menu_right"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("menu_left"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")

# 🌟 Efek visual tombol terpilih — warna + scale
func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]

		if i == selected_index:
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # teks emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) # teks abu-abu
			btn.scale = Vector2(1, 1)
