# NamePlateMarkerWheel

一个魔兽世界插件，通过 Alt+点击姓名板弹出径向轮盘，让玩家能够快速直观地设置团队标记。

## 功能特性

- 🎯 **Alt+点击唤出轮盘** - 按住 Alt 键并点击任意姓名板，快速唤出标记轮盘
- 🔥 **8种团队标记** - 径向排列的 8 个标记按钮（星星、大饼、菱形、三角、月亮、方块、叉叉、骷髅）
- ❌ **中心清除按钮** - 一键移除目标标记
- ⌨️ **ESC键关闭** - 按 ESC 键快速关闭轮盘
- 🔗 **安全按钮实现** - 使用 `SecureActionButtonTemplate` 确保战斗中可用
- 🔄 **标记同步高亮** - 轮盘会高亮显示目标当前已有的标记

## 安装方法

1. 下载最新版本
2. 将 `NamePlateMarkerWheel` 文件夹复制到 `World of Warcraft\_retail_\Interface\AddOns\`
3. 重启游戏或在角色选择界面点击"插件"按钮启用

## 使用方法

### 基本操作

- **Alt + 左键点击姓名板** - 唤出标记轮盘
- **点击标记图标** - 为目标设置对应标记
- **点击中心按钮** - 清除目标标记
- **ESC 键** - 关闭轮盘

### 斜杠命令

```
/npw              - 显示命令列表
/npw test         - 在屏幕中央显示测试轮盘
/npw tar          - 对当前目标显示轮盘
/npw te           - 查看当前目标信息
/npw debug        - 切换调试模式
/npw reset        - 重置配置
/npw status       - 查看插件状态
```

## 开发状态

### 已实现功能

- ✅ Alt+点击唤出轮盘
- ✅ 径向轮盘 UI（8个标记按钮）
- ✅ 标记设置功能（安全按钮）
- ✅ 中心清除按钮
- ✅ ESC键关闭轮盘
- ✅ 标记同步高亮显示
- ✅ 配置系统（SavedVariables）
- ✅ 斜杠命令支持

### 待实现功能

- ⏳ 打开/关闭动画
- ⏳ 音效反馈
- ⏳ 图形化配置界面

## 技术说明

### 核心实现

- **事件检测**: 使用 `WorldFrame:HookScript("OnMouseDown")` 检测 Alt+点击
- **安全按钮**: 使用 `SecureActionButtonTemplate` 创建标记按钮，确保战斗中可用
- **宏格式**: `/tm [@target] N` (N = 0-8, 0为清除)

### 文件结构

```
NamePlateMarkerWheel/
├── NamePlateMarkerWheel.toc  # 插件描述文件
├── Core.lua                  # 核心逻辑/初始化
├── WheelUI.lua              # 轮盘 UI 实现
├── Events.lua               # Alt+点击检测/事件处理
├── Config.lua               # 配置管理
├── Register.lua             # 斜杠命令注册
└── Utils.lua                # 工具函数
```

## 兼容性

- **游戏版本**: World of Warcraft 12.0+ (至暗之夜/Midnight)
- **插件冲突**: 理论上与其他姓名板插件兼容

## 更新日志

### v1.0.0 (2026-02-19)

- 初始版本发布
- 实现核心标记功能
- 支持 Alt+点击唤出轮盘
- 支持标记同步高亮

## 贡献

欢迎提交 Issue 和 Pull Request。

## 许可证

MIT License

---

**注意**: 这是一个魔兽世界插件，仅供学习交流使用。
