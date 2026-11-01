class_name Economy
extends RefCounted
## Pure economy functions. No nodes, no storage.
## Port of src/game/economy.js

static func default_levels() -> Dictionary:
	var levels := {}
	for k in Balance.SECTION_KEYS:
		levels[k] = 1
	return levels


## Units/sec produced by a flow section (vitrin = customers, pishkhan = sales, tanoor = bread).
static func flow_rate(key: String, level: int) -> float:
	var s: Dictionary = Balance.SECTIONS[key]
	return float(s["rate_base"]) * pow(float(s["rate_growth"]), level - 1)


## Extra coins per customer from decor.
static func decor_extra(level: int) -> float:
	var s: Dictionary = Balance.SECTIONS["decor"]
	return float(s["extra_per_level"]) * (level - 1)


## Cost of going from `level` to `level + 1`.
static func upgrade_cost(key: String, level: int) -> float:
	var s: Dictionary = Balance.SECTIONS[key]
	return floor(float(s["cost_base"]) * pow(float(s["cost_growth"]), level - 1))


## Full picture of the economy for a set of section levels.
## Returns { flows, bottleneck, throughput, price, income }
static func analyze(levels: Dictionary) -> Dictionary:
	var flows := {}
	for k in Balance.FLOW_KEYS:
		flows[k] = flow_rate(k, int(levels[k]))
	var bottleneck: String = Balance.FLOW_KEYS[0]
	for k in Balance.FLOW_KEYS:
		if float(flows[k]) < float(flows[bottleneck]):
			bottleneck = k
	# customers actually served & paid per sec
	var throughput: float = flows[bottleneck]
	var price: float = Balance.BASE_PRICE + decor_extra(int(levels["decor"]))
	return {
		"flows": flows,
		"bottleneck": bottleneck,
		"throughput": throughput,
		"price": price,
		"income": throughput * price,
	}


static func income_per_sec(levels: Dictionary) -> float:
	return float(analyze(levels)["income"])


## Single "bakery level" used for season progress / HUD: average of the 4 sections (rounded down).
static func overall_level(levels: Dictionary) -> int:
	var total := 0
	for k in Balance.SECTION_KEYS:
		total += int(levels[k])
	return maxi(1, floori(float(total) / float(Balance.SECTION_KEYS.size())))


static func capped_offline_seconds(seconds: float) -> float:
	return minf(seconds, Balance.OFFLINE_CAP_SEC)


static func offline_earnings(levels: Dictionary, seconds: float) -> float:
	return income_per_sec(levels) * capped_offline_seconds(seconds) * Balance.OFFLINE_EFFICIENCY
