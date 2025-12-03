extends Node

var steps = []
var current_step_index := 0

func _ready():
	steps = get_tree().get_nodes_in_group("tutorial_steps")
	steps.sort_custom(_sort_by_name)

	# Activate the first step
	if steps.size() > 0:
		steps[0].activate()
		steps[0].connect("step_completed", self._on_step_completed)

func _on_step_completed(step_id):
	print("Step selesai:", step_id)

	current_step_index += 1
	if current_step_index < steps.size():
		var next_step = steps[current_step_index]
		next_step.activate()
		next_step.connect("step_completed", self._on_step_completed)
	else:
		print("Semua tutorial selesai!")
		queue_free()

func _sort_by_name(a, b):
	return a.name < b.name
