extends RefCounted
## D40: every sound and the music are synthesised here, at run time, from this project's
## own parameters and note lists: sine and triangle tones, simple envelopes and a
## deterministic noise generator of our own. No audio files, samples or packs. It never
## uses the town's random number generator and never touches the model.
const EFFECT_RATE: int = 22050
const MUSIC_RATE: int = 16000
const EFFECTS: Array[String] = ["build", "clear", "reject", "grow", "alert"]
## Music: 16 beats at 80 BPM (12 seconds), looped.
const BPM: float = 80.0
const BEATS: int = 16
## Chords for the pad, one per four beats (MIDI note numbers), written for this project.
const PAD: Array = [[60, 64, 67], [53, 60, 65, 69], [57, 60, 64], [55, 59, 62, 67]]
## Plucked melody: [beat, MIDI note, length in beats], written for this project.
const MELODY: Array = [[0.0, 76, 1.0], [1.5, 79, 0.5], [2.0, 81, 1.0], [3.0, 79, 1.0],
	[4.0, 77, 1.5], [5.5, 76, 0.5], [6.0, 72, 1.0], [7.0, 74, 1.0],
	[8.0, 72, 1.0], [9.0, 76, 0.5], [9.5, 79, 0.5], [10.0, 81, 1.0], [11.0, 79, 1.0],
	[12.0, 76, 1.0], [13.0, 74, 1.0], [14.0, 72, 2.0]]

static func midi_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)

static func _triangle(phase: float) -> float:
	var x: float = fposmod(phase, 1.0)
	return 4.0 * x - 1.0 if x < 0.5 else 3.0 - 4.0 * x

## Adds a tone with a short attack and an exponential decay into the buffer.
static func _tone(out: PackedFloat32Array, rate: int, start: float, length: float, hz: float, amp: float, triangle: bool, decay: float, attack: float = 0.006) -> void:
	var first: int = int(start * rate)
	var count: int = int(length * rate)
	for n in range(count):
		var i: int = first + n
		if i >= out.size(): break
		var t: float = float(n) / rate
		var env: float = minf(1.0, t / attack) * exp(-decay * t)
		# A short fade at the end so no tone stops with a click.
		env *= minf(1.0, (length - t) / 0.02)
		var phase: float = hz * t
		var wave: float = _triangle(phase) if triangle else sin(TAU * phase)
		out[i] += amp * env * wave

## Deterministic noise of our own (a 32-bit linear congruential sequence).
static func _noise(out: PackedFloat32Array, rate: int, length: float, amp: float, seed_value: int) -> void:
	var state: int = seed_value
	var low: float = 0.0
	var count: int = mini(out.size(), int(length * rate))
	for n in range(count):
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var white: float = float(state) / 0x3fffffff - 1.0
		low += 0.18 * (white - low)
		var t: float = float(n) / rate
		var env: float = minf(1.0, t / 0.01) * exp(-14.0 * t) * minf(1.0, (length - t) / 0.03)
		out[n] += amp * env * low

## Samples (-1..1) for one effect.
static func effect_samples(name: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var length: float = {"build": 0.22, "clear": 0.2, "reject": 0.2, "grow": 0.46, "alert": 0.62}.get(name, 0.0)
	out.resize(int(length * EFFECT_RATE))
	out.fill(0.0)
	match name:
		"build":
			_tone(out, EFFECT_RATE, 0.0, 0.13, midi_hz(76), 0.3, true, 18.0)
			_tone(out, EFFECT_RATE, 0.07, 0.15, midi_hz(81), 0.3, true, 16.0)
		"clear":
			_noise(out, EFFECT_RATE, 0.2, 0.9, 20261107)
		"reject":
			_tone(out, EFFECT_RATE, 0.0, 0.07, midi_hz(57), 0.35, false, 20.0)
			_tone(out, EFFECT_RATE, 0.1, 0.09, midi_hz(57), 0.3, false, 20.0)
		"grow":
			for k in range(3):
				_tone(out, EFFECT_RATE, 0.08 * k, 0.3, midi_hz([84, 88, 91][k]), 0.18, false, 9.0)
		"alert":
			for k in range(2):
				var hz: float = midi_hz([67, 74][k])
				_tone(out, EFFECT_RATE, 0.22 * k, 0.4, hz, 0.22, false, 6.0, 0.01)
				_tone(out, EFFECT_RATE, 0.22 * k, 0.4, hz * 2.0, 0.06, false, 9.0, 0.01)
	return out

## Samples (-1..1) for the whole music loop.
static func music_samples() -> PackedFloat32Array:
	var beat: float = 60.0 / BPM
	var out := PackedFloat32Array()
	out.resize(int(BEATS * beat * MUSIC_RATE))
	out.fill(0.0)
	for c in range(PAD.size()):
		var start: int = int(4 * c * beat * MUSIC_RATE)
		var count: int = int(4 * beat * MUSIC_RATE)
		var notes: Array = PAD[c]
		for n in range(count):
			var t: float = float(n) / MUSIC_RATE
			# Slow swell in and out across the chord, so chords join without clicks.
			var env: float = minf(1.0, t / 0.6) * minf(1.0, (4 * beat - t) / 0.6)
			var value: float = 0.0
			for note in notes: value += sin(TAU * midi_hz(note) * t)
			out[start + n] += 0.05 * env * value
	for entry in MELODY:
		_tone(out, MUSIC_RATE, float(entry[0]) * beat, float(entry[2]) * beat, midi_hz(entry[1]), 0.16, true, 2.2, 0.01)
	return out

static func peak(samples: PackedFloat32Array) -> float:
	var top: float = 0.0
	for v in samples: top = maxf(top, absf(v))
	return top

static func to_wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
