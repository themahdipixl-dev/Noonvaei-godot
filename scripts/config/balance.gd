class_name Balance
extends RefCounted
## All tunable numbers live here.
## Port of src/config/balance.js
##
## Economy model (step 1):
##   customers/sec  <- vitrin   (ویترین)
##   sales/sec      <- pishkhan (پیشخوان)
##   bread/sec      <- tanoor   (تنور و حمل)
##   throughput     =  min(customers, sales, bread)  <- the weakest section limits everything
##   price per sale =  BASE_PRICE + decor bonus      <- decor (دکور) adds money per customer
##   income/sec     =  throughput * price per sale

const SECTION_KEYS: Array[String] = ["vitrin", "pishkhan", "tanoor", "decor"]
## Sections that can be the bottleneck.
const FLOW_KEYS: Array[String] = ["vitrin", "pishkhan", "tanoor"]

## Save file (replaces AsyncStorage key 'bakery_save_v1').
const SAVE_PATH := "user://bakery_save.json"
const SAVE_VERSION := 2

## NOTE: the JS version used milliseconds, Godot version uses seconds.
const TICK_SEC := 0.25
const SAVE_EVERY_SEC := 5.0

## Coins per sold loaf at decor level 1.
const BASE_PRICE := 1.0

## rate(level) = rate_base * rate_growth^(level-1)   (units per second)
## cost(level) = cost_base * cost_growth^(level-1)   (cost of going level -> level+1)
const SECTIONS := {
	"vitrin":   {"rate_base": 1.0, "rate_growth": 1.15, "cost_base": 15.0, "cost_growth": 1.32},
	"pishkhan": {"rate_base": 1.5, "rate_growth": 1.15, "cost_base": 20.0, "cost_growth": 1.32},
	"tanoor":   {"rate_base": 1.2, "rate_growth": 1.15, "cost_base": 25.0, "cost_growth": 1.32},
	# decor: extra coins per customer = extra_per_level * (level-1)
	"decor":    {"extra_per_level": 0.25, "cost_base": 30.0, "cost_growth": 1.4},
}

## Gaps longer than this count as "offline".
const OFFLINE_THRESHOLD_SEC := 10.0
## Max 8h of offline income.
const OFFLINE_CAP_SEC := 8.0 * 3600.0
## Offline pays 50%.
const OFFLINE_EFFICIENCY := 0.5
