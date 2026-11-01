class_name Icons
extends RefCounted
## Icons. Port of src/ui/Icons.js
##
## TEMPORARY: the PNG icons are replaced by emoji for now. When the real icon textures are added to
## the project, only this file needs to change (keep the same names / the same `place()` function).

## ICONS key (same keys as the JS file) -> emoji
const EMOJI := {
	"joystick": "🕹️",
	"cart": "🛒",
	"diamond": "💎",
	"clipboard": "📋",
	"buildings": "🏙️",
	"sparkle": "✨",
	"crown": "👑",
	"levelUp": "⬆️",
	"gear": "⚙️",
	"house": "🏠",
	"money": "💵",
	"cards": "🃏",
	"plus": "➕",
	"star": "⭐",
	# extra (were inline emoji in the JS UI)
	"coin": "🪙",
	"warn": "⚠️",
}

## Bottom bar tab key -> ICONS key
const TAB_ICON := {
	"shop": "cart",
	"cards": "cards",
	"home": "house",
	"upgrade": "levelUp",
	"minigames": "joystick",
}


static func get_emoji(icon_name: String) -> String:
	return String(EMOJI.get(icon_name, ""))


static func tab_emoji(tab_key: String) -> String:
	return get_emoji(String(TAB_ICON.get(tab_key, "")))


## Adds an icon (a centered emoji label) to `parent` inside the square [pos, pos + box]. Returns the label.
static func place(parent: Control, icon_name: String, pos: Vector2, box: float) -> Label:
	var l := UiKit.make_label(get_emoji(icon_name), box * 0.78, Color.WHITE, "regular")
	parent.add_child(l)
	UiKit.place_label(l, Rect2(pos, Vector2(box, box)))
	return l
