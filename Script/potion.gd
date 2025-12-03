extends Control

@onready var label: Label = $Label

func _process(delta: float) -> void:
	# Update label jadi jumlah potion
	label.text = str(GameData.potion)

	# Tekan P untuk minum potion
	if Input.is_action_just_pressed("ui_potion"): 
		if GameData.use_potion():
			print("darah nambah")
		else:
			print("nggak bisa minum potion (habis atau darah penuh)")
