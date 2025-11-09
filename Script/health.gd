extends Control

@onready var hearts_container = $HeartsContainer

func _ready():
	_update_hearts()
	GameData.connect("stats_updated", Callable(self, "_on_stats_updated"))

func _on_stats_updated():
	_update_hearts()

func _update_hearts():
	var current_health = clamp(GameData.health, 1, hearts_container.get_child_count())

	for i in range(hearts_container.get_child_count()):
		var heart = hearts_container.get_child(i)
		if i < current_health:
			heart.visible = true
		else:
			heart.visible = false
