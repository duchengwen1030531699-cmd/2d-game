extends Node

signal state_changed(state: Dictionary)
signal toast_requested(message: String)

var _state: Dictionary = {}
var _emit_timer := 0.0
var _autosave_timer := 0.0
var persistence_enabled := true


func _ready() -> void:
	_state = SaveManager.load_state()
	if _state.is_empty():
		_state = Catalog.new_state()
	else:
		_normalize_state()
		var offline_seconds := clampf(Time.get_unix_time_from_system() - float(_state.get("last_saved_unix", 0)), 0.0, Catalog.MAX_OFFLINE_SECONDS)
		if offline_seconds > 0.0:
			advance(offline_seconds, false)
			if offline_seconds >= Catalog.MAX_OFFLINE_SECONDS:
				toast_requested.emit("离线结算已达到 2 小时上限")
	_save()
	state_changed.emit(get_state())


func _process(delta: float) -> void:
	advance(delta, true)
	_emit_timer += delta
	_autosave_timer += delta
	if _emit_timer >= 0.25:
		_emit_timer = 0.0
		state_changed.emit(get_state())
	if _autosave_timer >= 15.0:
		_autosave_timer = 0.0
		_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_save()


func _exit_tree() -> void:
	if not _state.is_empty():
		_save()


func get_state() -> Dictionary:
	return _state.duplicate(true)


func purchase(items: Dictionary) -> bool:
	var total_cost := 0
	var total_quantity := 0
	for item_id in items:
		var quantity := int(items[item_id])
		if not Catalog.INGREDIENTS.has(item_id) or quantity < 0:
			return _fail("采购数量无效")
		total_cost += int(Catalog.INGREDIENTS[item_id]["price"]) * quantity
		total_quantity += quantity
	if total_quantity <= 0:
		return _fail("请先选择需要采购的原料")
	if total_cost > int(_state["coins"]):
		return _fail("金币不足，无法完成采购")
	if _material_count() + total_quantity > Catalog.material_capacity(_state):
		return _fail("原料库存容量不足")
	for item_id in items:
		_state["stock"][item_id] += int(items[item_id])
	_state["coins"] -= total_cost
	_commit("采购完成，原料已进入库存")
	return true


func enqueue_recipe(recipe_id: String) -> bool:
	if not Catalog.RECIPES.has(recipe_id):
		return _fail("未知配方")
	var recipe: Dictionary = Catalog.RECIPES[recipe_id]
	for ingredient_id in recipe["ingredients"]:
		if int(_state["stock"].get(ingredient_id, 0)) < int(recipe["ingredients"][ingredient_id]):
			return _fail("材料不足，无法加入队列")
	for ingredient_id in recipe["ingredients"]:
		_state["stock"][ingredient_id] -= int(recipe["ingredients"][ingredient_id])
	var job := {
		"id": int(_state["next_job_id"]),
		"recipe_id": recipe_id,
		"remaining": Catalog.recipe_duration(_state, recipe_id),
		"started": false,
		"blocked": false,
	}
	_state["next_job_id"] += 1
	_state["queue"].append(job)
	_start_next_job()
	_commit("%s 已加入生产队列" % recipe["name"])
	return true


func cancel_queued_job(job_id: int) -> bool:
	for index in range(_state["queue"].size()):
		var job: Dictionary = _state["queue"][index]
		if int(job["id"]) != job_id:
			continue
		if bool(job["started"]):
			return _fail("生产中的任务不可取消")
		var recipe: Dictionary = Catalog.RECIPES[job["recipe_id"]]
		for ingredient_id in recipe["ingredients"]:
			_state["stock"][ingredient_id] += int(recipe["ingredients"][ingredient_id])
		_state["queue"].remove_at(index)
		_commit("未开始任务已取消，材料已返还")
		return true
	return _fail("未找到该队列任务")


func move_queued_job(job_id: int, direction: int) -> bool:
	for index in range(_state["queue"].size()):
		var job: Dictionary = _state["queue"][index]
		if int(job["id"]) != job_id:
			continue
		if bool(job["started"]):
			return _fail("生产中的任务不能调整顺序")
		var target := index + (1 if direction > 0 else -1)
		if target < 0 or target >= _state["queue"].size() or bool(_state["queue"][target]["started"]):
			return _fail("该任务无法继续移动")
		var swapped: Variant = _state["queue"][target]
		_state["queue"][target] = _state["queue"][index]
		_state["queue"][index] = swapped
		_commit("已调整未开始任务的顺序")
		return true
	return _fail("未找到该队列任务")


func accept_order() -> bool:
	if not _state["active_order"].is_empty():
		return _fail("当前已有进行中的订单")
	if _state["order_offer"].is_empty():
		return _fail("暂无可接取订单")
	var offer: Dictionary = _state["order_offer"]
	_state["active_order"] = {
		"target_id": offer["target_id"],
		"required": 2,
		"reserved": 0,
		"remaining": Catalog.ORDER_DURATION,
		"ready": false,
	}
	_state["order_offer"] = {}
	_reserve_existing_items()
	_commit("已接取 %s ×2，倒计时开始" % Catalog.PRODUCT_NAMES[_state["active_order"]["target_id"]])
	return true


func deliver_order() -> bool:
	if _state["active_order"].is_empty() or not bool(_state["active_order"].get("ready", false)):
		return _fail("订单尚未完成")
	var order: Dictionary = _state["active_order"]
	var removed := 0
	for index in range(_state["finished_items"].size() - 1, -1, -1):
		var item: Dictionary = _state["finished_items"][index]
		if item["id"] == order["target_id"] and bool(item["reserved"]):
			_state["finished_items"].remove_at(index)
			_state["stock"][item["id"]] -= 1
			removed += 1
			if removed == int(order["required"]):
				break
	_state["coins"] += 60
	_state["reputation"] += 3
	_state["active_order"] = {}
	_state["order_cooldown"] = Catalog.ORDER_REFRESH_DELAY
	_try_unblock_output()
	_commit("订单交付成功，获得 60 金币与 3 口碑")
	return true


func buy_upgrade(upgrade_id: String) -> bool:
	if not Catalog.UPGRADES.has(upgrade_id):
		return _fail("未知升级")
	if bool(_state["upgrades"].get(upgrade_id, false)):
		return _fail("该升级已经购买")
	var cost: int = Catalog.UPGRADES[upgrade_id]["cost"]
	if int(_state["coins"]) < cost:
		return _fail("金币不足，还差 %d 金币" % (cost - int(_state["coins"])))
	_state["coins"] -= cost
	_state["upgrades"][upgrade_id] = true
	if upgrade_id == "production_speed":
		_apply_speed_upgrade_to_queue()
	_try_unblock_output()
	_commit("%s 已生效" % Catalog.UPGRADES[upgrade_id]["name"])
	return true


func advance(seconds: float, announce: bool = false) -> void:
	if seconds <= 0.0:
		return
	var remaining_time := seconds
	while remaining_time > 0.0001:
		_start_next_job()
		var step := remaining_time
		if not _state["queue"].is_empty() and not bool(_state["queue"][0].get("blocked", false)):
			step = minf(step, float(_state["queue"][0]["remaining"]))
		step = minf(step, float(_state["customer_timer"]))
		if not _state["active_order"].is_empty() and not bool(_state["active_order"].get("ready", false)):
			step = minf(step, float(_state["active_order"]["remaining"]))
		if _state["active_order"].is_empty() and _state["order_offer"].is_empty() and float(_state["order_cooldown"]) > 0.0:
			step = minf(step, float(_state["order_cooldown"]))
		if step <= 0.0001:
			step = minf(remaining_time, 0.0001)
		_decrement_timers(step)
		remaining_time -= step
		_resolve_events(announce)


func _decrement_timers(step: float) -> void:
	if not _state["queue"].is_empty() and not bool(_state["queue"][0].get("blocked", false)):
		_state["queue"][0]["remaining"] = maxf(0.0, float(_state["queue"][0]["remaining"]) - step)
	_state["customer_timer"] = maxf(0.0, float(_state["customer_timer"]) - step)
	if not _state["active_order"].is_empty() and not bool(_state["active_order"].get("ready", false)):
		_state["active_order"]["remaining"] = maxf(0.0, float(_state["active_order"]["remaining"]) - step)
	if _state["active_order"].is_empty() and _state["order_offer"].is_empty():
		_state["order_cooldown"] = maxf(0.0, float(_state["order_cooldown"]) - step)


func _resolve_events(announce: bool) -> void:
	if not _state["queue"].is_empty() and not bool(_state["queue"][0].get("blocked", false)) and float(_state["queue"][0]["remaining"]) <= 0.0001:
		_complete_current_job(announce)
	if float(_state["customer_timer"]) <= 0.0001:
		_attempt_sale(announce)
		_state["customer_timer"] = Catalog.CUSTOMER_INTERVAL
	if not _state["active_order"].is_empty() and not bool(_state["active_order"].get("ready", false)) and float(_state["active_order"]["remaining"]) <= 0.0001:
		_expire_order(announce)
	if _state["active_order"].is_empty() and _state["order_offer"].is_empty() and float(_state["order_cooldown"]) <= 0.0001 and int(_state["sold_since_offer"]) >= Catalog.ORDER_UNLOCK_SALES:
		_generate_order_offer(announce)


func _complete_current_job(announce: bool) -> void:
	var job: Dictionary = _state["queue"][0]
	var recipe: Dictionary = Catalog.RECIPES[job["recipe_id"]]
	if not _has_output_space(recipe["output_category"]):
		_state["queue"][0]["blocked"] = true
		if announce:
			toast_requested.emit("库存已满，生产等待空位")
		return
	_add_output(recipe["output"], recipe["output_category"])
	_state["queue"].remove_at(0)
	if announce:
		toast_requested.emit("%s 制作完成" % recipe["name"])
	_start_next_job()


func _try_unblock_output() -> void:
	if _state["queue"].is_empty() or not bool(_state["queue"][0].get("blocked", false)):
		return
	var recipe: Dictionary = Catalog.RECIPES[_state["queue"][0]["recipe_id"]]
	if _has_output_space(recipe["output_category"]):
		_state["queue"][0]["blocked"] = false
		_complete_current_job(true)


func _add_output(output_id: String, category: String) -> void:
	_state["stock"][output_id] += 1
	if category != "finished":
		return
	var reserved := false
	if not _state["active_order"].is_empty() and _state["active_order"]["target_id"] == output_id and int(_state["active_order"]["reserved"]) < int(_state["active_order"]["required"]):
		reserved = true
		_state["active_order"]["reserved"] += 1
		if int(_state["active_order"]["reserved"]) >= int(_state["active_order"]["required"]):
			_state["active_order"]["ready"] = true
			toast_requested.emit("订单已完成，可前往订单板交付")
	_state["finished_items"].append({"id": output_id, "reserved": reserved})


func _attempt_sale(announce: bool) -> void:
	for index in range(_state["finished_items"].size()):
		var item: Dictionary = _state["finished_items"][index]
		if bool(item["reserved"]):
			continue
		_state["finished_items"].remove_at(index)
		_state["stock"][item["id"]] -= 1
		_state["coins"] += Catalog.sale_price(_state, item["id"])
		_state["sold_since_offer"] += 1
		_try_unblock_output()
		if announce:
			toast_requested.emit("顾客购买了 %s" % Catalog.PRODUCT_NAMES[item["id"]])
		return


func _generate_order_offer(announce: bool) -> void:
	var target_id := "egg_pancake" if randi() % 2 == 0 else "scallion_pancake"
	_state["order_offer"] = {"target_id": target_id}
	_state["sold_since_offer"] = 0
	if announce:
		toast_requested.emit("新的特殊订单已出现")


func _reserve_existing_items() -> void:
	var order: Dictionary = _state["active_order"]
	for item in _state["finished_items"]:
		if item["id"] != order["target_id"] or bool(item["reserved"]):
			continue
		item["reserved"] = true
		order["reserved"] += 1
		if int(order["reserved"]) >= int(order["required"]):
			order["ready"] = true
			break
	_state["active_order"] = order


func _expire_order(announce: bool) -> void:
	for item in _state["finished_items"]:
		if bool(item["reserved"]):
			item["reserved"] = false
	_state["reputation"] = max(0, int(_state["reputation"]) - 1)
	_state["active_order"] = {}
	_state["order_cooldown"] = Catalog.ORDER_REFRESH_DELAY
	if announce:
		toast_requested.emit("订单已超时，口碑 -1")


func _start_next_job() -> void:
	if _state["queue"].is_empty() or bool(_state["queue"][0].get("started", false)):
		return
	_state["queue"][0]["started"] = true


func _has_output_space(category: String) -> bool:
	if category == "materials":
		return _material_count() < Catalog.material_capacity(_state)
	return _state["finished_items"].size() < Catalog.finished_capacity(_state)


func _material_count() -> int:
	var total := 0
	for item_id in ["flour", "egg", "scallion", "batter"]:
		total += int(_state["stock"].get(item_id, 0))
	return total


func _apply_speed_upgrade_to_queue() -> void:
	for job in _state["queue"]:
		if bool(job.get("started", false)):
			job["remaining"] = float(job["remaining"]) * 0.8
		else:
			job["remaining"] = Catalog.recipe_duration(_state, job["recipe_id"])


func _commit(message: String) -> void:
	_save()
	state_changed.emit(get_state())
	toast_requested.emit(message)


func _fail(message: String) -> bool:
	toast_requested.emit(message)
	return false


func _save() -> void:
	if not persistence_enabled:
		return
	_state["last_saved_unix"] = Time.get_unix_time_from_system()
	SaveManager.save_state(_state)


func _normalize_state() -> void:
	var defaults: Dictionary = Catalog.new_state()
	for key in defaults:
		if not _state.has(key):
			_state[key] = defaults[key]
	for stock_key in defaults["stock"]:
		if not _state["stock"].has(stock_key):
			_state["stock"][stock_key] = defaults["stock"][stock_key]
	for upgrade_id in defaults["upgrades"]:
		if not _state["upgrades"].has(upgrade_id):
			_state["upgrades"][upgrade_id] = false
