# NamePlateMarkerWheel 项目开发指南

## 项目概述

**NamePlateMarkerWheel** 是一个魔兽世界插件，通过 Alt+点击姓名板弹出径向轮盘的方式，让玩家能够快速直观地设置团队标记。

## 研发进度

### P0 - 核心功能
- ✅ Alt+点击唤出轮盘 (`Events.lua`) - **已修复，可正常唤出**
- ✅ 双击唤出轮盘 (`Events.lua`) - **已实现，300ms 内双击同一目标**
- ✅ 姓名板点击唤出轮盘 (`Events.lua`) - **已实现，支持默认姓名板和ElvUI姓名板**
- ✅ 战斗中唤出/关闭轮盘 (`WheelUI.lua`) - **已实现，使用[target]宏避免战斗中修改属性**
- ✅ 径向轮盘UI (`WheelUI.lua`) - **显示正常**
- ✅ 标记设置功能 (`WheelUI.lua`, `SecureActionButtonTemplate`) - **已修复，按钮点击可设置标记**
- ✅ 测试命令 `/npw test` 可正常唤出轮盘
- ✅ 测试命令 `/npw tar` 可针对目标唤出轮盘
- ✅ 安全按钮宏更新 (`Core.lua`)
- ✅ **战斗快捷标记** (`Core.lua`, `Config.lua`) - **已实现，支持自定义按键组合，战斗中无需唤出轮盘**

### 已完成 (P1 - 交互增强)
- ✅ 中心清除按钮
- ✅ ESC键关闭轮盘
- ✅ 点击外部关闭轮盘

### 已完成 (P2 - 配置系统)
- ✅ 配置管理 (`Config.lua`)
- ✅ 斜杠命令 (`/npw`, `/npw test`, `/npw debug`, `/npw tar`)
- ✅ SavedVariables 持久化
- ✅ 图形化配置界面 (`/npw config`) - **完整配置面板，支持实时预览**
- ✅ 战斗快捷标记配置 - **可为每个标记独立设置按键组合**

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
| `Core.lua` | 插件初始化、安全按钮宏更新、核心状态管理、**战斗快捷标记绑定** |
| `WheelUI.lua` | 轮盘创建、8个标记按钮+清除按钮、显示/隐藏逻辑、GUID解析 |
| `Events.lua` | Alt+点击检测、WorldFrame钩子、姓名板钩子（支持默认/ElvUI）、事件处理 |
| `Config.lua` | 配置管理、默认值、配置重置、**图形化配置界面**、**战斗快捷标记配置UI** |
| `Register.lua` | 斜杠命令注册 (`/npw test`, `/npw tar` 等) |
| `Utils.lua` | 常量定义、数学计算(角度/位置)、工具函数 |

## 关键实现细节

### 唤出轮盘触发方式（双击 + Alt+点击 + 姓名板点击）

#### 方式1: WorldFrame 点击
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

#### 方式2: 姓名板点击
- 方式: 钩住姓名板框架的 OnMouseDown 事件
- 位置: `Events.lua` 第161-285行
- 流程:
  1. 监听 `NAME_PLATE_CREATED` 事件
  2. 为新创建的姓名板调用 `HookScript("OnMouseDown", ...)`
  3. 从姓名板获取单位 token (`GetUnitFromNamePlate()`)
  4. 检测触发条件（与WorldFrame相同）：
     - **双击**: 同一目标，两次点击间隔 <= 300ms
     - **Alt+点击**: 按住 Alt 键点击
  5. 调用 `ShowWheel()` 显示轮盘
- 特点: 姓名板点击优先级更高，直接获取姓名板对应的单位

##### 支持的姓名板插件
- **默认姓名板**: 使用 `nameplate.namePlateUnitToken`
- **ElvUI 姓名板**: 使用 `nameplate.unit` 或从 `ElvUI[1].NamePlates.displayedPlates` 获取
- **其他插件**: 通过姓名板名称匹配 (NamePlate1 -> nameplate1)

### 安全按钮与战斗中支持

#### 按钮创建
- 使用 `SecureActionButtonTemplate` 直接创建视觉按钮
- 按钮创建: `CreateFrame("Button", ..., parent, "SecureActionButtonTemplate")`
- 类型: `macro`
- 宏格式: `/tm [target] <index>`（使用[target]而非动态单位）

#### 战斗中的限制与解决方案
| 操作 | 战斗中允许 | 解决方案 |
|------|-----------|----------|
| `Show()`/`Hide()` | ✅ | 直接显示/隐藏轮盘 |
| `SetAlpha()`/`SetScale()` | ✅ | 动画效果可用 |
| `SetAttribute()` | ❌ | 使用`[target]`宏，无需动态更新 |
| `ClearAllPoints()`/`SetPoint()` | ❌ | 非战斗中预设位置，战斗中复用 |
| `CreateFrame()` | ❌ | 所有帧预创建，战斗中只显示/隐藏 |

#### 关键实现
1. **预创建所有帧**: 在 `CreateWheelFrame()` 和 `CreateClickOutFrames()` 中完成
2. **静态宏文本**: 使用 `/tm [target] N` 而非 `/tm [@unit] N`，避免战斗中修改属性
3. **位置预设**: 非战斗中保存最后位置，战斗中只能在该位置显示
4. **动画控制**: 战斗中禁用创建动画组的操作，只使用基本的 Show/Hide

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
| 战斗中无法设置标记 | `Core.lua`, `Config.lua` | 使用 `SetOverrideBindingClick` 预创建安全按钮并绑定修饰键+点击组合，实现战斗中快捷标记 | 已修复 |

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

### 2026-03-12 - 战斗快捷标记（无需唤出轮盘）

**需求**: 在战斗中无需唤出轮盘，直接使用按键组合设置标记。

**技术挑战**:
- 战斗中不能调用 `SetBindingClick`（受保护）
- 需要预创建安全按钮并在战斗外绑定
- 用户需要自定义按键组合以避免冲突

**解决方案**:
1. **预创建9个安全按钮** (`NPW_CombatMarkBtn0-8`)
   - 使用 `SecureActionButtonTemplate` 创建
   - 每个按钮对应一个标记（1-8）或清除（0）
   - 宏文本固定为 `/tm N`，战斗中不可变

2. **使用 `SetOverrideBindingClick` 绑定**
   - 战斗外预先绑定修饰键+点击组合到对应按钮
   - Override binding 优先级高于普通绑定
   - 插件禁用时自动清除绑定

3. **可配置按键组合**
   - 配置面板中为每个标记提供独立设置
   - 修饰键选项：无、Alt、Ctrl、Shift 及其组合
   - 按键选项：左键、右键、中键
   - 修改后立即生效（`ReapplyCombatBindings`）

4. **配置持久化**
   - `combatBindings.enabled` - 功能开关
   - `combatBindings[1-8]` - 每个标记的按键配置
   - `combatBindings.clear` - 清除按钮配置

**变更文件**:
- `Core.lua`:
  - `CreateCombatMarkButtons()` - 预创建9个安全按钮（0-8）
  - `BindDirectMarkKeys()` - 从配置读取并应用绑定
  - `ReapplyCombatBindings()` - 清除旧绑定并重新应用
  - `ClearOverrideBindings()` - 清除所有插件绑定
  - `InitCombatMarkBindings()` - 初始化时调用绑定

- `Config.lua`:
  - 新增 `combatBindings` 默认配置
  - `CreateBindRow()` - 创建单行绑定配置UI
  - 9行配置（8标记+清除），每行包含标签+修饰键下拉+按键下拉
  - `ValidateConfig()` - 确保配置结构完整

- `Events.lua`:
  - 移除战斗中 `SetBindingClick` 调用（已废弃）
  - 简化战斗中 Alt+点击处理逻辑

**WindTools 参考**:
- `Modules/UnitFrames/QuickFocus.lua:120-124` - `SetOverrideBindingClick` 使用
- `Modules/Combat/RaidMarkers.lua:249-308` - 安全按钮创建和属性设置

**默认绑定**:
| 按键组合 | 标记 |
|---------|------|
| Alt+左键 | 星星 (1) |
| Ctrl+左键 | 大饼 (2) |
| Shift+左键 | 菱形 (3) |
| Alt+右键 | 三角 (4) |
| Ctrl+右键 | 月亮 (5) |
| Shift+右键 | 方块 (6) |
| Alt+Ctrl+左键 | 叉 (7) |
| Alt+Shift+左键 | 骷髅 (8) |
| Alt+中键 | 清除 |

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
3. **✅ `/npw tar` 命令唤不出轮盘** - 已修复
4. 缺少打开/关闭动画
5. 轮盘不显示目标当前标记状态
6. 音效配置未生效
7. **✅ 缺少图形化配置界面** - 已修复，完整配置面板已实现

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
- [x] 创建配置界面 - **已完成，支持外观、行为、战斗快捷标记完整配置**
- [ ] 编写单元测试
- [x] **游戏内完整测试验证** - P0功能验证通过

## 今日完成 (2026-03-12)

### 新增功能: 战斗快捷标记（无需唤出轮盘）

实现类似 WindTools 的战斗快捷标记功能，但提供可配置的按键组合。

**核心实现：**

1. **预创建9个安全按钮** (`Core.lua:CreateCombatMarkButtons`)
   - `NPW_CombatMarkBtn1-8` - 对应8个团队标记
   - `NPW_CombatMarkBtn0` - 清除标记
   - 使用 `SecureActionButtonTemplate` 创建，宏文本固定为 `/tm N`

2. **使用 `SetOverrideBindingClick` 绑定** (`Core.lua:BindDirectMarkKeys`)
   - 战斗外预先绑定修饰键+点击组合到对应按钮
   - Override binding 优先级高于普通绑定，插件卸载时自动清除

3. **可配置按键组合** (`Config.lua`)
   - 配置面板中为每个标记提供独立设置
   - 修饰键：无、Alt、Ctrl、Shift、Alt+Ctrl、Alt+Shift、Ctrl+Shift、Alt+Ctrl+Shift
   - 按键：左键、右键、中键
   - 修改后立即生效（无需重载）

4. **配置结构** (`Config.lua`)
   ```lua
   combatBindings = {
       enabled = true,
       [1] = { modifier = "ALT", button = "BUTTON1" },      -- 星星
       [2] = { modifier = "CTRL", button = "BUTTON1" },     -- 大饼
       ...
       [8] = { modifier = "ALT-SHIFT", button = "BUTTON1" }, -- 骷髅
       clear = { modifier = "ALT", button = "BUTTON3" },    -- 清除
   }
   ```

5. **配置界面** (`Config.lua:CreateBindRow`)
   - 9行配置UI（8个标记 + 清除）
   - 每行包含：标签 + 修饰键下拉菜单 + 按键下拉菜单
   - 启用/禁用复选框
   - 重置为默认按钮

**默认绑定：**
| 按键组合 | 标记 |
|---------|------|
| Alt+左键 | 星星 (1) |
| Ctrl+左键 | 大饼 (2) |
| Shift+左键 | 菱形 (3) |
| Alt+右键 | 三角 (4) |
| Ctrl+右键 | 月亮 (5) |
| Shift+右键 | 方块 (6) |
| Alt+Ctrl+左键 | 叉 (7) |
| Alt+Shift+左键 | 骷髅 (8) |
| Alt+中键 | 清除 |

**使用方法：**
1. 打开配置面板：`/npw config`
2. 展开"战斗快捷标记"部分
3. 勾选"启用战斗快捷标记"
4. 为每个标记选择喜欢的按键组合
5. 战斗中直接对目标使用对应按键组合即可设置标记

**技术限制：**
- 战斗中无法更改绑定（配置修改需等待战斗结束或手动重载）
- 相同绑定会相互覆盖（后设置的生效）
- 会覆盖游戏默认的同按键组合（但仅在插件启用时）

## 今日完成 (2026-03-10)

### 新增功能
1. **姓名板点击唤出轮盘**
   - 实现: 监听 `NAME_PLATE_CREATED` 事件，为新姓名板钩住 `OnMouseDown` 事件
   - 文件: `Events.lua` - 新增 `HookNamePlates()`, `HookNamePlate()`, `CheckNamePlateClick()` 函数
   - 支持: Alt+点击和双击两种方式
   - 特点: 直接通过姓名板获取单位 token，比 WorldFrame 方式更可靠

2. **ElvUI 姓名板支持**
   - 实现: 新增 `GetUnitFromNamePlate()` 函数，支持从 ElvUI 姓名板获取单位 token
   - 文件: `Events.lua`
   - 支持方式:
     - `nameplate.unit` 属性
     - `ElvUI[1].NamePlates.displayedPlates` 表
     - 姓名板名称匹配 (NamePlate1 -> nameplate1)

3. **战斗中唤出/关闭轮盘**
   - 问题: 战斗中不能调用 `SetAttribute`、`ClearAllPoints`、`CreateFrame`
   - 解决:
     - 修改宏为 `/tm [target] N`，避免战斗中动态更新宏文本
     - 所有帧预创建，战斗中只执行 `Show()`/`Hide()`
     - 位置在非战斗中预设，战斗中复用最后位置
     - 战斗中禁用动画（避免创建动画组）
   - 文件: `WheelUI.lua`, `Core.lua`

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
