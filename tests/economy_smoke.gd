extends Node


func _ready() -> void:
	GameManager.persistence_enabled = false
	GameManager._state = Catalog.new_state()
	GameManager._state["customer_timer"] = 100.0

	_check(GameManager.purchase({"flour": 2, "egg": 1}), "可购买制作鸡蛋饼的原料")
	_check(GameManager.enqueue_recipe("batter"), "可将面糊加入队列")
	GameManager.advance(6.0)
	_check(int(GameManager._state["stock"]["batter"]) == 1, "面糊应在 6 秒后完成")
	_check(GameManager.enqueue_recipe("egg_pancake"), "可将鸡蛋饼加入队列")
	GameManager.advance(10.0)
	_check(GameManager._state["finished_items"].size() == 1, "鸡蛋饼应进入成品库存")
	GameManager._state["customer_timer"] = 0.0
	GameManager.advance(0.1)
	_check(int(GameManager._state["coins"]) == 94, "顾客售卖后金币应正确增加")
	_check(int(GameManager._state["sold_since_offer"]) == 1, "售卖应累计订单解锁进度")

	GameManager._state["sold_since_offer"] = Catalog.ORDER_UNLOCK_SALES
	GameManager.advance(0.1)
	_check(not GameManager._state["order_offer"].is_empty(), "达到售卖条件后应生成待接订单")
	_check(GameManager.accept_order(), "待接订单可被玩家接取")
	_check(not GameManager._state["active_order"].is_empty(), "接取后订单应进入活动状态")

	GameManager._state["coins"] = 600
	_check(GameManager.buy_upgrade("production_speed"), "金币充足时可购买生产速度升级")
	_check(bool(GameManager._state["upgrades"]["production_speed"]), "生产速度升级状态应保存")

	print("Economy smoke test passed")
	get_tree().quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("Smoke test failed: %s" % message)
	get_tree().quit(1)
