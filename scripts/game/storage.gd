class_name Storage
extends RefCounted
## Save / load to disk. Replaces AsyncStorage.
## Port of src/game/storage.js
##
## File: user://bakery_save.json  (Android: app-private storage)

## Returns the saved dictionary, or an empty dictionary if there is no (valid) save.
static func load_game() -> Dictionary:
	if not FileAccess.file_exists(Balance.SAVE_PATH):
		return {}
	var file := FileAccess.open(Balance.SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


## Same schema as the React Native version: { v, money, levels, totalEarned, lastSeen }
## (lastSeen is in SECONDS here, not milliseconds).
static func save_game(money: float, levels: Dictionary, total_earned: float, last_seen: float) -> void:
	var file := FileAccess.open(Balance.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		# ignore save errors in the first prototype (same as the JS version)
		return
	file.store_string(JSON.stringify({
		"v": Balance.SAVE_VERSION,
		"money": money,
		"levels": levels,
		"totalEarned": total_earned,
		"lastSeen": last_seen,
	}))
