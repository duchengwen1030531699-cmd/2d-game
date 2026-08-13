# 开发者快速上手指南

> 对应版本：M1 单店可玩原型  
> 目标读者：新加入项目的开发者，或需要快速回忆项目结构的现有成员。

---

## 1. 环境准备

### 1.1 所需软件
- **Godot 4.7.1** 或更高版本（4.7+ 推荐）
  - 下载: https://godotengine.org/download
  - 版本要求: 4.7+，启用 GL Compatibility 渲染
- **Git**: 用于版本控制
- **文本编辑器**: VS Code / Godot 内置编辑器均可

### 1.2 克隆项目

```bash
git clone git@github.com:duchengwen1030531699-cmd/2d-game.git
cd 2d-game
git checkout develop
```

### 1.3 打开项目
1. 启动 Godot 4.7.1
2. 点击 "Scan" 或直接导入项目目录
3. 确认项目路径为 `2d-game/`
4. 等待导入完成（首次可能需要几秒）

## 2. 项目结构速览

```
2d-game/
├── project.godot          # 项目配置、输入映射、渲染设置
├── docs/                  # 设计文档
│   ├── GDD.md             # 主设计文档
│   ├── M1_BALANCE.md      # 数值规格
│   ├── M1_UI_FLOW.md      # 界面线框
│   ├── M1_IMPLEMENTATION.md # 实现状态
│   ├── ART_AUDIO_STYLE.md # 美术音频规范
│   └── TESTING.md         # 测试用例
├── scenes/                # 场景文件
│   ├── main.tscn          # M1 主界面
│   └── menus/main_menu.tscn
├── scripts/               # GDScript 脚本
│   ├── autoload/          # 全局单例
│   │   ├── game_manager.gd # 核心逻辑
│   │   ├── save_manager.gd # 存档读写
│   │   └── catalog.gd      # 静态数据
│   ├── main.gd            # 主界面 UI
│   └── ui/street_scroll.gd # 街区卷轴
├── assets/                # 美术音频资源
└── tests/                 # 冒烟测试
```

## 3. 运行与调试

### 3.1 运行项目
- **F5**: 运行当前场景
- **F6**: 运行主场景（需在项目设置中指定）

### 3.2 调试经营逻辑
- **输出面板**: 查看 `print()` 输出，`GameManager` 中关键操作均有 toast
- **断点调试**: 在 `game_manager.gd` 中设置断点，运行后自动命中断点
- **状态查看**: 运行中可通过 `print(GameManager.get_state())` 查看完整状态

### 3.3 快速重置存档
```gdscript
# 在脚本编辑器中运行
SaveManager.clear_save()
get_tree().quit()
```
重新运行即可获得新档（80 金币，空库存）。

### 3.4 冒烟测试
1. 打开 `tests/economy_smoke.tscn`
2. 按 F5 运行
3. 观察输出面板，看到 "Economy smoke test passed" 即通过
4. 如有失败，输出面板会显示 `Smoke test failed: ...`

## 4. 核心概念

### 4.1 单一状态源
所有经营数据存储于 `GameManager._state`（Dictionary），UI 仅做展示。修改数据必须通过 `GameManager` 提供的公共方法，禁止直接修改 `_state`。

### 4.2 信号驱动更新
- `state_changed(state)`: 数据变更后通知 UI 刷新
- `toast_requested(message)`: 请求显示轻量提示
- UI 通过连接这两个信号实现响应式更新

### 4.3 串行生产队列
- 队列中任务按顺序执行，仅队首任务处于 `started=true` 状态
- 未开始任务可取消/调整顺序，生产中的任务不可取消
- 成品库存满时，队首任务标记 `blocked=true`，待有空位自动继续

### 4.4 订单预留机制
- 接单后，目标成品产出时自动标记 `reserved=true`
- 普通顾客只能购买未预留成品
- 交付时移除对应 reserved 成品

## 5. 常见问题

### Q: 修改数值后如何生效？
直接修改 `catalog.gd` 中的常量即可，无需修改其他文件。UI 和 GameManager 均通过 Catalog 读取数据。

### Q: 如何添加新配方？
在 `catalog.gd` 的 `RECIPES` 字典中添加条目，然后在 UI 的 `_build_craft_page()` 中会自动渲染（因为遍历 Catalog.RECIPES）。

### Q: 存档文件在哪里？
- Windows: `%APPDATA%/Godot/savegame/user/m1_save.json`
- macOS: `~/Library/Application Support/Godot/savegame/user/m1_save.json`
- Linux: `~/.local/share/godot/savegame/user/m1_save.json`

### Q: 如何开启 Godot 日志？
- Editor → Editor Settings → Debug → 调整日志级别
- 或在 `project.godot` 中设置 `debug/settings/print_error_enabled=true`

### Q: 移动端测试？
- File → Export → 导出 Android APK
- 或使用 Godot Remote 在真机上调试
- 触控输入已通过 `InputEventScreenTouch/Drag` 支持

### Q: UI 在窄屏下显示异常？
当前基准为 1280×720，抽屉收起时街区占满全宽。如需支持更窄屏幕，需调整 `street_content.custom_minimum_size` 和抽屉宽度。

## 6. 开发流程

### 6.1 分支策略
- `main`: 稳定发布分支
- `develop`: 开发分支，当前主力分支
- 功能分支: `feature/xxx`，完成后合并到 develop

### 6.2 提交规范
推荐使用约定式提交（Conventional Commits）：
```
feat: 添加配方筛选功能
fix: 修复订单超时后口碑未扣除的问题
docs: 更新 M1 数值规格
refactor: 重构生产队列推进逻辑
test: 增加订单超时冒烟测试
```

### 6.3 代码风格
- 缩进: 4 空格
- 命名: 蛇形命名法
- 类型标注: 推荐使用（如 `func _ready() -> void:`）
- 信号: 使用 `signal` 关键字定义，连接时注意对象生命周期

## 7. 后续里程碑入口

| 里程碑 | 入口文档 | 关键任务 |
|--------|----------|----------|
| M2 街区扩张 | `docs/GDD.md` 第 7 节 | 多店铺、更多配方、装饰与音频 |
| M3 打磨发布 | `docs/GDD.md` 第 7 节 | 存档、移动端适配、性能优化 |

## 8. 获取帮助

- Godot 官方文档: https://docs.godotengine.org/
- 项目设计文档: `docs/` 目录
- 代码注释: `scripts/` 目录内各文件头部说明
- 问题反馈: 在 GitHub Issues 提交 bug 或建议
