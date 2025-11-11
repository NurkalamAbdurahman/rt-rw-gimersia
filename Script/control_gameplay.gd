extends Control

@onready var control: Control = $"."

func _ready() -> void:
	pass

func _on_gameplay_pressed() -> void:
	control.visible = false
	print("keluar")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if control.visible:
			control.visible = false
			return
