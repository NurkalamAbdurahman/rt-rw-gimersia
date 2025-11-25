extends CanvasLayer

@onready var bat = $Control/AnimatedSprite2D

func _ready():
	bat.play("default")
	var tween = create_tween()

	# posisi awal (di luar layar atas)
	bat.position = Vector2(get_viewport().size.x/2, -100)

	# kelelawar terbang menuju tengah layar
	tween.tween_property(
		bat, "position",
		Vector2(get_viewport().size.x/2, get_viewport().size.y/2),
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# delay sedikit lalu hilang
	tween.tween_interval(0.3)
	tween.tween_callback(Callable(self, "_finish"))
	

func _finish():
	queue_free()
