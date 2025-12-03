extends Area2D

# Array berisi teks yang akan ditampilkan secara berurutan
const DIALOG_TEXTS = [
	"Light the torch to start",
]
@onready var static_body_2d: StaticBody2D = $"../tutorial_welcome/StaticBody2D"

# Path ke node Label pada Player (PASTIKAN INI BENAR)
@onready var player_label: Label = $"../Hud/Label"
@onready var player_2: CharacterBody2D = $"../Player2"
@onready var suara_typing: AudioStreamPlayer2D = $"../Suara_Typing"
@onready var obor_26: Node2D = $"../SceneObor/Obor26"


# Status untuk memastikan trigger hanya terjadi sekali
var triggered_once: bool = false
# Index untuk melacak teks mana yang sedang ditampilkan
var current_text_index: int = 0
# Timer untuk mengontrol kecepatan pengetikan
var type_timer = Timer.new()
# Timer untuk mengontrol jeda sebelum fade out
var delay_timer = Timer.new()

# Index huruf yang sedang ditampilkan untuk animasi typing
var char_index: int = 0 


func _ready():
	# Setup Timer untuk pengetikan
	add_child(type_timer)
	type_timer.one_shot = true
	type_timer.connect("timeout", _on_type_timer_timeout)
	
	# Setup Timer untuk jeda
	add_child(delay_timer)
	delay_timer.one_shot = true
	delay_timer.connect("timeout", _on_delay_timer_timeout)
	
	# Inisialisasi Label agar tidak terlihat di awal (alpha = 0)
	player_label.text = ""
	player_label.self_modulate = Color(1,1,1,0)
	obor_26.connect("torch_lit", Callable(self, "_on_torch_lit"))



# ----------------------------------------------------------------------
# ➡️ FUNGSI UTAMA TRIGGER
# ----------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	player_label.show()
	player_label.visible = true
	# 1. Pastikan yang masuk adalah Player dan belum pernah ter-trigger
	if body.name == "Player2" and not triggered_once:
		triggered_once = true # Kunci agar tidak ter-trigger lagi
		# 2. Mulai menampilkan teks pertama
		show_next_dialog()


# ----------------------------------------------------------------------
# 💬 FUNGSI PENAMPILAN TEKS (MENGATUR FADE IN/OUT)
# ----------------------------------------------------------------------

func _on_torch_lit():
	stop_dialog_and_cleanup()

func stop_dialog_and_cleanup():
	# Hentikan semua proses
	type_timer.stop()
	delay_timer.stop()

	if suara_typing.playing:
		suara_typing.stop()

	# Langsung hilangkan label
	player_label.text = ""
	player_label.modulate.a = 0

	_clean_up()


func show_next_dialog():
	if current_text_index < DIALOG_TEXTS.size():
		# Reset Label dan buat muncul (fade in)
		player_label.text = ""
		var fade_in_tween = create_tween()
		# Fade in cepat: 0.3 detik
		fade_in_tween.tween_property(player_label, "self_modulate:a", 1.0, 0.3)
		
		# Mulai animasi pengetikan setelah fade in selesai
		fade_in_tween.tween_callback(Callable(self, "_start_typing"))
	else:
		# Semua dialog sudah ditampilkan, hilangkan Label secara total
		var full_fade_out_tween = create_tween()
		# Full Fade out cepat: 0.5 detik
		full_fade_out_tween.tween_property(player_label, "modulate:a", 0.0, 0.5) 
		#full_fade_out_tween.tween_callback(Callable(self, "_clean_up"))


# ----------------------------------------------------------------------
# ⌨️ FUNGSI ANIMASI PENGETIKAN
# ----------------------------------------------------------------------

func _start_typing():
	suara_typing.play()
	print("LABEL ALPHA:", player_label.self_modulate.a)
	print("LABEL COLOR:", player_label.get_theme_color("font_color", "Label"))
	print("LABEL GLOBAL VISIBLE:", player_label.is_visible_in_tree())

	var current_text = DIALOG_TEXTS[current_text_index]
	# Atur kecepatan pengetikan: 0.05 detik per huruf
	type_timer.start(0.05) 

func _on_type_timer_timeout():
	var current_text = DIALOG_TEXTS[current_text_index]
	
	if char_index < current_text.length():
		# Tambahkan satu huruf ke Label
		player_label.text += current_text[char_index]
		char_index += 1
		# Lanjutkan timer untuk huruf selanjutnya
		type_timer.start(0.05)
	else:
		# Pengetikan selesai, reset index huruf
		char_index = 0
		# Jeda lebih cepat: 1.5 detik sebelum teks fade out
		#delay_timer.start(2)


# ----------------------------------------------------------------------
# 🔄 FUNGSI FADE OUT DAN PINDAH KE TEKS BERIKUTNYA
# ----------------------------------------------------------------------

func _on_delay_timer_timeout():
	suara_typing.stop()
	# Mulai fade out
	var fade_out_tween = create_tween()
	# Fade out cepat: 0.5 detik
	fade_out_tween.tween_property(player_label, "modulate:a", 0.0, 0.5)
	
	# Setelah fade out selesai, pindah ke teks berikutnya
	current_text_index += 1
	fade_out_tween.tween_callback(Callable(self, "show_next_dialog"))


# ----------------------------------------------------------------------
# 🧹 FUNGSI MEMBERSIHKAN
# ----------------------------------------------------------------------

func _clean_up():
	player_label.text = ""
	# Tambahkan kode di sini jika Anda ingin Area2D ini dihapus 
	# setelah semua dialog selesai:
	queue_free()
