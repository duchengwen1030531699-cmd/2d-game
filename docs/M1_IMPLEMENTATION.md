# M1 实现状态与架构说明

> 对应版本：M1 单店可玩原型  
> 本文档对齐 docs/GDD.md、docs/M1_BALANCE.md、docs/M1_UI_FLOW.md，梳理当前代码结构、模块职责、数据流与待完成项。

---

## 1. 整体架构

```
scenes/
├── main.tscn                # M1 经营主界面
├── menus/main_menu.tscn     # 启动菜单
└── ...

scripts/
├── main.gd                  # 主界面 UI 控制器
├── autoload/
│   ├── game_manager.gd      # 经营状态机（核心逻辑）
│   ├── save_manager.gd      # 单档自动保存
│   └── catalog.gd           # 静态数据：配方、原料、升级、价格
├── menus/main_menu.gd       # 菜单按钮逻辑
└── ui/
    └── street_scroll.gd     # 街区横向卷轴交互

tests/
├── economy_smoke.tscn       # 经济冒烟测试场景
└── economy_smoke.gd         # 冒烟测试脚本
```

## 2. 模块职责

| 模块 | 文件 | 职责 | 状态 |
|------|------|------|------|
| **GameManager** | `game_manager.gd` | 经营状态机，处理采购、排产、订单、升级、离线结算 | ✅ 已实现 |
| **Catalog** | `catalog.gd` | 静态数据定义：原料价格、配方、升级效果、容量上限 | ✅ 已实现 |
| **SaveManager** | `save_manager.gd` | 单档自动保存，文件路径 `user://m1_save.json` | ✅ 已实现 |
| **主界面** | `main.gd` | UI 构建与交互：采购页、制作页、订单页、升级页、toast | ✅ 已实现 |
| **街区卷轴** | `street_scroll.gd` | 横向拖拽浏览，12px 拖拽阈值，区分点击与滑动 | ✅ 已实现 |
| **主菜单** | `main_menu.gd` | 开始游戏、设置、退出 | ✅ 已实现 |
| **冒烟测试** | `economy_smoke.gd` | 验证采购→排产→售卖→订单→升级基础闭环 | ✅ 已实现 |

## 3. 数据流

```
玩家操作
    │
    ▼
UI (main.gd)
    │ 调用 GameManager 方法
    ▼
GameManager (game_manager.gd)
    │ 修改 _state
    │ 调用 Catalog 查询静态数据
    │ 触发 state_changed 信号
    ▼
UI 刷新 + 自动保存
```

### 3.1 状态字典结构

`GameManager._state` 为单一状态源，包含：

```gdscript
{
    "coins": 80,                    # 金币
    "reputation": 0,                # 口碑
    "stock": {
        "flour": 0,                 # 原料
        "egg": 0,
        "scallion": 0,
        "batter": 0,                # 中间品
        "egg_pancake": 0,           # 成品
        "scallion_pancake": 0
    },
    "finished_items": [],           # 成品列表 [{id, reserved}]
    "queue": [],                    # 生产队列 [{id, recipe_id, remaining, started, blocked}]
    "next_job_id": 1,               # 任务 ID 自增
    "customer_timer": 8.0,          # 顾客购买倒计时
    "sold_since_offer": 0,          # 当前订单周期售出数
    "order_offer": {},              # 待接订单 {target_id}
    "active_order": {},             # 活动订单 {target_id, required, reserved, remaining, ready}
    "order_cooldown": 0.0,          # 订单刷新冷却
    "upgrades": {
        "production_speed": false,
        "storage": false,
        "counter": false
    },
    "last_saved_unix": 1234567890   # 最后保存时间
}
```

## 4. 核心机制实现

### 4.1 采购
- UI: `_build_purchase_page()` + SpinBox 数量输入
- 逻辑: `GameManager.purchase(items)` 校验金币、容量，更新 stock
- 反馈: toast 提示成功/失败原因

### 4.2 生产队列
- UI: `_build_craft_page()` 显示配方卡与队列状态
- 逻辑:
  - `enqueue_recipe()` 预留原料，加入队列
  - `_start_next_job()` 标记队首为 started
  - `advance()` 推进计时器，处理完成/阻塞
  - `cancel_queued_job()` / `move_queued_job()` 仅允许未开始任务
- 特性: 串行执行，成品满时阻塞，空位后自动继续

### 4.3 顾客与订单
- 顾客: `_attempt_sale()` 每 8 秒尝试购买 1 份未预留成品
- 订单生成: `_generate_order_offer()` 累计 3 次售卖后生成
- 订单流程: 接取 → 预留 → 倒计时 → 交付/超时
- 奖励: 60 金币 + 3 口碑；超时 -1 口碑

### 4.4 升级
- UI: `_build_upgrades_page()` 显示升级卡
- 逻辑: `buy_upgrade()` 检查金币，立即生效
- 效果:
  - 生产速度: 所有配方时间 ×0.8
  - 库存容量: 原料 20→30，成品 8→12
  - 柜台销售: 售价 ×1.2

### 4.5 离线结算
- 入口: `_ready()` 读取存档后计算 `min(当前时间 - 最后保存时间, 7200秒)`
- 推进: `advance(offline_seconds)` 按事件顺序结算
- 限制: 最多结算 2 小时

## 5. 当前完成度

### ✅ 已完成
- 主菜单与经营主界面
- 采购、排产、订单、升级四大功能页
- 串行生产队列与阻塞机制
- 普通顾客自动购买
- 特殊订单完整生命周期
- 三项升级及效果
- 单档自动保存（操作/后台/退出时）
- 2 小时离线结算上限
- 街区横向卷轴交互
- 经济冒烟测试

### 🚧 待完善 / 已知问题
- **缺少主场景引用**: `main.tscn` 是否存在且正确引用 `main.gd` 尚待确认
- **缺少设置页**: M1_BALANCE.md 提到设置页，但当前主菜单设置按钮仅打印日志
- **新手引导**: M1_UI_FLOW.md 提到 tutorial_highlight，UI 中未实现
- **UI 尺寸校准**: 抽屉宽度与街区尺寸按 UI_FLOW 文档实现，需在实际分辨率下验证
- **订单状态同步**: 订单页与任务条状态一致性已验证逻辑，建议增加手动测试用例
- **性能**: 15 秒自动保存对移动端待实测，可能需延长至 30 秒
- **多语言**: 当前为中文硬编码，后续如需国际化需抽离

## 6. 后续扩展建议

### M2 街区扩张
- 新增 `DistrictManager` 管理多店铺状态
- `Catalog` 扩展为数据驱动，支持多店配方差异
- 街区镜头管理多店铺位置与切换

### M3 打磨
- 音效系统接入（`AudioManager`）
- 云端存档（可选）
- 性能分析：Profiler 检测 UI 重建开销
- 导出 Android 测试
