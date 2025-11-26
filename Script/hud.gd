extends CanvasLayer

@onready var strength_potion: Control = $MarginContainer4/HBoxContainer/StrengthPotion
@onready var speed_potion: Control = $MarginContainer4/HBoxContainer/SpeedPotion
@onready var buff_strength: Control = $MarginContainer3/VBoxContainer/BuffStrength
@onready var buff_speed: Control = $MarginContainer3/VBoxContainer/BuffSpeed
@onready var timer_lambat: AudioStreamPlayer = $TimerLambat
@onready var log_container: VBoxContainer = $MarginContainer2/Log

var last_strength := -1
var last_speed := -1
var timer_sfx_playing := false

# Track last known values for logging
var last_coins := 0
var last_silver_keys := 0
var last_golden_keys := 0
var last_skull_keys := 0

func _ready() -> void:
	for control in [strength_potion, speed_potion, buff_strength, buff_speed]:
		control.visible = false
		control.modulate.a = 0.0
	
	# Initialize last known values
	GameData.item_changed.connect(_on_item_changed)
	last_coins = GameData.coins
	last_silver_keys = GameData.silver_keys
	last_golden_keys = GameData.golden_keys
	last_skull_keys = GameData.skull_keys

func _on_item_changed(item_type: String, amount: int) -> void:
	_add_log_entry(item_type, amount)

func _process(_delta: float) -> void:
	_check_potion_changes()
	_update_buff_visibility()
	_check_item_changes()

func _check_item_changes() -> void:
	# Check coins
	if GameData.coins != last_coins:
		var diff = GameData.coins - last_coins
		if diff > 0:
			_add_log_entry("coin", diff)
		last_coins = GameData.coins
	
	# Check silver keys
	if GameData.silver_keys != last_silver_keys:
		var diff = GameData.silver_keys - last_silver_keys
		if diff > 0:
			_add_log_entry("silver_key", diff)
		last_silver_keys = GameData.silver_keys
	
	# Check golden keys
	if GameData.golden_keys != last_golden_keys:
		var diff = GameData.golden_keys - last_golden_keys
		if diff > 0:
			_add_log_entry("golden_key", diff)
		last_golden_keys = GameData.golden_keys
	
	# Check skull keys
	if GameData.skull_keys != last_skull_keys:
		var diff = GameData.skull_keys - last_skull_keys
		if diff > 0:
			_add_log_entry("skull_key", diff)
		last_skull_keys = GameData.skull_keys

func _add_log_entry(item_type: String, amount: int) -> void:
	# Create log entry container
	var entry = HBoxContainer.new()
	entry.modulate.a = 0.0
	
	# Create icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Set the appropriate texture based on item type
	match item_type:
		"coin":
			icon.texture = preload("res://Assets/collecitions/Coin/Coin.png")
		"silver_key":
			icon.texture = preload("res://Assets/collecitions/Silver_Key/Silver_Key.png")
		"golden_key":
			icon.texture = preload("res://Assets/collecitions/Golden_Key/Golden_Key.png")
		"skull_key":
			icon.texture = preload("res://Assets/collecitions/skull_key/Skull_Key.png")
		"hp_potion":
			icon.texture = preload("res://Assets/collecitions/Potion/HP_Potion.png")
		"speed_potion":
			icon.texture = preload("res://Assets/collecitions/Potion/Speed_Potion.png")
		"strength_potion":
			icon.texture = preload("res://Assets/collecitions/Potion/strength_Potion.png")

	# Create label
	var label = Label.new()
	label.text = ("%+d" % amount)
	var settings = LabelSettings.new()
	settings.font = load("res://Assets/Font/Pixels.ttf") 
	settings.font_size = 48
	settings.shadow_size = 0 
	settings.shadow_color = Color.BLACK
	settings.shadow_offset = Vector2(2, 2)
	label.label_settings = settings
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Add to container
	entry.add_child(icon)
	entry.add_child(label)
	log_container.add_child(entry)
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(entry, "modulate:a", 1.0, 0.3)
	
	# Auto-remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	# Fade out animation
	var fade_out = create_tween()
	fade_out.tween_property(entry, "modulate:a", 0.0, 0.5)
	await fade_out.finished
	
	entry.queue_free()

func _check_potion_changes() -> void:
	if GameData.strength_potion != last_strength:
		_update_potion_ui(strength_potion, GameData.strength_potion > 0)
		last_strength = GameData.strength_potion
		
	if GameData.speed_potion != last_speed:
		_update_potion_ui(speed_potion, GameData.speed_potion > 0)
		last_speed = GameData.speed_potion

func _update_potion_ui(potion: Control, show: bool) -> void:
	if show:
		potion.visible = true
		_fade(potion, 1.0)
	else:
		_fade(potion, 0.0)
		await get_tree().create_timer(0.25).timeout
		potion.visible = false

func _update_buff_visibility() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	_update_buff_container(buff_strength, player.strength_buff_active)
	_update_buff_container(buff_speed, player.speed_buff_active)
	_handle_timer_warning(player)

func _update_buff_container(container: Control, is_active: bool) -> void:
	if is_active:
		if not container.visible:
			container.visible = true
			_fade(container, 1.0)
	else:
		if container.visible:
			_fade(container, 0.0)
			await get_tree().create_timer(0.25).timeout
			container.visible = false

func _handle_timer_warning(player) -> void:
	var min_time = min(player.strength_buff_time if player.strength_buff_active else INF,
					   player.speed_buff_time if player.speed_buff_active else INF)
	
	if min_time <= 10.0 and not timer_sfx_playing:
		timer_lambat.play()
		timer_sfx_playing = true
	elif min_time > 10.0 and timer_sfx_playing:
		timer_lambat.stop()
		timer_sfx_playing = false

func _fade(control: Control, to_alpha: float, duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", to_alpha, duration)
