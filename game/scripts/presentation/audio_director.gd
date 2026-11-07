extends Node
## D40: owns the Effects and Music buses, the effect players and the background-made
## music loop. Presentation only: it never reads or changes the model.
const SoundKit = preload("res://scripts/presentation/sound_kit.gd")
const BUSES: Array[String] = ["Effects", "Music"]
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_stream: AudioStreamWAV
var music_thread: Thread
var volumes: Dictionary = {"master": 80, "effects": 70, "music": 30}
var muted: bool = false
## Last effect requested (for tests and logs) and how many have played.
var last_effect: String = ""
var effect_count: int = 0

func _ready() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	for name in SoundKit.EFFECTS:
		streams[name] = SoundKit.to_wav(SoundKit.effect_samples(name), SoundKit.EFFECT_RATE, false)
	# A few players so overlapping effects do not cut each other off.
	for n in range(4):
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	apply()
	# The music loop takes a moment to synthesise, so make it off the main thread.
	music_thread = Thread.new()
	music_thread.start(_make_music)

func _make_music() -> void:
	var stream: AudioStreamWAV = SoundKit.to_wav(SoundKit.music_samples(), SoundKit.MUSIC_RATE, true)
	call_deferred("_music_ready", stream)

func _music_ready(stream: AudioStreamWAV) -> void:
	if music_thread != null and music_thread.is_started(): music_thread.wait_to_finish()
	music_stream = stream
	music_player.stream = stream
	_update_music()

func _exit_tree() -> void:
	if music_thread != null and music_thread.is_started(): music_thread.wait_to_finish()

static func db(percent: int) -> float:
	return linear_to_db(maxf(0.0001, percent / 100.0))

## Applies volumes and mute to the buses; 0% mutes that bus.
func apply() -> void:
	var master: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, db(int(volumes.master)))
	AudioServer.set_bus_mute(master, muted or int(volumes.master) == 0)
	for entry in [["Effects", "effects"], ["Music", "music"]]:
		var index: int = AudioServer.get_bus_index(entry[0])
		AudioServer.set_bus_volume_db(index, db(int(volumes[entry[1]])))
		AudioServer.set_bus_mute(index, int(volumes[entry[1]]) == 0)
	_update_music()

func audible(kind: String) -> bool:
	return not muted and int(volumes.master) > 0 and int(volumes[kind]) > 0

func _update_music() -> void:
	if music_player == null: return
	if audible("music") and music_player.stream != null:
		if not music_player.playing: music_player.play()
	elif music_player.playing:
		music_player.stop()

func play(name: String) -> void:
	if not streams.has(name): return
	last_effect = name
	effect_count += 1
	if not audible("effects"): return
	for player in players:
		if not player.playing:
			player.stream = streams[name]
			player.play()
			return
	players[0].stream = streams[name]
	players[0].play()
