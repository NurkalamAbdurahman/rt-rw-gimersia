extends Button

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))
	set_process(true) # agar _process dijalankan terus

func _process(_delta):
	# jika tombol M ditekan
	if Input.is_action_just_pressed("open_map"):
		_on_pressed()

func _on_pressed():
	var editor_ui = get_parent().get_node("../MapEditorLayer/MapEditorUI")
	if editor_ui:
		editor_ui.open()
	else:
		print("❌ MapEditorUI not found!")
