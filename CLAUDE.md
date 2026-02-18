# NamePlateMarkerWheel 项目开发指南

## 项目概述

**NamePlateMarkerWheel** 是一个魔兽世界插件，通过 Alt+点击姓名板弹出径向轮盘的方式，让玩家能够快速直观地设置团队标记。

## 研发进度

### P0 - 核心功能
- ✅ Alt+点击唤出轮盘 (`Events.lua`) - **已修复，可正常唤出**
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

### 待完成 (P3 - 高级功能)
- ⏳ 标记同步高亮显示
- ⏳ 打开/关闭动画
- ⏳ 音效反馈
- ⏳ 图形化配置界面

### 待完成 (测试)
- ⏳ 修复 `/npw tar` 命令无法唤出轮盘的问题
- ⏳ 单元测试文件
- ⏳ 游戏内完整测试验证

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

### Alt+点击触发
- 方式: WorldFrame HookScript OnMouseDown + Alt键检测
- 位置: `Events.lua` 第60-110行
- 流程:
  1. 钩住 WorldFrame 的 OnMouseDown 事件
  2. 检测是否按住 Alt 键 (`IsAltKeyDown()`)
  3. 获取目标 GUID (`UnitGUID("target")`)
  4. 调用 `ShowWheel()` 显示轮盘（传递GUID）

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
| `/npw tar` 命令无效 | `Register.lua` | 添加详细调试，排查 GUID 获取问题 | 调试中 |

## 架构变更记录

### 2026-02-18 - 安全按钮架构重构

**问题原因**: `SecureActionButtonTemplate` 的 `:Click()` 方法不会触发安全动作，必须由真实硬件事件触发。

**解决方案**: 将安全按钮与视觉按钮合并，直接创建带 `SecureActionButtonTemplate` 的视觉按钮。

**变更文件**:
- `WheelUI.lua:CreateMarkButton()` - 使用 `SecureActionButtonTemplate` 创建按钮
- `WheelUI.lua:CreateClearButton()` - 使用 `SecureActionButtonTemplate` 创建按钮
- `WheelUI.lua` - 主框架 `EnableMouse(false)` 避免拦截点击

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
- [ ] **修复 `/npw tar` 命令** - 日志显示执行到 `ShowWheel` 后无输出
- [ ] 实现标记同步高亮
- [ ] 添加打开/关闭动画
- [ ] 实现音效反馈
- [ ] 创建配置界面
- [ ] 编写单元测试
- [ ] 游戏内完整测试验证

## 调试记录

### 2026-02-19 - 修复标记按钮不生效

**问题**: 按钮点击后宏不执行
**原因**: 轮盘主框架 `EnableMouse(true)` 拦截了点击事件
**解决**: 改为 `EnableMouse(false)` 和 `SetMouseClickEnabled(false)`

### 2026-02-19 - 修复 `/npw tar` 命令

**问题**: 命令执行后无轮盘显示
**调试**:
1. 添加模块级 `Log()` 函数区分日志来源
2. 发现执行到 `ShowWheel()` 后无输出
3. 怀疑 `guid:sub()` 调用出错，改为 `string.sub()`
**状态**: 调试中，等待进一步日志
