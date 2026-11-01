extends Control
## PART 3 main scene: the world map with the real UI on top. Port of App.js
##
## Layers (bottom -> top):  WorldMap  ->  TopGradient  ->  Hud  ->  UpgradePanel / ComingSoon  ->  BottomBar  ->  OfflineCard
##
## React concept                      ->  Godot
##   useGame()                         ->  `Game` autoload + its `changed` / `offline_report_changed` signals
##   useState('home')                  ->  `_tab`
##   useSafeAreaInsets / useBottomBarHeight -> UiKit.safe_insets() / BottomBar.bar_height()
##   hideSystemNav (expo-navigation-bar) -> _hide_system_bars()
##   loading screen (fonts / save)     ->  not needed: the save is loaded synchronously by `Game`, fonts are local files

var _map: WorldMap
var _top_gradient: TopGradient
var _hud: Hud
var _upgrade_panel: UpgradePanel
var _coming_soon: ComingSoon
var _bottom_bar: BottomBar
var _offline_card: OfflineCard

var _tab := "home"  # shop | cards | home | upgrade | minigames
var _dp := 1.0


func _ready() -> void:
	# Default Persian font (if the font files were added to assets/fonts/)
	var t := Theme.new()
	AppFonts.apply_to_theme(t)
	theme = t

	_hide_system_bars()

	# --- world (bottom layer) ---
	_map = WorldMap.new()
	_map.name = "WorldMap"
	add_child(_map)

	# Phone's top status bar is hidden; a short black -> transparent gradient replaces it.
	_top_gradient = TopGradient.new()
	add_child(_top_gradient)

	# The HUD root ignores the mouse, so empty areas still pass touches to the map.
	_hud = Hud.new()
	add_child(_hud)

	_upgrade_panel = UpgradePanel.new()
	_upgrade_panel.upgrade_requested.connect(Game.upgrade)
	add_child(_upgrade_panel)

	_coming_soon = ComingSoon.new()
	add_child(_coming_soon)

	_bottom_bar = BottomBar.new()
	_bottom_bar.tab_changed.connect(_on_tab_changed)
	add_child(_bottom_bar)

	_offline_card = OfflineCard.new()
	_offline_card.closed.connect(Game.dismiss_offline)
	add_child(_offline_card)

	Game.changed.connect(_refresh)
	Game.offline_report_changed.connect(_on_offline_changed)
	resized.connect(_layout)

	_layout()
	_bottom_bar.set_active(_tab)
	_refresh()
	_on_offline_changed()
	call_deferred("_layout")


## Sizes / safe area. Runs at start and whenever the screen size changes.
func _layout() -> void:
	var width := size.x
	if width <= 0.0:
		return
	_dp = UiKit.dp_scale(width)
	var ins := UiKit.safe_insets(get_viewport())
	var inset_top := float(ins["top"])
	var inset_bottom := float(ins["bottom"])

	_top_gradient.configure(_dp)
	_hud.configure(width, _dp, inset_top)
	_bottom_bar.configure(width, _dp, inset_bottom)

	# JS: panelBottom = barHeight + 10
	var panel_bottom := BottomBar.bar_height(inset_bottom, _dp) + 10.0 * _dp
	_upgrade_panel.configure(_dp, panel_bottom)
	_coming_soon.configure(_dp, panel_bottom)
	_offline_card.rebuild(_dp)

	_apply_tab()
	_refresh()


func _on_tab_changed(key: String) -> void:
	_tab = key
	_apply_tab()


func _apply_tab() -> void:
	_upgrade_panel.visible = _tab == "upgrade"
	var soon := _tab == "shop" or _tab == "cards" or _tab == "minigames"
	_coming_soon.visible = soon
	if soon:
		_coming_soon.set_title(String(Strings.TABS[_tab]))


## Pushes the game state into the UI (runs on every `Game.changed`).
func _refresh() -> void:
	_map.set_level(Game.level)
	_hud.set_state(Game.money, Game.income, Game.level)
	if not Game.info.is_empty():
		_upgrade_panel.refresh(Game.levels, Game.costs, Game.money, String(Game.info["bottleneck"]))


func _on_offline_changed() -> void:
	if Game.offline_report.is_empty():
		_offline_card.hide_card()
	else:
		_offline_card.show_report(Game.offline_report, _dp)


# ------------------------------------------------------------------ system bars (Android)

## Hides the phone's own system bars while the game is open. Also turn on
## "Screen > Immersive Mode" in the Android export preset (the most reliable way).
func _hide_system_bars() -> void:
	if OS.get_name() != "Android":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _notification(what: int) -> void:
	# Re-hide when coming back to the app (e.g. after the recents screen).
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_hide_system_bars()
