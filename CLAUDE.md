# NamePlateMarkerWheel 项目开发指南

## 项目概述

**NamePlateMarkerWheel** 是一个魔兽世界插件，通过 Alt+点击姓名板弹出径向轮盘的方式，让玩家能够快速直观地设置团队标记。

## 研发进度

### P0 - 核心功能
- ✅ Alt+点击唤出轮盘 (`Events.lua`) - **已修复，可正常唤出**
- ✅ 双击唤出轮盘 (`Events.lua`) - **已实现，300ms 内双击同一目标**
- ✅ 径向轮盘UI (`WheelUI.lua`) - **显示正常**
- ✅ 标记设置功能 (`WheelUI.lua`, `SecureActionButtonTemplate`) - **已修复，按钮点击可设置标记**
- ✅ 测试命令 `/npw test` 可正常唤出轮盘
- ✅ 测试命令 `/npw tar` 可针对目标唤出轮盘
- ✅ 安全按钮宏更新 (`Core.lua`)

### 已完成 (P1 - 交互增强)
- ✅ 中心清除按钮
- ✅ ESC键关闭轮盘
- ✅ 点击外部关闭轮盘

### 已完成 (P2 - 配置系统)
- ✅ 配置管理 (`Config.lua`)
- ✅ 斜杠命令 (`/npw`, `/npw test`, `/npw debug`, `/npw tar`)
- ✅ SavedVariables 持久化

### 已完成 (P3 - 高级功能)
- ✅ 标记同步高亮显示 - **已实现，使用 GetRaidTargetIndex 高亮当前标记**

### 待完成 (P3 - 高级功能)
- ⏳ 打开/关闭动画
- ⏳ 音效反馈
- ⏳ 图形化配置界面

### 已完成 (测试)
- ✅ 修复 `/npw tar` 命令无法唤出轮盘的问题
- ✅ 修复已标记目标无法重新唤出轮盘的问题
- ✅ 游戏内完整测试验证 - **核心功能验证通过**

### 待完成 (测试)
- ⏳ 单元测试文件

## 项目结构

```
.
├── specs/
│   └── NamePlateMarkerWheel-spec.md    # 功能规格文档
├── src/
│   ├── NamePlateMarkerWheel.toc        # 插件描述文件
│   ├── Core.lua                        # 核心逻辑/初始化
│   ├── WheelUI.lua                     # 轮盘UI实现
│   ├── Events.lua                      # Alt+点击检测/事件处理
│   ├── Config.lua                      # 配置管理
│   ├── Register.lua                    # 斜杠命令注册
│   └── Utils.lua                       # 工具函数
├── test/
│   └── TDD_TEST_CHECKLIST.md           # 测试清单
├── sync.bat                            # Windows批处理同步脚本
├── sync.ps1                            # PowerShell同步脚本
├── sync.sh                             # Bash同步脚本(WSL/Git Bash)
└── .claude/
    ├── doc/
    │   └── 需求文档.md                  # 中文需求文档
    └── skills/                          # TDD/SDD Agent配置
```

## 代码文件职责

| 文件 | 职责 |
|------|------|
| `Core.lua` | 插件初始化、安全按钮宏更新、核心状态管理 |
| `WheelUI.lua` | 轮盘创建、8个标记按钮+清除按钮、显示/隐藏逻辑、GUID解析 |
| `Events.lua` | Alt+点击检测、WorldFrame钩子、事件处理 |
| `Config.lua` | 配置管理、默认值、配置重置 |
| `Register.lua` | 斜杠命令注册 (`/npw test`, `/npw tar` 等) |
| `Utils.lua` | 常量定义、数学计算(角度/位置)、工具函数 |

## 关键实现细节

### 唤出轮盘触发方式（双击 + Alt+点击）
- 方式: WorldFrame HookScript OnMouseDown + 双击检测/Alt键检测
- 位置: `Events.lua` 第53-108行
- 流程:
  1. 钩住 WorldFrame 的 OnMouseDown 事件
  2. 检测触发条件：
     - **双击**: 同一目标，两次点击间隔 <= 300ms
     - **Alt+点击**: 按住 Alt 键点击
  3. 获取目标 GUID (`UnitGUID("target")`)
  4. 调用 `ShowWheel()` 显示轮盘（传递GUID）
- 双击阈值: `DOUBLE_CLICK_THRESHOLD = 300` (毫秒)

### 安全按钮
- 使用 `SecureActionButtonTemplate` 直接创建视觉按钮
- 按钮创建: `CreateFrame("Button", ..., parent, "SecureActionButtonTemplate")`
- 类型: `macro`
- 宏格式: `/tm [@unit] <index>`
- 动态更新: `ShowWheel()` 时通过 `SetAttribute("macrotext", ...)` 更新
- 关键点: 主框架 `EnableMouse(false)` 确保按钮直接接收硬件点击

### GUID 识别（2026-02-19 重构）
- **核心变更**: 从使用 unit token 改为使用 GUID 作为目标主要标识
- **原因**: GUID 是恒定不变的，unit token（如 nameplate1）会随姓名板变化
- **流程**:
  1. `Events.lua` 获取目标 GUID
  2. `ShowWheel()` 接收 GUID 参数
  3. `GetUnitFromGUID()` 从 GUID 解析当前可用的 unit token
  4. `UpdateSecureButtonMacros()` 使用解析出的 unit token 更新宏

### 坐标处理
- 使用 `GetCursorPosition()` 获取鼠标位置
- 使用 `UIParent:GetEffectiveScale()` 处理UI缩放
- 轮盘位置: `UIParent:BOTTOMLEFT` 锚点

## 修复记录

| 问题 | 修复文件 | 修复内容 | 状态 |
|------|----------|----------|------|
| 视角无法拖动 | `Events.lua` | 移除覆盖全屏的鼠标监听帧，改用 WorldFrame HookScript | 已修复 |
| 标记不工作 | `WheelUI.lua` | 将 `EnableMouse(true)` 改为 `EnableMouse(false)`，让按钮直接接收点击 | 已修复 |
| 双击检测不工作 | `Events.lua` | 方案改为 Alt+点击，WorldFrame OnMouseDown 检测 | 已修复 |
| Alt+点击轮盘不显示 | `Events.lua` | 移除姓名板强制检查，允许无姓名板时唤出 | 已修复 |
| 标记按钮点击无效 | `WheelUI.lua`, `Core.lua` | 安全按钮与视觉按钮合并，使用 `LeftButtonDown` 注册点击 | 已修复 |
| `/npw tar` 命令无效 | `Core.lua`, `WheelUI.lua` | 简化 `GetUnitFromGUID` 直接返回 "target"，修复循环中按钮更新问题 | 已修复 |
| 已标记目标无法唤出轮盘 | `WheelUI.lua` | 修复 `UpdateCurrentMarkHighlight` 中 `GetRaidTargetIndex` 错误处理，添加 `pcall` 保护 | 已修复 |
| 循环只执行一次 | `Core.lua` | 移除了 `SetAttribute("npw-guid")` 的无效属性设置，该设置会导致 Lua 错误中断循环 | 已修复 |

## 架构变更记录

### 2026-02-18 - 安全按钮架构重构

**问题原因**: `SecureActionButtonTemplate` 的 `:Click()` 方法不会触发安全动作，必须由真实硬件事件触发。

**解决方案**: 将安全按钮与视觉按钮合并，直接创建带 `SecureActionButtonTemplate` 的视觉按钮。

**变更文件**:
- `WheelUI.lua:CreateMarkButton()` - 使用 `SecureActionButtonTemplate` 创建按钮
- `WheelUI.lua:CreateClearButton()` - 使用 `SecureActionButtonTemplate` 创建按钮
- `WheelUI.lua` - 主框架 `EnableMouse(false)` 避免拦截点击

### 2026-02-19 - 双击 + Alt+点击双重触发支持

**需求**: 同时支持双击和 Alt+点击两种方式唤出轮盘

**实现逻辑**:
- 双击检测：两次点击同一目标且时间间隔 <= 500ms
- Alt+点击：按住 Alt 键点击目标
- 两种方式独立，满足任一条件即可唤出轮盘

**变更文件**:
- `Core.lua` - state 中使用 `lastClickGUID` 替代 `lastClickUnit`，双击阈值 500ms
- `Events.lua:OnWorldFrameMouseDown()` - 重构点击检测逻辑
- `Events.lua:ProcessClick()` - 新增，统一处理点击检测
- `Events.lua:ResetClickState()` - 新增，重置点击状态
- 清理 Events.lua 和 Core.lua 中的调试输出

### 2026-02-19 - GUID 识别重构

**问题原因**: unit token（如 nameplate1, nameplate2）会随姓名板变化，不可靠。

**解决方案**: 使用 GUID 作为主要标识，每次唤出时动态解析当前可用的 unit token。

**变更文件**:
- `Core.lua` - 添加 `currentGUID` 状态字段
- `Events.lua` - 传递 GUID 而不是 unit token
- `WheelUI.lua:ShowWheel()` - 接收 GUID，调用 `GetUnitFromGUID()`
- `WheelUI.lua:GetUnitFromGUID()` - 新增，从 GUID 解析 unit token
- `WheelUI.lua:UpdateSecureButtonMacros()` - 接收 GUID 参数

## 开发方法

本项目遵循 **SDD (Spec-Driven Development)** 和 **TDD (Test-Driven Development)**:

1. 编写规格文档 (`specs/`)
2. 编写测试清单 (`test/`)
3. 实现功能 (`src/`)
4. 游戏内测试验证

## 测试命令

```bash
# 游戏中测试轮盘显示（对自己）
/npw test

# 对当前目标测试轮盘
/npw tar

# 查看目标 GUID 和 unit token
/npw te

# 重置配置
/npw reset

# 切换调试模式
/npw debug

# 查看状态
/npw status

# 完全重置（需重载）
/npw forcereset
```

## 同步脚本

项目提供三个同步脚本，将代码复制到 WoW 插件目录：

```bash
# Windows 批处理（推荐）
.\sync.bat

# PowerShell
.\sync.ps1

# Bash (WSL/Git Bash)
bash sync.sh
```

## 已知问题

1. **✅ 标记按钮点击后无反应** - 已修复，主框架 `EnableMouse(false)` 解决
2. **✅ Alt+点击轮盘不显示** - 已修复
3. **⏳ `/npw tar` 命令唤不出轮盘** - 调试中，日志显示到 `ShowWheel` 调用后中断
4. 缺少打开/关闭动画
5. 轮盘不显示目标当前标记状态
6. 音效配置未生效
7. 缺少图形化配置界面

## 待办事项

- [x] **修复 Alt+点击显示问题**
- [x] **架构重构** - 安全按钮与视觉按钮合并 (2026-02-18)
- [x] **GUID 识别重构** - 使用 GUID 作为主要标识 (2026-02-19)
- [x] **修复标记按钮点击功能** - 已修复
- [x] **修复 `/npw tar` 命令** - 已修复，简化 GetUnitFromGUID 逻辑
- [x] **修复已标记目标无法唤出轮盘** - 已修复，添加 GetRaidTargetIndex 错误处理
- [x] **修复循环只执行一次的问题** - 已修复，移除无效 SetAttribute 调用
- [ ] 添加打开/关闭动画
- [ ] 实现音效反馈
- [ ] 创建配置界面
- [ ] 编写单元测试
- [x] **游戏内完整测试验证** - P0功能验证通过

## 今日完成 (2026-02-19)

### 修复的问题
1. **`/npw tar` 命令无法唤出轮盘**
   - 原因: `GetUnitFromGUID` 中 `UnitTokenFromGUID` 调用可能导致错误
   - 解决: 简化逻辑，直接返回 "target" 作为 unit token

2. **标记按钮只更新第一个**
   - 原因: `SetAttribute("npw-guid", ...)` 使用自定义属性导致 Lua 错误中断循环
   - 解决: 移除了不必要的自定义属性设置

3. **已标记目标无法重新唤出轮盘**
   - 原因: `UpdateCurrentMarkHighlight` 中 `GetRaidTargetIndex` 在某些情况下会出错
   - 解决: 添加 `pcall` 错误保护，防止函数中断

### 当前状态
- ✅ Alt+点击唤出轮盘: **工作正常**
- ✅ 8个标记按钮设置: **工作正常**
- ✅ 中心清除按钮: **工作正常**
- ✅ ESC键关闭轮盘: **工作正常**
- ✅ 已标记目标重新标记: **工作正常**
- ✅ 标记同步高亮: **已实现**

## 调试记录

### 2026-02-19 - 修复标记按钮不生效

**问题**: 按钮点击后宏不执行
**原因**: 轮盘主框架 `EnableMouse(true)` 拦截了点击事件
**解决**: 改为 `EnableMouse(false)` 和 `SetMouseClickEnabled(false)`

### 2026-02-19 - 修复 `/npw tar` 命令

**问题**: 命令执行后无轮盘显示
**原因**: `GetUnitFromGUID` 中 `UnitTokenFromGUID` 调用在某些情况下会导致错误，中断执行流程
**解决**: 简化 `GetUnitFromGUID` 直接返回 "target"

### 2026-02-19 - 修复循环只执行一次

**问题**: `UpdateSecureButtonMacros` 循环只更新第一个按钮
**原因**: `SetAttribute("npw-guid", ...)` 尝试设置自定义属性，但 SecureActionButtonTemplate 不支持任意属性名
**解决**: 移除了自定义属性设置，只保留必要的 `macrotext` 属性

### 2026-02-19 - 修复已标记目标无法唤出轮盘

**问题**: 对已标记目标 Alt+点击无反应
**原因**: `UpdateCurrentMarkHighlight` 中 `GetRaidTargetIndex` 在某些情况下会出错，导致函数中断
**解决**: 使用 `pcall` 包裹 `GetRaidTargetIndex` 调用，添加错误保护

### 2026-02-19 - 调试记录总结

通过添加详细的 `print` 调试输出，定位到以下关键问题：
1. `ShowWheel` 调用后无输出 → 发现 `GetUnitFromGUID` 中的 API 调用问题
2. `UpdateSecureButtonMacros` 循环中断 → 发现 `SetAttribute` 无效属性错误
3. `UpdateCurrentMarkHighlight` 函数中断 → 发现 `GetRaidTargetIndex` 错误

**调试技巧**: 在 WoW 插件开发中，使用 `pcall` 包裹可能出错的 API 调用可以有效防止函数中断。
