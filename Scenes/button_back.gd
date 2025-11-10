extends Button

func _on_Button_Back_pressed():
	var editor_ui = get_node_or_null("../../MapEditorUI")
	if editor_ui:
		editor_ui.close()
	else:
		push_error("❌ MapEditorUI not found!")
