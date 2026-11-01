extends Node
## Autoload singleton: `Game`.
## Replaces state.js (reducer) + useGame.js (hook) from the React Native app.
##
## React concept        ->  Godot equivalent
##   useReducer state   ->  member variables below
##   dispatch(...)      ->  plain methods (upgrade, dismiss_offline, ...)
##   re-render          ->  `changed` signal (UI listens and refreshes)
##   setInterval        ->  Timer nodes
##   AppState listener  ->  _notification() app lifecycle callbacks

## Emitted after money / levels / derived values changed.
signal changed
## Emitted when `offline_report` is set or cleared.
signal offline_report_changed

var money := 0.0
## { vitrin, pishkhan, tanoor, decor } -> int level
var levels: Dictionary = {}
var total_earned := 0.0
## Unix time (seconds) of the last tick.
var last_seen := 0.0
## Runtime only, never saved. Empty = no report. Otherwise { amount: float, seconds: float }
var offline_report: Dictionary = {}
var is_loaded := false

# --- derived values (recomputed whenever levels change) ---
## { flows, bottleneck, throughput, price, income }
var info: Dictionary = {}
## section key -> cost of the next upgrade
var costs: Dictionary = {}
var income := 0.0
var level := 1

var _tick_timer: Timer
var _save_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_saved(_now())
	_tick_timer = _make_timer(Balance.TICK_SEC, _on_tick_timeout)
	_save_timer = _make_timer(Balance.SAVE_EVERY_SEC, _on_save_timeout)
	is_loaded = true
	changed.emit()


# ------------------------------------------------------------------ public API

## Try to buy the next level of a section. Returns true on success.
func upgrade(section: String) -> bool:
	if not Balance.SECTION_KEYS.has(section):
		return false
	var cost: float = costs[section]
	if money < cost:
		return false
	money -= cost
	levels[section] = int(levels[section]) + 1
	_recompute()
	changed.emit()
	save_now() # save right after purchase
	return true


func dismiss_offline() -> void:
	offline_report = {}
	offline_report_changed.emit()


func save_now() -> void:
	Storage.save_game(money, levels, total_earned, last_seen)


# ------------------------------------------------------------------ internals

func _now() -> float:
	return Time.get_unix_time_from_system()


func _make_timer(wait: float, callback: Callable) -> Timer:
	var t := Timer.new()
	t.wait_time = wait
	t.one_shot = false
	t.autostart = true
	t.timeout.connect(callback)
	add_child(t)
	return t


func _on_tick_timeout() -> void:
	_apply_time(_now())


func _on_save_timeout() -> void:
	save_now()


func _recompute() -> void:
	info = Economy.analyze(levels)
	income = float(info["income"])
	level = Economy.overall_level(levels)
	costs = {}
	for k in Balance.SECTION_KEYS:
		costs[k] = Economy.upgrade_cost(k, int(levels[k]))


## Pays income for the time since `last_seen`.
## Short gaps are normal play; long gaps (app was closed / paused) create an offline report.
func _apply_time(now: float) -> void:
	var dt := maxf(0.0, now - last_seen)
	var earned := 0.0
	if dt < Balance.OFFLINE_THRESHOLD_SEC:
		earned = income * dt
	else:
		earned = Economy.offline_earnings(levels, dt)
		offline_report = {
			"amount": earned,
			"seconds": Economy.capped_offline_seconds(dt),
		}
		offline_report_changed.emit()
	money += earned
	total_earned += earned
	last_seen = now
	changed.emit()


# ------------------------------------------------------------------ load / sanitize

func _load_saved(now: float) -> void:
	var saved := Storage.load_game()
	if saved.is_empty():
		money = 0.0
		levels = Economy.default_levels()
		total_earned = 0.0
		last_seen = now
		_recompute()
		return
	money = maxf(0.0, _num(saved.get("money"), 0.0))
	levels = _sanitize_levels(saved)
	total_earned = maxf(0.0, _num(saved.get("totalEarned"), 0.0))
	last_seen = minf(now, _num(saved.get("lastSeen"), now))
	_recompute()
	_apply_time(now) # pays the offline gap


func _num(v: Variant, fallback: float) -> float:
	if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
		var f := float(v)
		if is_finite(f):
			return f
	return fallback


func _lvl(v: Variant) -> int:
	return maxi(1, floori(_num(v, 1.0)))


## v2 saves have `levels`; v1 saves had a single `level` -> every section starts at that level.
func _sanitize_levels(saved: Dictionary) -> Dictionary:
	var src: Variant = saved.get("levels")
	var has_levels := src is Dictionary
	var legacy := _lvl(saved.get("level"))
	var out := {}
	for k in Balance.SECTION_KEYS:
		out[k] = _lvl(src.get(k)) if has_levels else legacy
	return out


# ------------------------------------------------------------------ app lifecycle

func _notification(what: int) -> void:
	if not is_loaded:
		return
	match what:
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_apply_time(_now()) # pays the offline gap
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			_apply_time(_now()) # bring money up to date, then stamp last_seen
			save_now()
