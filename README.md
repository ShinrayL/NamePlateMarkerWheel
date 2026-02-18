# NamePlateMarkerWheel

魔兽世界快速标记插件 - 通过双击或 Alt+点击姓名板，弹出径向轮盘快速设置团队标记。

![功能演示](https://user.shields.io/badge/WoW-12.0%2B-blue)
![版本](https://img.shields.io/badge/版本-1.0.0-green)

## 功能特性

- 🎯 **双击唤出** - 快速双击任意姓名板即可唤出标记轮盘
- ⌨️ **Alt+点击唤出** - 按住 Alt 键并点击姓名板也能唤出
- 🔥 **8种团队标记** - 径向排列的 8 个标记按钮（星星、大饼、菱形、三角、月亮、方块、叉叉、骷髅）
- ❌ **中心清除按钮** - 一键移除目标标记
- ⌨️ **ESC键关闭** - 按 ESC 键或点击外部快速关闭轮盘
- 🔄 **标记同步高亮** - 轮盘会高亮显示目标当前已有的标记

## 安装方法

### 方式一：下载即用（推荐）

1. 从 [Releases](../../releases) 下载最新版本的 `NamePlateMarkerWheel.zip`
2. 解压后将 `NamePlateMarkerWheel` 文件夹复制到：
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. 重启游戏或在角色选择界面启用插件

### 方式二：手动安装

如果你下载的是源代码，只需要 `src` 文件夹中的文件：

1. 在 `Interface\AddOns\` 下创建 `NamePlateMarkerWheel` 文件夹
2. 将 `src` 文件夹中的所有文件复制进去：
   ```
   Interface\AddOns\NamePlateMarkerWheel\
   ├── NamePlateMarkerWheel.toc
   ├── Core.lua
   ├── Utils.lua
   ├── Config.lua
   ├── Register.lua
   ├── Events.lua
   └── WheelUI.lua
   ```
3. 重启游戏

## 使用方法

### 快速标记

| 操作 | 效果 |
|------|------|
| **双击姓名板** | 唤出标记轮盘 |
| **Alt + 左键点击** | 唤出标记轮盘（备选方式）|
| **点击标记图标** | 为目标设置对应标记 |
| **点击中心按钮** | 清除目标标记 |
| **ESC 键** | 关闭轮盘 |

### 命令列表

输入 `/npw` 或 `/nameplatemarkerwheel` 查看所有命令：

```
/npw test         - 在屏幕中央显示测试轮盘
/npw tar          - 对当前目标显示轮盘
/npw te           - 查看当前目标信息
/npw debug        - 切换调试模式
/npw reset        - 重置配置
/npw status       - 查看插件状态
/npw forcereset   - 完全重置（需重载界面）
```

## 兼容性

- **游戏版本**: World of Warcraft 12.0+ (至暗之夜 / The War Within)
- **插件冲突**: 与主流姓名板插件（Plater、Threat Plates 等）兼容

## 常见问题

**Q: 双击没有反应？**
A: 请确保两次点击间隔在 0.5 秒内，且点击的是同一目标。

**Q: 战斗中可以用吗？**
A: 可以，插件使用安全按钮技术，战斗中也能正常标记。

**Q: 如何关闭轮盘？**
A: 按 ESC 键，或点击轮盘外部区域。

## 更新日志

### v1.0.0 (2026-02-19)

- ✨ 初始版本发布
- ✨ 支持双击和 Alt+点击两种触发方式
- ✨ 8种团队标记快速设置
- ✨ 标记同步高亮显示
- ✨ 战斗中完全可用

## 许可证

MIT License - 自由使用，欢迎分享

---

**提示**: 这是一个开源的魔兽世界插件，仅供学习交流使用。
