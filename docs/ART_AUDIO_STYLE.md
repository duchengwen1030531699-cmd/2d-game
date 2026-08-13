# 美术与音频资源规范

> 对应版本：M1 单店可玩原型，后续里程碑适用  
> 目的：统一资源命名、尺寸、格式与替换流程，便于美术与程序协作。

---

## 1. 命名约定

### 1.1 文件命名
- 统一使用 **蛇形命名**：`breakfast_shop.tscn`、`egg_pancake.png`
- 场景文件与脚本文件同名：`main.gd` ↔ `main.tscn`
- 资源按类型分组存放：

```
assets/
├── sprites/
│   ├── buildings/      # 街区建筑：supplier.tscn、breakfast_shop.tscn
│   ├── ui/             # UI 元素：button_normal.png、panel_bg.png
│   └── icons/          # 图标：coin.png、reputation.png
├── audio/
│   ├── bgm/            # 背景音乐（M2+）
│   └── sfx/            # 音效：purchase.wav、complete.wav
└── fonts/
    └── noto_sans_sc.ttf
```

### 1.2 内部节点命名
- Godot 节点使用 **蛇形小写**：`purchase_button`、`queue_container`
- UI 控件通过 `name` 属性区分：`coins_label`、`toast_timer`

## 2. 美术资源规格

### 2.1 基础设定
- **基准分辨率**: 1280×720
- **渲染方式**: GL Compatibility，CanvasItem 2D
- **拉伸模式**: `canvas_items` + `expand`，保持宽高比
- **色彩风格**: 奶油色、橙色、草绿色，温暖扁平插画风

### 2.2 尺寸规范

| 元素 | 建议尺寸 | 说明 |
|------|----------|------|
| 建筑按钮 | 250×150 px | 街区中的供应商/早餐店/订单板/升级入口 |
| 右侧入口按钮 | 64×64 px | 竖向导航栏 |
| 抽屉宽度 | 收起 64px / 展开 360px | 内容区 296px |
| 资源标签 | 100×30 px | 顶部资源栏 |
| Toast | 380×42 px | 轻量提示 |
| 卡片 | 内容自适应，最小高度按内容 | 圆角 10px |

### 2.3 格式与优化
- **格式**: PNG（支持透明）或 SVG（图标/矢量图）
- **压缩**: 使用 `basis_universal` 纹理压缩，减少内存占用
- **导入设置**:
  - 禁用 mipmap（2D UI 不需要）
  - 滤镜: `Nearest` 用于像素风，`Linear` 用于平滑插值
  - 最大分辨率: 2048×2048（M1 不需要更大）

### 2.4 Placeholder 替换流程
1. 开发阶段使用 `ColorRect` + `StyleBoxFlat` 占位
2. 确定最终尺寸后导出对应 PNG
3. 替换时保持节点结构不变，仅更换 `texture` 属性
4. 美术资源放入 `assets/sprites/`，通过 Godot 导入器管理

## 3. UI 组件规范

### 3.1 按钮
- 正常态: 奶油底 + 棕色文字
- 悬停态: 浅橙底
- 按下态: 深橙底
- 禁用态: 降低透明度至 50%
- 圆角: 9px
- 字体大小: 14px（正文）、15px（卡片）、19px（建筑按钮）

### 3.2 卡片
- 背景: `fff8ee` 奶油色
- 边框: `e6d5c4` 浅棕色，1px
- 圆角: 10px
- 内边距: 水平 10px，垂直 6px
- 卡片间距: 10px

### 3.3 抽屉与面板
- 抽屉背景: `fffdf8` 米白色
- 分隔线: `e6d5c4`
- 滚动条样式: 自定义细滚动条，宽度 6px

## 4. 音频资源规范

### 4.1 格式
- **音效**: WAV（短促音效）或 OGG Vorbis（较长音效）
- **BGM**: OGG Vorbis，M2+ 引入
- **采样率**: 44.1kHz
- **位深度**: 16-bit

### 4.2 命名约定

| 事件 | 建议文件名 | 说明 |
|------|------------|------|
| 采购完成 | `purchase_complete.wav` | 轻快短音 |
| 任务完成 | `craft_complete.wav` | 满足感音效 |
| 订单接取 | `order_accepted.wav` | 叮咚声 |
| 订单交付 | `order_delivered.wav` | 奖励音效 |
| 升级成功 | `upgrade_bought.wav` | 提升感 |
| 错误提示 | `error.wav` | 柔和提示音 |
| 顾客购买 | `customer_purchase.wav` | 金币声 |

### 4.3 音量规范
- 音效: 基准 0 dB，峰值不超过 -3 dB
- BGM: -12 dB 基准，可淡入淡出
- 提供全局音量滑块（M2+）

### 4.4 播放时机
- 采购成功: `GameManager.purchase()` 返回 true 时
- 任务完成: `_complete_current_job()` 中
- 订单接取: `accept_order()` 中
- 订单交付: `deliver_order()` 中
- 升级购买: `buy_upgrade()` 中
- 顾客购买: `_attempt_sale()` 中

## 5. 字体规范

### 5.1 字体选择
- **首选**: 思源黑体 / Noto Sans SC（中文友好）
- **备选**: 系统默认无衬线字体
- 存放路径: `assets/fonts/`

### 5.2 字号体系

| 用途 | 字号 | 字重 |
|------|------|------|
| 页面标题 | 20px | Regular |
| 区块标题 | 17px | Regular |
| 卡片标题 | 15px | Regular |
| 正文 | 14px | Regular |
| 辅助文字 | 13px | Regular |
| Toast | 16px | Regular |
| 建筑按钮 | 19px | Regular |

### 5.3 颜色
- 主色: `#4a3426` 深棕色（文字）
- 辅助色: `#806b5a` 灰棕色（次要信息）
- 警示色: `#e7773b` 橙色（操作按钮）
- 背景色: `#fff8ec` 奶油色

## 6. 性能与导出注意事项

- 2D 项目避免使用 3D 资源，保持包体小巧
- 音频统一使用压缩格式，WAV 仅用于极短音效
- 图集（Atlas）用于批量 UI 元素，减少 draw call
- Android 导出时启用 ASTC 纹理压缩
