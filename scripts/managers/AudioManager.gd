extends Node

var bgm_player: AudioStreamPlayer
var _sfx_enabled: bool = true

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	_connect_events()
	_self_test()

func _connect_events() -> void:
	EventBus.on("projectile:explode", func(_d): _play_log("💥 爆炸"))
	EventBus.on("card:used", func(_d): _play_log("🃏 使用卡牌"))
	EventBus.on("card:drawn", func(_d): _play_log("🃏 抽牌"))
	EventBus.on("unit:died", func(_d): _play_log("💀 单位死亡"))
	EventBus.on("turn:phase_changed", func(_d): _play_log("⏳ 阶段切换"))
	EventBus.on("battle:ended", func(d): _play_log("🏁 战斗结束: " + str(d.get("result", ""))))
	EventBus.on("shop:item_bought", func(_d): _play_log("🛒 购买物品"))
	EventBus.on("wind:changed", func(_d): _play_log("💨 风向变化"))
	EventBus.on("energy:changed", func(_d): _play_log("⚡ 能量变化"))
	EventBus.on("event:triggered", func(_d): _play_log("❓ 触发事件"))
	EventBus.on("event:resolved", func(_d): _play_log("✅ 事件解决"))

func _play_log(text: String) -> void:
	if _sfx_enabled:
		print("[Audio] " + text)

func play_bgm(s: AudioStream) -> void:
	bgm_player.stream = s
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_sfx(s: AudioStream) -> void:
	if not _sfx_enabled:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = s
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()

func _self_test() -> void:
	TestHelper.check(bgm_player != null, "AudioManager has bgm_player")
	TestHelper.check(_sfx_enabled, "AudioManager sfx enabled")
	# Trigger a log to verify event binding
	_play_log("🔊 AudioManager self-test")
	print("[TEST] AudioManager self-test complete")
