class_name AppFonts
extends RefCounted
## Fonts. Port of src/ui/Fonts.js
##
## The JS version downloaded fonts at runtime from the Assets repo (TEMPORARY).
## In Godot the fonts are bundled as files in res://assets/fonts/ (see the README there).
## Each weight is its own file/family.

const DIR := "res://assets/fonts/"

const FILES := {
	"thin": "Vazir-Thin-FD-WOL.ttf",
	"light": "Vazir-Light-FD-WOL.ttf",
	"regular": "Vazir-FD-WOL.ttf",
	"medium": "Vazir-Medium-FD-WOL.ttf",
	"bold": "Vazir-Bold-FD-WOL.ttf",
	"title": "Lalezar-Regular.ttf",
	## OPTIONAL (added in Part 3): a color emoji font. While the icons are emoji, put
	## NotoColorEmoji.ttf here if emoji don't show on your device. It is attached as a fallback
	## to every other font automatically. If the file isn't there, the system emoji font is used.
	"emoji": "NotoColorEmoji.ttf",
}


## Returns the font for a key ("thin", "light", "regular", "medium", "bold", "title", "emoji"),
## or null if the file isn't in the project yet (-> Godot falls back to its default/system font).
static func get_font(key: String) -> Font:
	if not FILES.has(key):
		return null
	var path: String = DIR + String(FILES[key])
	if not ResourceLoader.exists(path):
		return null
	var f := load(path) as Font
	if f != null and key != "emoji":
		_attach_emoji(f)
	return f


## Makes the regular Vazir font the default font of a Theme (if available).
static func apply_to_theme(theme: Theme) -> void:
	var regular := get_font("regular")
	if regular != null:
		theme.default_font = regular


## Adds the optional emoji font as a fallback of `f` (once).
static func _attach_emoji(f: Font) -> void:
	var path: String = DIR + String(FILES["emoji"])
	if not ResourceLoader.exists(path):
		return
	var emoji := load(path) as Font
	if emoji == null:
		return
	var fb: Array[Font] = f.fallbacks
	if fb.has(emoji):
		return
	fb.append(emoji)
	f.fallbacks = fb
