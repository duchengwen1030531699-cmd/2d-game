# 晨光街开发规范

> 目标引擎：Godot 4.7.1（GL Compatibility）  
> 作用：约束后续所有代码编写，避免凭记忆写 API。  
> 原则：只使用项目已验证的模式；未经验证的 API 必须先查 Godot 官方文档或现有代码。

---

## 1. 总规则

- **只复用项目里已验证过的写法**，不凭记忆写新 API。
- 写新代码前，先找同类旧代码做参照。
- 不确定的 API，先查官方文档或现有代码，不要猜。
- 本项目缩进使用 **Tab**，不使用空格。
- GDScript 类型标注推荐写全：`func _ready() -> void:`、`var x: int = 0`。

---

## 2. 已验证可用的 API 清单

以下 API 已经在项目中实际使用且运行正常，**优先复用**：

### 2.1 Control / UI 布局
```gdscript
# 正确：全屏布局
node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# 正确：样式覆写
button.add_theme_font_size_override("font_size", 14)
button.add_theme_color_override("font_color", Color.WHITE)
button.add_theme_stylebox_override("normal", _stylebox(Color("fff8ee"), 10, COLOR_LINE))

# 正确：容器间距
container.add_theme_constant_override("separation", 10)
```

### 2.2 场景切换
```gdscript
# 正确：切换场景
get_tree().change_scene_to_file("res://scenes/main.tscn")

# 禁止：pop_scene_from_stack() —— 本项目不使用，且不是 Godot 4 SceneTree 的标准 API
```

### 2.3 信号定义与连接
```gdscript
# 定义信号
signal state_changed(state: Dictionary)
signal toast_requested(message: String)

# 连接信号
GameManager.state_changed.connect(_on_state_changed)
button.pressed.connect(func() -> void: _show_page(page))
```

### 2.4 输入事件（街卷轴已验证）
```gdscript
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _pressed = event.pressed
        _start_position = event.position
        _start_scroll = scroll_horizontal
        return
    if event is InputEventMouseMotion and _pressed:
        _handle_drag(event.position)
        return
    if event is InputEventScreenTouch:
        _pressed = event.pressed
        _start_position = event.position
        _start_scroll = scroll_horizontal
        return
    if event is InputEventScreenDrag and _pressed:
        _handle_drag(event.position)

# 阻止事件继续传播
accept_event()
```

### 2.5 文件与数据持久化
```gdscript
# 读取
var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
var text := file.get_as_text()

# 写入
var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
file.store_string(JSON.stringify(payload))
file.close()

# 重命名/删除
DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
DirAccess.remove_absolute(SAVE_PATH)

# JSON 解析
var parsed: Variant = JSON.parse_string(text)

# 路径约定
res://  # 项目资源
user://  # 用户数据/存档
```

### 2.6 时间与随机
```gdscript
Time.get_unix_time_from_system()
randi()
clampf(value, min, max)
minf(a, b)
maxf(a, b)
```

### 2.7 日志与警告
```gdscript
print("message")
push_warning("warning message")
push_error("error message")
```

### 2.8 节点与生命周期
```gdscript
# 添加子节点
add_child(node)

# 移除子节点
child.queue_free()

# 查找子节点
var child = get_node("NodePath")
var child = $NodeName
var found = find_child("name", true, false)

# 实例校验
if not is_instance_valid(node):
    return

# 预加载资源
var script = preload("res://scripts/example.gd")
```

---

## 3. 命名约定

### 3.1 文件与目录
- 脚本与场景同名：`main.gd` ↔ `main.tscn`
- 蛇形命名：`street_scroll.gd`、`settings_button`
- 目录按职责分组：`scripts/autoload/`、`scripts/ui/`、`scenes/menus/`

### 3.2 代码命名
- 私有变量：`_coins_label`、`_state`
- 私有函数：`_build_interface()`、`_on_state_changed()`
- 常量：`COLOR_CREAM`、`MAX_OFFLINE_SECONDS`
- 信号/全局函数：驼峰或蛇形均可，保持项目内一致

### 3.3 场景节点命名
- 使用蛇形小写：`settings_button`、`queue_container`
- 在 `.tscn` 中保持路径清晰

---

## 4. UI 构建模式（以 main.gd 为准）

本项目 UI 采用 **代码动态构建**，参考 `scripts/main.gd`：

### 4.1 基本结构
```gdscript
func _build_interface() -> void:
    # 1. 背景
    var background := ColorRect.new()
    background.color = COLOR_CREAM
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    # 2. 主布局
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 0)
    add_child(layout)

    # 3. 各区域按顺序加入 layout
```

### 4.2 辅助函数集合
以下 helper 已在 `main.gd` 中实现，**新 UI 直接复用或改造**：
- `_label(text, font_size, color)` → Label
- `_card(content)` → PanelContainer + StyleBox
- `_action_button(text)` → Button + 橙色样式
- `_section_label(text)` → 区块标题
- `_stylebox(color, radius, border_color)` → StyleBoxFlat
- `_page_heading(title, note)` → 页面标题 + 关闭按钮
- `_resource_label(text)` → 顶部资源标签

### 4.3 页面切换逻辑
```gdscript
func _show_page(page: String) -> void:
    _active_page = page
    _drawer.custom_minimum_size.x = 64 if page == "none" else 360
    _drawer_scroll.visible = page != "none"
    for page_id in _nav_buttons:
        _nav_buttons[page_id].button_pressed = page_id == page
    if page == "none":
        return
    _rebuild_active_page()
```

---

## 5. 数据流规范

### 5.1 单一状态源
- 所有经营数据统一存放在 `GameManager._state`（Dictionary）
- UI 只读状态，不直接修改数据
- 修改数据必须通过 `GameManager` 提供的公共方法

### 5.2 信号驱动 UI 更新
```gdscript
# 数据变更后
state_changed.emit(get_state())

# UI 响应
GameManager.state_changed.connect(_on_state_changed)
```

### 5.3 存档路径约定
```gdscript
const SAVE_PATH := "user://m1_save.json"
const TEMP_PATH := "user://m1_save.tmp"
```

---

## 6. 禁止使用的 API / 写法

以下写法**本项目不使用或已验证有问题**：

| 禁止项 | 原因 | 正确替代 |
|--------|------|----------|
| `set_anchors_and_presets()` | 方法名错误，不存在 | `set_anchors_and_offsets_preset()` |
| `pop_scene_from_stack()` | 不是 Godot 4 SceneTree 标准 API | `change_scene_to_file()` |
| `add_child(self)` 或递归添加自己 | 导致栈溢出 | 检查子节点引用 |
| 直接修改 `GameManager._state` | 破坏单一状态源 | 使用公共方法 |
| 空格缩进 | 项目统一使用 Tab | 编辑器设置 Tab 缩进 |
| `res://` 用于存档 | 应为只读资源路径 | 使用 `user://` |

---

## 7. 新增代码检查清单

写新代码前，逐项确认：

- [ ] 是否参考了同类现有代码？
- [ ] 使用的 API 是否在“已验证 API 清单”中？
- [ ] 如果不在清单中，是否查过 Godot 4.7 官方文档？
- [ ] 缩进是否为 Tab？
- [ ] 是否写了类型标注？
- [ ] 是否遵循命名约定？
- [ ] 是否有 `_fail()` 或 toast 反馈？
- [ ] 是否通过信号更新 UI，而不是直接操作 UI 节点？

---

## 8. 参考文件

写代码时的首选参考顺序：

1. `scripts/main.gd` — UI 构建范本
2. `scripts/autoload/game_manager.gd` — 状态管理与业务逻辑
3. `scripts/autoload/catalog.gd` — 静态数据定义
4. `scripts/ui/street_scroll.gd` — 输入交互
5. `scripts/settings/settings.gd` — 设置页（需修正后作为参考）
6. Godot 4.7 官方文档：https://docs.godotengine.org/

---

## 9. 修正优先级

当前代码中需要按本规范修正的优先级：

1. **P0** `scripts/settings/settings.gd` — 作为新参考模板，必须修正所有 API
2. **P1** 新增场景/脚本时，对照本规范审查
3. **P2** 逐步将现有 helper 函数沉淀到 `docs/DEVELOPER_GUIDE.md`
