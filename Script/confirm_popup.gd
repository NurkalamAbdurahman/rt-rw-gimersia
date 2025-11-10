extends CanvasLayer

@onready var control: Control = $Control
@onready var label: Label = $Control/Panel/MarginContainer/VBoxContainer/Label
@onready var no: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/no
@onready var yes: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/yes

signal confirmed
signal cancelled

var _tween: Tween

func _ready():
	hide()
	label.text = "Are you sure?"
	yes.text = "Confirm"
	no.text = "Cancel"
	yes.pressed.connect(_on_confirm_pressed)
	no.pressed.connect(_on_cancel_pressed)

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
	_tween.finished.connect(func(): queue_free())  # PAKAI queue_free() seperti shop!
