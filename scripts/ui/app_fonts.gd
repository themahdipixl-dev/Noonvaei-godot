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
}


## Returns the font for a key ("thin", "light", "regular", "medium", "bold", "title"),
## or null if the file isn't in the project yet (-> Godot falls back to its default/system font).
static func get_font(key: String) -> Font:
	if not FILES.has(key):
		return null
	var path: String = DIR + String(FILES[key])
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null


## Makes the regular Vazir font the default font of a Theme (if available).
static func apply_to_theme(theme: Theme) -> void:
	var regular := get_font("regular")
	if regular != null:
		theme.default_font = regular
