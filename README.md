# 2d-game

横板 2D 冒险手游，基于 **Godot 4.7.1**（GL Compatibility 渲染）。

## 当前进度

- ✅ M0 项目骨架：目录结构、输入映射、主菜单、设计文档
- ⬜ M1 可玩原型（玩家控制器 + 测试关卡 + 敌人 + HUD）
- ⬜ M2 内容填充（3 世界关卡、BOSS、美术音频）
- ⬜ M3 打磨发布（真机适配、Android 导出）

详细设计见 [docs/GDD.md](docs/GDD.md)。

## 快速开始

1. 用 Godot 4.7.1 打开本目录（导入 `project.godot`）。
2. 按 F5 运行，进入主菜单。
3. 「开始游戏」进入开发测试场景 `scenes/main.tscn`。

## 开发期操作（键盘）

- A/D 或 ←/→：左右移动
- W/Space：跳跃
- Shift/K：冲刺
- J：攻击
- P/Esc：暂停

## 目录结构

```
2d-game/
├── project.godot      # Godot 项目配置
├── icon.svg           # 项目图标
├── docs/GDD.md        # 游戏设计文档
├── scenes/            # 场景（菜单/关卡/UI）
├── scripts/           # GDScript 脚本
└── assets/            # 美术、音频、字体
```