extends RefCounted
## D40 / R4: synthesised sounds and music, the audio buses, settings version 2.
const City = preload("res://scripts/sim/city_state.gd")
const SoundKit = preload("res://scripts/presentation/sound_kit.gd")
const AudioDirector = preload("res://scripts/presentation/audio_director.gd")
const Settings = preload("res://scripts/persistence/settings_store.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
var t: SceneTree

func run(tester: SceneTree) -> void:
	t = tester
	test_effects()
	test_music()
	test_settings_v2()
	await test_director()
	print("PASS group: R4 sounds, music, buses and settings version 2")

func quiet_edges(samples: PackedFloat32Array) -> bool:
	return absf(samples[0]) < 0.02 and absf(samples[samples.size() - 1]) < 0.02

func test_effects() -> void:
	var city: City = t.land(8, 8)
	var state: int = city.rng.state
	for name in SoundKit.EFFECTS:
		var samples: PackedFloat32Array = SoundKit.effect_samples(name)
		var seconds: float = float(samples.size()) / SoundKit.EFFECT_RATE
		var top: float = SoundKit.peak(samples)
		t.check(seconds > 0.1 and seconds < 1.0 and top > 0.05 and top <= 0.5, "%s is under a second and peaks at most half scale (%.2f)" % [name, top])
		t.check(quiet_edges(samples), "%s starts and ends quietly" % name)
		t.check(SoundKit.effect_samples(name) == samples, "%s is identical on every run" % name)
		var wav: AudioStreamWAV = SoundKit.to_wav(samples, SoundKit.EFFECT_RATE, false)
		t.check(wav.data.size() == samples.size() * 2 and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED and wav.mix_rate == SoundKit.EFFECT_RATE, "%s becomes a 16-bit mono, non-looping stream" % name)
	t.check(city.rng.state == state, "synthesis never touches the town's randomness")
	t.check(SoundKit.effect_samples("nothing").is_empty(), "unknown sounds are empty")

func test_music() -> void:
	var samples: PackedFloat32Array = SoundKit.music_samples()
	var seconds: float = float(samples.size()) / SoundKit.MUSIC_RATE
	var top: float = SoundKit.peak(samples)
	t.check(absf(seconds - 12.0) < 0.01 and top > 0.1 and top <= 0.5, "the music loop is 12 seconds and peaks at most half scale (%.2f)" % top)
	t.check(quiet_edges(samples) and absf(samples[0] - samples[samples.size() - 1]) < 0.02, "the loop joins quietly, without a click")
	var wav: AudioStreamWAV = SoundKit.to_wav(samples, SoundKit.MUSIC_RATE, true)
	t.check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_end == samples.size(), "the music stream loops over its whole length")
	var notes: bool = true
	for entry in SoundKit.MELODY:
		notes = notes and int(entry[1]) % 12 in [0, 2, 4, 5, 7, 9] and float(entry[0]) + float(entry[2]) <= SoundKit.BEATS
	t.check(notes, "the melody stays in its key and inside the 16-beat loop")

func test_settings_v2() -> void:
	var previous: String = Settings.override_path
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	Settings.override_path = base.path_join("settings_v2_%d/settings.json" % Time.get_ticks_usec())
	var store := Settings.new()
	var d: Dictionary = Settings.defaults()
	t.check(int(d.settings_version) == Settings.VERSION and int(d.master_volume) == 80 and int(d.effects_volume) == 70 and int(d.music_volume) == 30 and not bool(d.muted) and bool(d.animation), "version-2 defaults: 80 / 70 / 30, not muted, animation on")
	var v1: Dictionary = Settings.defaults_v1()
	v1.text_size = 20
	v1.services = true
	FileOps.new().write_text(Settings.path(), JSON.stringify(v1))
	var migrated: Dictionary = store.load_settings()
	t.check(migrated.ok and int(migrated.settings.text_size) == 20 and bool(migrated.settings.services) and int(migrated.settings.settings_version) == Settings.VERSION and int(migrated.settings.music_volume) == 30 and bool(migrated.settings.animation), "a valid version-1 file keeps its values and gains the sound defaults")
	var values: Dictionary = Settings.defaults()
	values.music_volume = 0
	values.muted = true
	values.animation = false
	t.check(store.save_settings(values).ok and store.load_settings().settings == values, "version-2 settings round-trip")
	for bad in [55, 110, -10, 2.5]:
		var wrong: Dictionary = Settings.defaults()
		wrong.effects_volume = bad
		t.check(not Settings.valid(wrong), "volume %s is rejected" % str(bad))
	var mixed: Dictionary = Settings.defaults_v1()
	mixed.muted = true
	t.check(not Settings.valid(mixed), "a version-1 file with version-2 keys is rejected")
	Settings.override_path = previous

func test_director() -> void:
	var director := AudioDirector.new()
	t.root.add_child(director)
	t.check(AudioServer.get_bus_index("Effects") > 0 and AudioServer.get_bus_index("Music") > 0 and director.streams.size() == SoundKit.EFFECTS.size(), "Effects and Music buses and every effect stream exist")
	director.volumes = {"master": 50, "effects": 0, "music": 40}
	director.muted = false
	director.apply()
	var effects: int = AudioServer.get_bus_index("Effects")
	t.check(AudioServer.is_bus_mute(effects) and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.4)) < 0.01, "0% mutes a bus; other volumes become bus levels")
	director.play("build")
	t.check(director.last_effect == "build" and director.effect_count == 1 and not director.audible("effects"), "a silenced effect is recorded but not audible")
	director.muted = true
	director.apply()
	t.check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and not director.audible("music"), "Mute all silences the master bus")
	for frame in range(200):
		if director.music_stream != null: break
		await t.process_frame
	t.check(director.music_stream != null and not director.music_player.playing, "the music is made in the background and stays stopped while muted")
	director.muted = false
	director.apply()
	t.check(director.music_player.playing, "unmuting starts the music")
	director.queue_free()
	await t.process_frame
	# Leave the shared buses at their defaults for later tests.
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
