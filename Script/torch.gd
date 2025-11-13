extends Area2D
#
## Signal yang akan dipancarkan ketika item diambil
#signal picked_up(item)
#
## Ketika node lain memasuki area (overlap)
#func _on_body_entered(body):
	## Cek apakah body yang masuk adalah pemain (CharacterBody2D).
	## Ganti 'CharacterBody2D' jika node pemain Anda menggunakan jenis node lain (misalnya RigidBody2D).
	#if body is CharacterBody2D:
		## Panggil fungsi untuk mengambil item
		#pick_up(body)
#
#func pick_up(player: CharacterBody2D):
	## *** LANGKAH PENTING UNTUK REPARENTING ***
	## 1. Lepaskan (remove) item ini dari induknya yang sekarang (misalnya: Main Scene/Level).
	## Ini harus dilakukan sebelum menambahkan item sebagai anak (child) dari node lain.
	#get_parent().remove_child(self)
	#
	## 2. Ubah induk item menjadi pemain (Reparenting).
	## Ini akan membuat item mengikuti pemain secara otomatis.
	#player.add_child(self)
	#
	## 3. Nonaktifkan CollisionShape agar tidak dapat diambil lagi/bertabrakan lagi.
	## set_deferred digunakan untuk memastikan Godot melakukannya dengan aman di akhir frame.
	#$CollisionShape2D.set_deferred("disabled", true)
	#
	## 4. Atur posisi item relatif terhadap pemain.
	## Ganti Vector2(0, -30) untuk menyesuaikan posisi obor agar terlihat di tangan/di atas pemain.
	#self.position = Vector2(0, -30) 
	#
	## 5. Memancarkan signal (Opsional, untuk logika Inventory/Game lainnya).
	#emit_signal("picked_up", self)
	#
	## 6. Hentikan pemrosesan script (opsional, jika tidak ada logika lain yang dibutuhkan)
	#set_process(false)
