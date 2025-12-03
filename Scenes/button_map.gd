extends Button

@onready var map_editor_ui: Control = get_node("/root/Node2D/MapEditorLayer/MapEditorUI")  # Use absolute path

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))
	# Remove set_process(true) - we don't need _process anymore

# Remove the entire _process function - it's causing the conflict

func _on_pressed():
	if map_editor_ui:
		if map_editor_ui.visible:
			map_editor_ui.close()
		else:
			map_editor_ui.open()
	else:
		print("❌ MapEditorUI not found!")
