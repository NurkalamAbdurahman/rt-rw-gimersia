extends Control

@onready var bar = $"."

func _ready():
	bar.value = GameData.health
	GameData.connect("stats_updated", Callable(self, "_on_stats_updated"))

func _on_stats_updated():
	bar.value = GameData.health
