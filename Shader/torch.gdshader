shader_type canvas_item;

uniform float radius = 0.5; // Radius maksimum cahaya (0.0 - 1.0)
uniform float intensity = 2.0;
uniform vec4 light_color : hint_color;

void fragment() {
	// Jarak dari pusat Light2D (0.5, 0.5)
	vec2 pos = LIGHT_UV - vec2(0.5);
	float dist = length(pos);

	// Hitung faktor redaman (attenuation)
	// Menggunakan pemudaran halus (smoothstep) untuk batas yang tajam (pixel art look)
	// Aturan: Semakin jauh, semakin gelap.
	float attenuation = 1.0 - smoothstep(radius * 0.8, radius, dist);
	
	// Memberikan sedikit flicker/kebisingan untuk efek api obor (opsional)
	// Jika Anda ingin efek dinamis, Anda bisa mengirimkan waktu (TIME) sebagai uniform.
	// Contoh: float flicker = sin(TIME * 10.0) * 0.05 + 0.95;
	// attenuation *= flicker;

	// Terapkan warna dan intensitas
	COLOR = light_color;
	COLOR.a = attenuation * intensity;
}
