extends Node
## Audio: buses, adaptive music, positional SFX, ambience, and the voice/dialogue queue with subtitles.

signal line_started(spk: String, text: String, dur: float)
signal line_finished
signal queue_empty

var _cache := {}
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var _music_cur: AudioStreamPlayer
var _music_key := ""
var _music_target_db := 0.0
var voice: AudioStreamPlayer
var amb_a: AudioStreamPlayer
var amb_b: AudioStreamPlayer
var _queue: Array = []
var _cur_line = null
var _line_t := 0.0
var _line_dur := 0.0
var _pool3d: Array[AudioStreamPlayer3D] = []
var _pool2d: Array[AudioStreamPlayer] = []
var _p3i := 0
var _p2i := 0
var duck := 0.0
var voice_mission := "m1"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	music_a = _mk_player("Music"); music_b = _mk_player("Music"); _music_cur = music_a
	voice = _mk_player("VoiceNear")
	amb_a = _mk_player("Ambience"); amb_b = _mk_player("Ambience")
	for i in 40:
		var p := AudioStreamPlayer3D.new(); p.bus = "SFX"; p.unit_size = 6.0; p.max_distance = 90.0; p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 1.0; add_child(p); _pool3d.append(p)
	for i in 16:
		var q := AudioStreamPlayer.new(); q.bus = "SFX"; add_child(q); _pool2d.append(q)
	Game.settings_changed.connect(apply_volumes)
	apply_volumes()

func _mk_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.bus = bus; add_child(p); return p

func _setup_buses() -> void:
	var names := ["Music", "SFX", "Ambience", "UI", "VoiceNear", "VoiceRadio", "VoicePA", "VoiceIntercept"]
	for n in names:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus(); var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n); AudioServer.set_bus_send(i, "Master")
	# SFX: room reverb (wet adjusted per room) + gentle compression
	var sfx := AudioServer.get_bus_index("SFX")
	var rv := AudioEffectReverb.new(); rv.room_size = 0.55; rv.damping = 0.6; rv.wet = 0.12; rv.dry = 1.0; rv.spread = 0.8
	AudioServer.add_bus_effect(sfx, rv)
	var comp := AudioEffectCompressor.new(); comp.threshold = -10; comp.ratio = 4; AudioServer.add_bus_effect(sfx, comp)
	# Voice buses
	var vn := AudioServer.get_bus_index("VoiceNear")
	var rvn := AudioEffectReverb.new(); rvn.room_size = 0.35; rvn.wet = 0.08; rvn.dry = 1.0; AudioServer.add_bus_effect(vn, rvn)
	var vr := AudioServer.get_bus_index("VoiceRadio")
	var hp := AudioEffectHighPassFilter.new(); hp.cutoff_hz = 380; AudioServer.add_bus_effect(vr, hp)
	var lp := AudioEffectLowPassFilter.new(); lp.cutoff_hz = 3800; AudioServer.add_bus_effect(vr, lp)
	var ds := AudioEffectDistortion.new(); ds.mode = AudioEffectDistortion.MODE_OVERDRIVE; ds.drive = 0.18; ds.post_gain = -2; AudioServer.add_bus_effect(vr, ds)
	var cp := AudioEffectCompressor.new(); cp.threshold = -16; cp.ratio = 6; cp.gain = 3; AudioServer.add_bus_effect(vr, cp)
	var vp := AudioServer.get_bus_index("VoicePA")
	var hp2 := AudioEffectHighPassFilter.new(); hp2.cutoff_hz = 220; AudioServer.add_bus_effect(vp, hp2)
	var bp := AudioEffectLowPassFilter.new(); bp.cutoff_hz = 5200; AudioServer.add_bus_effect(vp, bp)
	var dl := AudioEffectDelay.new(); dl.tap1_active = true; dl.tap1_delay_ms = 140; dl.tap1_level_db = -12; dl.tap2_active = true; dl.tap2_delay_ms = 290; dl.tap2_level_db = -18; dl.feedback_active = false
	AudioServer.add_bus_effect(vp, dl)
	var rvp := AudioEffectReverb.new(); rvp.room_size = 0.85; rvp.wet = 0.22; AudioServer.add_bus_effect(vp, rvp)
	var vi := AudioServer.get_bus_index("VoiceIntercept")
	var hp3 := AudioEffectHighPassFilter.new(); hp3.cutoff_hz = 500; AudioServer.add_bus_effect(vi, hp3)
	var lp3 := AudioEffectLowPassFilter.new(); lp3.cutoff_hz = 3000; AudioServer.add_bus_effect(vi, lp3)
	var ds3 := AudioEffectDistortion.new(); ds3.mode = AudioEffectDistortion.MODE_LOFI; ds3.drive = 0.35; AudioServer.add_bus_effect(vi, ds3)
	var mus := AudioServer.get_bus_index("Music")
	var mc := AudioEffectCompressor.new(); mc.threshold = -14; mc.ratio = 3; mc.sidechain = &"VoiceRadio"; AudioServer.add_bus_effect(mus, mc)

func apply_volumes() -> void:
	var s: Dictionary = Game.settings
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(s["vol_master"]))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, float(s["vol_music"]))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(0.0001, float(s["vol_sfx"]))))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(0.0001, float(s["vol_sfx"]) * 0.8)))
	for b in ["VoiceNear", "VoiceRadio", "VoicePA", "VoiceIntercept"]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(b), linear_to_db(maxf(0.0001, float(s["vol_voice"]))) + 2.0)

func stream(path: String) -> AudioStream:
	if _cache.has(path): return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path): s = load(path)
	_cache[path] = s
	return s

func sfx(name: String) -> AudioStream:
	return stream("res://assets/audio/sfx/%s.ogg" % name)

## Positional sound
func play3d(name: String, pos: Vector3, db := 0.0, pitch_var := 0.06, unit := 6.0) -> void:
	var s := sfx(name)
	if s == null: return
	var p := _pool3d[_p3i % _pool3d.size()]; _p3i += 1
	p.stream = s; p.volume_db = db; p.unit_size = unit; p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.global_position = pos; p.play()

func play2d(name: String, db := 0.0, pitch_var := 0.0, bus := "SFX") -> void:
	var s := sfx(name)
	if s == null: return
	var p := _pool2d[_p2i % _pool2d.size()]; _p2i += 1
	p.stream = s; p.volume_db = db; p.bus = bus; p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var); p.play()

func set_reverb(wet: float, size := 0.55) -> void:
	var rv := AudioServer.get_bus_effect(AudioServer.get_bus_index("SFX"), 0) as AudioEffectReverb
	if rv: rv.wet = wet; rv.room_size = size

## Ambience loops (rain, alarm, hum). Empty name stops.
func ambience(name: String, db := -8.0, second := "", db2 := -14.0) -> void:
	for pair in [[amb_a, name, db], [amb_b, second, db2]]:
		var pl: AudioStreamPlayer = pair[0]
		if pair[1] == "": pl.stop(); continue
		var s := sfx(pair[1])
		if s == null: continue
		if s is AudioStreamOggVorbis: (s as AudioStreamOggVorbis).loop = true
		if pl.stream != s or not pl.playing:
			pl.stream = s; pl.play()
		pl.volume_db = pair[2]

## Music with crossfade. key is a track name under assets/audio/music.
func music(key: String, fade := 2.0, db := 0.0) -> void:
	if key == _music_key: return
	_music_key = key
	var nxt: AudioStreamPlayer = music_b if _music_cur == music_a else music_a
	var old := _music_cur
	if key != "":
		var s := stream("res://assets/audio/music/%s.ogg" % key)
		if s is AudioStreamOggVorbis: (s as AudioStreamOggVorbis).loop = true
		nxt.stream = s; nxt.volume_db = -40.0; nxt.play()
		create_tween().tween_property(nxt, "volume_db", db, fade)
		_music_target_db = db
	var tw := create_tween(); tw.tween_property(old, "volume_db", -40.0, fade); tw.tween_callback(old.stop)
	_music_cur = nxt

func music_key() -> String: return _music_key

func stop_music(fade := 2.0) -> void: music("", fade)

## Dialogue
func say(spk: String, text: String, vo_id := "", mission := "", interrupt := false) -> void:
	var item := {"spk": spk, "text": text, "vo": vo_id, "m": mission if mission != "" else voice_mission}
	if interrupt:
		_queue.clear(); _stop_line()
	_queue.append(item)

func say_lines(lines: Array, mission := "") -> void:
	for l in lines: say(l["spk"], l["text"], l.get("vo", ""), mission)

func say_generic(gid: String, interrupt := false) -> void:
	var g: Dictionary = Game.content["generic"].get(gid, {})
	if g.is_empty(): return
	say(g["spk"], g["text"], gid, "common", interrupt)

func bark(spk: String, id: String, pos = null) -> void:
	# short positional/radio bark that doesn't occupy the subtitle queue
	var s := stream("res://assets/audio/vo/barks/%s_%s.ogg" % [spk, id])
	if s == null: return
	if pos != null and spk != "RUIZ":
		var p := _pool3d[_p3i % _pool3d.size()]; _p3i += 1
		p.stream = s; p.volume_db = 2.0; p.unit_size = 8.0; p.pitch_scale = 1.0; p.global_position = pos; p.play()
	elif not voice.playing:
		var q := _pool2d[_p2i % _pool2d.size()]; _p2i += 1
		q.stream = s; q.bus = "VoiceNear"; q.volume_db = -2.0; q.pitch_scale = 1.0; q.play()

func skip_line() -> void: _stop_line()

func busy() -> bool: return _cur_line != null or not _queue.is_empty()

func clear_dialogue() -> void:
	_queue.clear(); _stop_line()

func _stop_line() -> void:
	voice.stop()
	if _cur_line != null:
		_cur_line = null; line_finished.emit()

func _process(dt: float) -> void:
	if _cur_line == null and not _queue.is_empty():
		_cur_line = _queue.pop_front()
		var path := "res://assets/audio/vo/%s/%s.ogg" % [_cur_line["m"], _cur_line["vo"]]
		var s: AudioStream = stream(path) if _cur_line["vo"] != "" else null
		var fx: String = Game.speaker(_cur_line["spk"]).get("fx", "near")
		voice.bus = {"radio": "VoiceRadio", "pa": "VoicePA", "intercept": "VoiceIntercept"}.get(fx, "VoiceNear")
		if s:
			voice.stream = s; voice.play(); _line_dur = s.get_length() + 0.25
			if fx == "radio": play2d("empty", -26.0, 0.1, "UI")
		else:
			_line_dur = 1.6 + _cur_line["text"].length() * 0.055
		_line_t = 0.0
		line_started.emit(_cur_line["spk"], _cur_line["text"], _line_dur)
	if _cur_line != null:
		_line_t += dt
		if _line_t >= _line_dur:
			_cur_line = null; line_finished.emit()
			if _queue.is_empty(): queue_empty.emit()
	# duck music under dialogue
	var target := -7.0 if (_cur_line != null) else 0.0
	duck = lerpf(duck, target, 1.0 - exp(-4.0 * dt))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, float(Game.settings["vol_music"]))) + duck)
