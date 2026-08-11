extends Node

const MAX_OFFLINE_SECONDS := 7200.0
const CUSTOMER_INTERVAL := 8.0
const ORDER_UNLOCK_SALES := 3
const ORDER_DURATION := 120.0
const ORDER_REFRESH_DELAY := 90.0

const INGREDIENTS := {
	"flour": {"name": "面粉", "price": 3},
	"egg": {"name": "鸡蛋", "price": 5},
	"scallion": {"name": "葱花", "price": 4},
}

const RECIPES := {
	"batter": {
		"name": "面糊",
		"ingredients": {"flour": 2},
		"duration": 6.0,
		"output": "batter",
		"output_category": "materials",
		"price": 0,
	},
	"egg_pancake": {
		"name": "鸡蛋饼",
		"ingredients": {"batter": 1, "egg": 1},
		"duration": 10.0,
		"output": "egg_pancake",
		"output_category": "finished",
		"price": 25,
	},
	"scallion_pancake": {
		"name": "葱油饼",
		"ingredients": {"batter": 1, "scallion": 1},
		"duration": 9.0,
		"output": "scallion_pancake",
		"output_category": "finished",
		"price": 23,
	},
}

const PRODUCT_NAMES := {
	"batter": "面糊",
	"egg_pancake": "鸡蛋饼",
	"scallion_pancake": "葱油饼",
}

const UPGRADES := {
	"production_speed": {"name": "生产速度", "cost": 600, "recommended": true},
	"storage": {"name": "库存容量", "cost": 750, "recommended": false},
	"counter": {"name": "柜台销售效率", "cost": 900, "recommended": false},
}


func new_state() -> Dictionary:
	return {
		"coins": 80,
		"reputation": 0,
		"stock": {
			"flour": 0,
			"egg": 0,
			"scallion": 0,
			"batter": 0,
			"egg_pancake": 0,
			"scallion_pancake": 0,
		},
		"finished_items": [],
		"queue": [],
		"next_job_id": 1,
		"customer_timer": CUSTOMER_INTERVAL,
		"sold_since_offer": 0,
		"order_offer": {},
		"active_order": {},
		"order_cooldown": 0.0,
		"upgrades": {
			"production_speed": false,
			"storage": false,
			"counter": false,
		},
		"last_saved_unix": Time.get_unix_time_from_system(),
	}


func material_capacity(state: Dictionary) -> int:
	return 30 if state["upgrades"].get("storage", false) else 20


func finished_capacity(state: Dictionary) -> int:
	return 12 if state["upgrades"].get("storage", false) else 8


func recipe_duration(state: Dictionary, recipe_id: String) -> float:
	var duration: float = RECIPES[recipe_id]["duration"]
	return duration * 0.8 if state["upgrades"].get("production_speed", false) else duration


func sale_price(state: Dictionary, product_id: String) -> int:
	var price: int = RECIPES[product_id]["price"]
	return int(round(price * 1.2)) if state["upgrades"].get("counter", false) else price
