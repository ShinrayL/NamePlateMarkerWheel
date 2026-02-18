# NamePlateMarkerWheel 插件规格文档

**版本**: 1.0.0
**适用游戏版本**: World of Warcraft 12.0+ (至暗之夜/Midnight)
**最后更新**: 2026-02-17

---

## 目录

1. [项目概述](#1-项目概述)
2. [功能规格 (Functional Spec)](#2-功能规格-functional-spec)
3. [技术规格 (Technical Spec)](#3-技术规格-technical-spec)
4. [测试计划 (Test Plan)](#4-测试计划-test-plan)
5. [附录](#5-附录)

---

## 1. 项目概述

### 1.1 项目背景

在团队副本和地下城中，快速标记目标是一项重要的团队协作功能。传统的标记方式需要通过右键菜单或快捷键逐个选择，操作效率较低。NamePlateMarkerWheel 插件通过双击姓名板弹出径向轮盘的方式，让玩家能够快速直观地设置团队标记。

### 1.2 目标用户

- 团队副本/地下城队长
- 需要频繁标记目标的玩家
- 追求操作效率的进阶玩家

### 1.3 核心功能

通过双击任意姓名板，弹出一个包含8个团队标记的径向轮盘，点击图标即可快速设置标记。

### 1.4 团队标记对照表

| 索引 | 标记名称 | 图标 | 颜色 |
|------|----------|------|------|
| 1 | 星星 (Star) | ★ | 黄色 |
| 2 | 圆圈 (Circle) | ● | 橙色 |
| 3 | 菱形 (Diamond) | ◆ | 紫色 |
| 4 | 三角 (Triangle) | ▲ | 绿色 |
| 5 | 月亮 (Moon) | ☽ | 银色 |
| 6 | 方块 (Square) | ■ | 蓝色 |
| 7 | 十字 (Cross) | ✕ | 红色 |
| 8 | 骷髅 (Skull) | ☠ | 白色 |

---

## 2. 功能规格 (Functional Spec)

### 2.1 P0 功能 - 必须实现

#### 2.1.1 双击姓名板检测 (NPW-001)

**功能描述**: 监听玩家双击姓名板的事件，识别双击动作并触发轮盘显示。

**输入**:
- 鼠标左键点击姓名板
- 时间间隔（两次点击间隔 < 300ms 视为双击）
- 点击位置（必须在姓名板范围内）

**输出**:
- 触发事件: `NAMEPLATE_DOUBLE_CLICKED`
- 参数: `unit` (单位ID), `namePlate` (姓名板框架), `x`, `y` (屏幕坐标)

**行为**:
1. 监听所有姓名板的 `OnMouseDown` 事件
2. 记录每次点击的时间戳和位置
3. 当两次点击间隔小于 300ms 且在同一姓名板上时，判定为双击
4. 触发双击事件，传递单位信息和屏幕坐标

**边界条件**:
- 战斗中：功能正常可用
- 点击间隔超过 300ms：视为两次独立单击
- 点击不同姓名板：视为独立点击，不触发双击

**错误处理**:
- 无效单位：静默忽略
- 单位不存在：记录调试日志

---

#### 2.1.2 径向轮盘UI (NPW-002)

**功能描述**: 显示一个包含8个团队标记图标的径向轮盘，图标呈圆形排列。

**输入**:
- 触发位置 (centerX, centerY) - 双击时的屏幕坐标
- 轮盘半径 (默认: 100 像素)

**输出**:
- 可视化轮盘UI框架
- 8个标记按钮，按圆形排列

**UI元素**:

```
              [骷髅 8]
                 |
    [十字 7] --- 中心 --- [星星 1]
       |                   |
    [方块 6]             [圆圈 2]
       |                   |
    [月亮 5] --- [三角 4] [菱形 3]
```

**布局计算**:
```lua
local function GetWheelPosition(index, centerX, centerY, radius)
    -- 从12点钟方向开始，顺时针排列
    local angle = math.rad(270 + (index - 1) * 45)  -- 45度间隔
    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)
    return x, y
end
```

**视觉设计**:
- 轮盘背景: 半透明黑色圆形 (80% 透明度)
- 标记图标: 使用游戏内置 RAID_TARGET_* 纹理
- 图标大小: 32x32 像素
- 悬停效果: 图标放大 1.2 倍，添加发光边框
- 选中效果: 图标高亮显示

**动画效果**:
- 打开动画: 从中心向外缩放展开 (200ms, ease-out)
- 关闭动画: 向内收缩消失 (150ms, ease-in)

---

#### 2.1.3 标记设置 (NPW-003)

**功能描述**: 点击轮盘上的标记图标，使用安全按钮+宏的方式为双击的单位设置对应的团队标记。

**输入**:
- 目标单位 (unit)
- 标记索引 (1-8)

**输出**:
- 通过安全按钮执行宏设置标记
- 关闭轮盘UI
- 显示确认反馈（可选）

**技术方案**: 参考 ElvUI_WindTools QuickFocus 实现 @"Warcraft/_retail_/Interface/AddOns/ElvUI_WindTools/Modules/UnitFrames/QuickFocus.lua  "

**行为**:
1. 玩家双击姓名板唤出轮盘
2. 点击轮盘上的标记图标
3. 安全按钮执行宏命令: `/tm [@mouseover] N`
4. 关闭轮盘

**API调用**:
```lua
-- 创建安全按钮
local button = CreateFrame("Button", "NPW_MarkButton" .. index, UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "macro")
button:SetAttribute("macrotext", "/tm [@mouseover] " .. index)

-- 模拟点击安全按钮
button:Click()
```

**错误处理**:
- 单位无效: 静默忽略
- 无权限: 静默忽略
- 标记已被使用: 允许覆盖

---

### 2.2 P1 功能 - 高优先级

#### 2.2.1 右键取消轮盘 (NPW-004)

**功能描述**: 右键点击轮盘外部区域或按 ESC 键关闭轮盘。

**输入**:
- 鼠标右键点击
- ESC 键按下
- 点击轮盘外部区域

**输出**:
- 关闭轮盘UI
- 清理相关状态

**行为**:
1. 监听右键点击事件
2. 如果点击位置不在轮盘范围内，关闭轮盘
3. 监听 ESC 键，按下时关闭轮盘
4. 关闭时播放轻微音效

---

#### 2.2.2 标记移除 (NPW-005)

**功能描述**: 轮盘中心提供一个按钮，使用安全按钮+宏的方式移除目标的所有标记。

**输入**:
- 点击轮盘中心区域

**输出**:
- 通过安全按钮执行宏 `/tm [@mouseover] 0`
- 关闭轮盘

**UI设计**:
- 中心按钮: 显示 "X" 或清除图标
- 大小: 40x40 像素
- 悬停提示: "移除标记"

**技术实现**:
```lua
-- 创建清除标记安全按钮
local clearButton = CreateFrame("Button", "NPW_ClearMarkButton", UIParent, "SecureActionButtonTemplate")
clearButton:SetAttribute("type", "macro")
clearButton:SetAttribute("macrotext", "/tm [@mouseover] 0")

-- 模拟点击
clearButton:Click()
```

---

### 2.3 P2 功能 - 中优先级

#### 2.3.1 Shift+点击快速焦点+标记 (NPW-009)

**功能描述**: 按住 Shift（可配置）并点击姓名板，快速将目标设为焦点并自动添加预设的团队标记。

**参考实现**: ElvUI_WindTools QuickFocus 模块

**输入**:
- 修饰键（默认: Shift）
- 鼠标按键（默认: 左键）
- 被点击的姓名板/单位

**输出**:
- 设置焦点目标
- 自动设置预设的团队标记
- 显示视觉反馈（可选）

**行为**:
1. 玩家按住 Shift 并点击姓名板
2. 插件检测到修饰键+点击组合
3. 执行宏命令序列：
   - `/focus mouseover` - 设置焦点
   - `/tm [@focus,exists] 0` - 清除现有标记
   - `/tm [@focus,exists] N` - 设置预设标记（N=1-8）
4. 在屏幕中央显示提示："焦点: 目标名称 [标记图标]"

**配置项**:

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| quickFocus.enabled | 布尔 | true | 启用快速焦点功能 |
| quickFocus.modifier | 字符串 | "SHIFT" | 修饰键: SHIFT/CTRL/ALT |
| quickFocus.button | 字符串 | "LeftButton" | 触发按键: LeftButton/RightButton/MiddleButton |
| quickFocus.setMark | 布尔 | true | 是否同时设置标记 |
| quickFocus.markNumber | 数字 | 8 | 预设标记 (1-8, 8=骷髅) |
| quickFocus.safeMark | 布尔 | true | 安全模式：先清除再设置标记 |
| quickFocus.showNotification | 布尔 | true | 显示焦点设置提示 |

**技术实现**:

```lua
-- 创建安全按钮
local button = CreateFrame("Button", "NPW_QuickFocusButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type1", "macro")
button:SetAttribute("macrotext", [[
/focus mouseover
/tm [@focus,exists] 0
/tm [@focus,exists] 8
]])

-- 绑定按键
SetOverrideBindingClick(button, true, "SHIFT-LeftButton", "NPW_QuickFocusButton")
```

**边界条件**:
- 战斗中：使用安全按钮，功能正常
- 已有焦点：替换为新的焦点目标
- 无权限设置标记：仅设置焦点，标记失败静默处理
- 目标已死亡：焦点设置失败，显示提示

**视觉反馈**:
- 在屏幕中央显示临时提示框
- 显示焦点目标名称和设置的标记图标
- 2秒后自动淡出

**错误处理**:
- 无效目标：静默忽略
- 焦点设置失败：显示错误提示 "无法设置焦点"

---

#### 2.3.2 自定义配置 (NPW-006)

**功能描述**: 提供配置界面，允许玩家自定义轮盘的外观和行为。

**配置项**:

| 配置项 | 类型 | 默认值 | 范围 |
|--------|------|--------|------|
| wheelRadius | 数字 | 100 | 50-200 |
| iconSize | 数字 | 32 | 16-64 |
| opacity | 数字 | 0.8 | 0.1-1.0 |
| animationSpeed | 数字 | 200 | 100-500 (毫秒) |
| doubleClickInterval | 数字 | 300 | 200-500 (毫秒) |
| enableSound | 布尔 | true | true/false |
| showOnHover | 布尔 | false | true/false |

**配置界面**:
- 使用 AceConfig-3.0 库创建配置面板
- 路径: ESC -> 界面 -> 插件 -> NamePlateMarkerWheel
- 实时预览功能

**配置文件**:
```lua
-- SavedVariables
NamePlateMarkerWheelDB = {
    profile = {
        wheelRadius = 100,
        iconSize = 32,
        opacity = 0.8,
        -- ...
    }
}
```

---

#### 2.3.2 快捷键支持 (NPW-007)

**功能描述**: 允许玩家绑定按键快速触发标记轮盘。

**输入**:
- 按键绑定

**输出**:
- 在鼠标位置显示轮盘
- 或显示在屏幕中心

**行为**:
1. 玩家按下绑定的快捷键
2. 在鼠标当前位置或屏幕中心显示轮盘
3. 轮盘行为与双击触发一致

**按键绑定配置**:
```lua
-- Bindings.xml
<Binding name="NamePlateMarkerWheel_TOGGLE" header="NamePlateMarkerWheel">
    显示标记轮盘
</Binding>
```

---

### 2.4 P3 功能 - 低优先级

#### 2.4.1 标记同步显示 (NPW-008)

**功能描述**: 轮盘上高亮显示目标当前已有的标记。

**输入**:
- 目标单位
- 当前标记状态

**输出**:
- 轮盘上对应标记图标高亮显示
- 其他标记图标变暗

**API调用**:
```lua
-- 获取当前标记
local currentMark = GetRaidTargetIndex(unit)
```

**视觉设计**:
- 当前标记: 100% 亮度，金色边框
- 其他标记: 50% 亮度，正常边框
- 无标记: 所有图标正常显示

---

## 3. 技术规格 (Technical Spec)

### 3.1 架构设计

#### 3.1.1 模块结构

```
NamePlateMarkerWheel/
├── NamePlateMarkerWheel.toc    # 插件描述文件
├── Core.lua                     # 核心逻辑模块
├── WheelUI.lua                  # 轮盘UI模块
├── Config.lua                   # 配置管理模块
├── Events.lua                   # 事件处理模块
├── Utils.lua                    # 工具函数模块
└── Media/
    ├── textures/                # 自定义纹理（可选）
    └── sounds/                  # 音效文件（可选）
```

#### 3.1.2 模块职责

| 模块 | 职责 |
|------|------|
| Core.lua | 插件初始化、模块加载、核心逻辑协调 |
| WheelUI.lua | 轮盘UI创建、显示/隐藏、动画处理 |
| Config.lua | 配置管理、SavedVariables、设置界面 |
| Events.lua | 事件注册、双击检测、输入处理 |
| Utils.lua | 通用工具函数、数学计算、辅助方法 |
| QuickFocus.lua | 快速焦点+标记功能实现 |

#### 3.1.3 数据流

```
玩家双击姓名板
      ↓
Events.lua 检测双击事件
      ↓
Core.lua 处理事件，获取单位信息
      ↓
WheelUI.lua 显示轮盘
      ↓
玩家点击标记图标
      ↓
Core.lua 调用 SetRaidTarget
      ↓
WheelUI.lua 关闭轮盘
```

---

### 3.2 API 接口

#### 3.2.1 核心API

**SetRaidTarget**
```lua
SetRaidTarget(unit, index)
-- unit: string - 单位ID ("target", "mouseover", "nameplate1" 等)
-- index: number - 标记索引 (0-8, 0为移除)
-- 返回值: 无
```

**GetRaidTargetIndex**
```lua
local index = GetRaidTargetIndex(unit)
-- unit: string - 单位ID
-- 返回值: number | nil - 当前标记索引，无标记返回 nil
```

**C_NamePlate API**
```lua
-- 获取所有姓名板
local namePlates = C_NamePlate.GetNamePlates()

-- 姓名板属性
namePlate.unit          -- 关联的单位ID
namePlate.namePlateUnitToken  -- 单位令牌
```

#### 3.2.2 自定义事件

| 事件名 | 参数 | 描述 |
|--------|------|------|
| NPW_NAMEPLATE_DOUBLE_CLICK | unit, namePlate, x, y | 双击姓名板触发 |
| NPW_WHEEL_SHOW | unit, x, y | 轮盘显示 |
| NPW_WHEEL_HIDE | - | 轮盘隐藏 |
| NPW_MARK_SET | unit, index | 标记设置成功 |

---

### 3.3 数据结构

#### 3.3.1 配置数据结构

```lua
NamePlateMarkerWheelDB = {
    profile = {
        -- 外观设置
        appearance = {
            wheelRadius = 100,          -- 轮盘半径
            iconSize = 32,              -- 图标大小
            opacity = 0.8,              -- 不透明度
            borderSize = 2,             -- 边框大小
        },

        -- 行为设置
        behavior = {
            doubleClickInterval = 300,  -- 双击间隔(毫秒)
            animationSpeed = 200,       -- 动画速度(毫秒)
            enableSound = true,         -- 启用音效
            closeOnMarkSet = true,      -- 设置标记后关闭
        },

        -- 按键绑定
        keybinds = {
            toggleKey = nil,            -- 快捷键
        },

        -- 快速焦点设置
        quickFocus = {
            enabled = true,             -- 启用快速焦点
            modifier = "SHIFT",         -- 修饰键
            button = "LeftButton",      -- 触发按键
            setMark = true,             -- 同时设置标记
            markNumber = 8,             -- 预设标记 (8=骷髅)
            safeMark = true,            -- 安全模式
            showNotification = true,    -- 显示提示
        },
    },
}
```

#### 3.3.2 运行时数据结构

```lua
-- 模块命名空间
local NamePlateMarkerWheel = {
    -- 状态
    state = {
        isWheelVisible = false,     -- 轮盘是否可见
        currentUnit = nil,          -- 当前目标单位
        wheelFrame = nil,           -- 轮盘框架引用
        lastClickTime = 0,          -- 上次点击时间
        lastClickNamePlate = nil,   -- 上次点击的姓名板
    },

    -- 常量
    constants = {
        NUM_MARKS = 8,              -- 标记数量
        MARK_TEXTURES = {           -- 标记纹理路径
            [1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
            [2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
            -- ...
            [8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
        },
    },
}
```

---

### 3.4 核心算法

#### 3.4.1 双击检测算法

```lua
local DOUBLE_CLICK_THRESHOLD = 300 -- 毫秒

function NamePlateMarkerWheel:HandleNamePlateClick(namePlate, button)
    local currentTime = GetTime() * 1000

    if button == "LeftButton" then
        if namePlate == self.state.lastClickNamePlate and
           (currentTime - self.state.lastClickTime) < DOUBLE_CLICK_THRESHOLD then
            -- 双击检测成功
            self:OnDoubleClick(namePlate)
            self.state.lastClickNamePlate = nil
        else
            -- 记录单击
            self.state.lastClickTime = currentTime
            self.state.lastClickNamePlate = namePlate
        end
    end
end
```

#### 3.4.2 径向布局计算

```lua
function NamePlateMarkerWheel:CalculateWheelPosition(index, centerX, centerY, radius)
    -- 从12点钟方向开始，顺时针排列
    -- 索引1(星星)在顶部，然后顺时针: 1->2->3->...->8
    local angle = math.rad(270 + (index - 1) * 45)

    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)

    return x, y
end
```

#### 3.4.3 点击区域检测

```lua
function NamePlateMarkerWheel:IsPointInWheel(x, y)
    local wheel = self.state.wheelFrame
    if not wheel then return false end

    local centerX = wheel:GetCenter()
    local centerY = wheel:GetCenter()
    local radius = self.db.profile.appearance.wheelRadius

    local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)

    return distance <= radius
end
```

---

### 3.5 文件详细规格

#### 3.5.1 NamePlateMarkerWheel.toc

```toc
## Interface: 120000
## Title: NamePlateMarkerWheel
## Notes: Double-click nameplates to quickly set raid markers
## Author: YourName
## Version: 1.0.0
## SavedVariables: NamePlateMarkerWheelDB

# Libraries (if using)
# Libs\LibStub\LibStub.lua
# Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua
# Libs\AceAddon-3.0\AceAddon-3.0.lua
# ...

Core.lua
Utils.lua
Events.lua
WheelUI.lua
Config.lua
QuickFocus.lua
```

#### 3.5.2 Core.lua 结构

```lua
local addonName, NamePlateMarkerWheel = ...
local _G = _G

-- 初始化
function NamePlateMarkerWheel:OnInitialize()
    -- 加载配置
    -- 初始化模块
end

-- 启用
function NamePlateMarkerWheel:OnEnable()
    -- 注册事件
    -- 开始监听姓名板
end

-- 禁用
function NamePlateMarkerWheel:OnDisable()
    -- 注销事件
    -- 停止监听
end

-- 双击处理
function NamePlateMarkerWheel:OnDoubleClick(namePlate)
    local unit = namePlate.unit
    local x, y = GetCursorPosition()

    self.state.currentUnit = unit
    self:ShowWheel(x, y, unit)
end

-- 创建标记安全按钮
function NamePlateMarkerWheel:CreateSecureMarkButtons()
    self.secureButtons = {}
    for i = 1, 8 do
        local btn = CreateFrame("Button", "NPW_SecureMark" .. i, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "/tm [@mouseover] " .. i)
        self.secureButtons[i] = btn
    end

    -- 清除按钮
    local clearBtn = CreateFrame("Button", "NPW_SecureClear", UIParent, "SecureActionButtonTemplate")
    clearBtn:SetAttribute("type", "macro")
    clearBtn:SetAttribute("macrotext", "/tm [@mouseover] 0")
    self.secureButtons.clear = clearBtn
end

-- 设置标记（通过安全按钮）
function NamePlateMarkerWheel:SetMark(index)
    local btn = self.secureButtons[index]
    if not btn then return end

    -- 执行安全按钮点击
    btn:Click()

    if self.db.profile.behavior.closeOnMarkSet then
        self:HideWheel()
    end
end
```

#### 3.5.4 QuickFocus.lua 结构

```lua
-- 快速焦点+标记模块（参考 ElvUI_WindTools QuickFocus）

-- 初始化快速焦点功能
function NamePlateMarkerWheel:InitQuickFocus()
    if not self.db.profile.quickFocus.enabled then return end

    -- 创建安全按钮
    self.quickFocusButton = CreateFrame("Button", "NPW_QuickFocusButton", UIParent, "SecureActionButtonTemplate")
    self.quickFocusButton:SetAttribute("type1", "macro")
    self.quickFocusButton:RegisterForClicks("AnyDown")

    -- 更新宏文本
    self:UpdateQuickFocusMacro()

    -- 绑定按键
    local modifier = self.db.profile.quickFocus.modifier
    local button = self.db.profile.quickFocus.button
    SetOverrideBindingClick(self.quickFocusButton, true, modifier .. "-" .. button, "NPW_QuickFocusButton")

    -- 创建通知框架
    self:CreateFocusNotification()
end

-- 更新快速焦点宏文本
function NamePlateMarkerWheel:UpdateQuickFocusMacro()
    local lines = { "/focus mouseover" }

    if self.db.profile.quickFocus.setMark then
        local markNum = self.db.profile.quickFocus.markNumber
        if markNum and markNum >= 1 and markNum <= 8 then
            if self.db.profile.quickFocus.safeMark then
                tAppendAll(lines, {
                    "/tm [@focus,exists,help][@focus,exists,harm] 0",
                    "/tm [@focus,exists,help][@focus,exists,harm] " .. markNum,
                })
            else
                tAppendAll(lines, {
                    "/tm [@focus,exists] 0",
                    "/tm [@focus,exists] " .. markNum,
                })
            end
        end
    end

    local macroText = table.concat(lines, "\n")
    self.quickFocusButton:SetAttribute("macrotext", macroText)
end

-- 创建焦点设置通知框架
function NamePlateMarkerWheel:CreateFocusNotification()
    local frame = CreateFrame("Frame", "NPW_FocusNotify", UIParent)
    frame:SetSize(300, 60)
    frame:SetPoint("CENTER", 0, 200)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- 背景
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.7)

    -- 焦点图标
    frame.focusIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.focusIcon:SetSize(32, 32)
    frame.focusIcon:SetPoint("LEFT", 10, 0)
    frame.focusIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8") -- 默认骷髅

    -- 文本
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("LEFT", frame.focusIcon, "RIGHT", 10, 0)
    frame.text:SetText("焦点目标")

    -- 动画组
    frame.animGroup = frame:CreateAnimationGroup()
    local fadeIn = frame.animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)

    local stay = frame.animGroup:CreateAnimation("Alpha")
    stay:SetFromAlpha(1)
    stay:SetToAlpha(1)
    stay:SetDuration(2)
    stay:SetOrder(2)

    local fadeOut = frame.animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(3)

    frame.animGroup:SetScript("OnFinished", function()
        frame:Hide()
    end)

    self.focusNotifyFrame = frame
end

-- 显示焦点设置通知
function NamePlateMarkerWheel:ShowFocusNotification(unitName, markIndex)
    if not self.db.profile.quickFocus.showNotification then return end

    local frame = self.focusNotifyFrame
    frame.text:SetText("焦点: " .. (unitName or "未知"))

    if markIndex and markIndex >= 1 and markIndex <= 8 then
        frame.focusIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markIndex)
        frame.focusIcon:Show()
    else
        frame.focusIcon:Hide()
    end

    frame:SetAlpha(0)
    frame:Show()
    frame.animGroup:Restart()
end
```

#### 3.5.5 文件详细规格总结

| 文件 | 核心职责 | 关键技术 |
|------|----------|----------|
| Core.lua | 插件初始化、模块协调 | AceAddon-3.0 模式 |
| Utils.lua | 工具函数、常量定义 | 数学计算 |
| Config.lua | 配置管理、设置界面 | AceDB-3.0, AceConfig-3.0 |
| Events.lua | 双击检测、事件处理 | HookScript |
| WheelUI.lua | 轮盘UI、安全按钮 | SecureActionButtonTemplate |
| QuickFocus.lua | 快速焦点+标记 | SetOverrideBindingClick |

#### 3.5.3 WheelUI.lua 结构

```lua
-- 创建轮盘框架（使用安全按钮）
function NamePlateMarkerWheel:CreateWheelFrame()
    local frame = CreateFrame("Frame", "NPW_WheelFrame", UIParent)
    frame:SetSize(300, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    -- 背景
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)

    -- 创建8个标记按钮（安全按钮）
    frame.markButtons = {}
    for i = 1, 8 do
        frame.markButtons[i] = self:CreateSecureMarkButton(frame, i)
    end

    -- 中心清除按钮（安全按钮）
    frame.clearButton = self:CreateSecureClearButton(frame)

    return frame
end

-- 创建安全标记按钮
function NamePlateMarkerWheel:CreateSecureMarkButton(parent, index)
    -- 可见的UI按钮
    local visualBtn = CreateFrame("Button", nil, parent)
    visualBtn:SetSize(32, 32)

    -- 安全按钮（实际执行宏）
    local secureBtn = CreateFrame("Button", "NPW_SecureMark" .. index, UIParent, "SecureActionButtonTemplate")
    secureBtn:SetAttribute("type", "macro")
    secureBtn:SetAttribute("macrotext", "/tm [@mouseover] " .. index)

    -- 图标
    local icon = visualBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index)

    -- 点击时执行安全按钮
    visualBtn:SetScript("OnClick", function()
        secureBtn:Click()
        parent:Hide()
    end)

    return visualBtn
end

-- 显示轮盘
function NamePlateMarkerWheel:ShowWheel(x, y, unit)
    local frame = self.state.wheelFrame

    -- 设置位置
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

    -- 更新当前标记高亮
    self:UpdateCurrentMark(unit)

    -- 显示动画
    frame:Show()
    self:PlayShowAnimation()
end

-- 隐藏轮盘
function NamePlateMarkerWheel:HideWheel()
    local frame = self.state.wheelFrame
    self:PlayHideAnimation(function()
        frame:Hide()
    end)
end
```

---

## 4. 测试计划 (Test Plan)

### 4.1 测试策略

采用分层测试策略：
- **单元测试**: 测试独立函数和模块
- **集成测试**: 测试模块间交互
- **功能测试**: 测试完整功能流程
- **兼容性测试**: 测试不同游戏场景

### 4.2 测试用例

#### 4.2.1 P0 功能测试

**TC-001: 双击检测 - 正常情况**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证双击姓名板能正确触发轮盘 |
| 前置条件 | 插件已加载，姓名板可见 |
| 测试步骤 | 1. 找到任意姓名板<br>2. 快速双击左键（间隔<300ms） |
| 预期结果 | 轮盘在双击位置显示 |
| 优先级 | P0 |

**TC-002: 双击检测 - 单击不触发**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证单击不会触发轮盘 |
| 前置条件 | 插件已加载，姓名板可见 |
| 测试步骤 | 1. 单击姓名板<br>2. 等待500ms<br>3. 再次单击 |
| 预期结果 | 轮盘不显示 |
| 优先级 | P0 |

**TC-003: 轮盘显示 - 布局正确**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证8个标记按正确顺序排列 |
| 前置条件 | 轮盘已显示 |
| 测试步骤 | 检查轮盘上的标记位置和顺序 |
| 预期结果 | 从顶部开始顺时针: 星星->圆圈->菱形->三角->月亮->方块->十字->骷髅 |
| 优先级 | P0 |

**TC-004: 标记设置 - 正常设置（安全按钮）**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证通过安全按钮执行宏能正确设置标记 |
| 前置条件 | 轮盘已显示，目标单位有效 |
| 测试步骤 | 1. 双击姓名板打开轮盘<br>2. 点击骷髅图标 |
| 预期结果 | 安全按钮执行 `/tm [@mouseover] 8`，目标被设置骷髅标记，轮盘关闭 |
| 技术验证 | 确认使用 SecureActionButtonTemplate |
| 优先级 | P0 |

**TC-005: 标记设置 - 战斗中（安全按钮）**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证安全按钮在战斗中能正常工作 |
| 前置条件 | 玩家处于战斗状态 |
| 测试步骤 | 1. 进入战斗<br>2. 双击姓名板<br>3. 设置标记 |
| 预期结果 | 安全按钮通过 `/tm` 宏成功设置标记，无 taint 错误 |
| 技术验证 | 确认战斗中可执行 SecureActionButtonTemplate |
| 优先级 | P0 |

#### 4.2.2 P1 功能测试

**TC-006: Shift+点击快速焦点+标记**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证 Shift+点击能同时设置焦点和标记 |
| 前置条件 | 快速焦点功能已启用 |
| 测试步骤 | 1. 按住 Shift 点击姓名板 |
| 预期结果 | 目标设为焦点并自动设置预设标记（默认骷髅），屏幕中央显示提示 |
| 技术验证 | 确认 SetOverrideBindingClick 绑定正确 |
| 优先级 | P1 |

**TC-007: 右键关闭**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证右键点击关闭轮盘 |
| 前置条件 | 轮盘已显示 |
| 测试步骤 | 右键点击轮盘外部区域 |
| 预期结果 | 轮盘关闭 |
| 优先级 | P1 |

**TC-008: 中心清除按钮（安全按钮）**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证中心按钮通过安全按钮移除标记 |
| 前置条件 | 目标已有标记，轮盘已显示 |
| 测试步骤 | 点击轮盘中心清除按钮 |
| 预期结果 | 安全按钮执行 `/tm [@mouseover] 0`，标记被移除，轮盘关闭 |
| 技术验证 | 确认清除按钮使用 SecureActionButtonTemplate |
| 优先级 | P1 |

**TC-009: 快速焦点配置**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证快速焦点配置可正常修改 |
| 前置条件 | 插件已加载 |
| 测试步骤 | 1. 修改预设标记为三角(4)<br>2. Shift+点击姓名板 |
| 预期结果 | 目标设为焦点并设置三角标记 |
| 优先级 | P2 |

#### 4.2.3 P2/P3 功能测试

**TC-010: 配置保存**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证配置更改能正确保存 |
| 前置条件 | 插件已加载 |
| 测试步骤 | 1. 修改轮盘半径为150<br>2. 重新加载界面 |
| 预期结果 | 设置保持为150 |
| 优先级 | P2 |

**TC-011: 当前标记高亮**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证当前标记正确高亮 |
| 前置条件 | 目标已有骷髅标记 |
| 测试步骤 | 双击该目标姓名板 |
| 预期结果 | 轮盘上骷髅图标高亮显示 |
| 优先级 | P3 |

**TC-012: 战斗中快速焦点**

| 项目 | 内容 |
|------|------|
| 测试目的 | 验证战斗中快速焦点功能正常 |
| 前置条件 | 玩家处于战斗状态 |
| 测试步骤 | 1. 进入战斗<br>2. Shift+点击姓名板 |
| 预期结果 | 安全按钮成功设置焦点和标记，无 taint 错误 |
| 技术验证 | 确认 SetOverrideBindingClick 在战斗中可用 |
| 优先级 | P1 |

### 4.3 验收标准

#### 4.3.1 功能验收

| 功能 | 验收标准 |
|------|----------|
| 双击检测 | 准确率 > 95%，不误触发 |
| 轮盘显示 | 渲染正确，无视觉错误 |
| 标记设置 | 成功率 100%，通过SecureActionButtonTemplate执行宏 |
| 右键关闭 | 响应时间 < 100ms |
| 配置系统 | 设置持久化，界面友好 |

#### 4.3.2 性能验收

| 指标 | 标准 |
|------|------|
| 内存占用 | < 5MB |
| CPU占用 | 双击检测 < 0.1ms/帧 |
| 加载时间 | < 100ms |
| 帧率影响 | 无可见影响 |

#### 4.3.3 兼容性验收

| 场景 | 标准 |
|------|------|
| 战斗状态 | 功能正常 |
| 多姓名板 | 每个姓名板独立工作 |
| 其他插件 | 不冲突，可共存 |
| 不同分辨率 | UI自适应 |

### 4.4 测试环境

- **游戏版本**: WoW 12.0.0 (至暗之夜)
- **测试服务器**: 正式服 / PTR
- **分辨率**: 1920x1080, 2560x1440, 3840x2160
- **UI缩放**: 0.8 - 1.2

---

## 5. 附录

### 5.1 参考资料

- [WoW API Documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [UI Customization Guide](https://wowpedia.fandom.com/wiki/UI_customization)
- [Ace3 Framework](https://www.wowace.com/projects/ace3)

### 5.2 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 全局变量 | NPW_前缀 | NPW_WheelFrame |
| 模块函数 | 驼峰命名 | CalculateWheelPosition |
| 常量 | 全大写 | DOUBLE_CLICK_THRESHOLD |
| 事件 | NPW_前缀 | NPW_NAMEPLATE_DOUBLE_CLICK |

### 5.3 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-02-17 | 初始版本，P0-P1功能 |

### 5.4 待办事项

- [x] 更新 Spec 文档 (使用 SecureActionButtonTemplate 方案)
- [ ] 实现 Core.lua - 插件核心初始化
- [ ] 实现 Utils.lua - 工具函数
- [ ] 实现 Config.lua - 配置管理
- [ ] 实现 Events.lua - 双击检测
- [ ] 实现 WheelUI.lua - 轮盘UI + 安全按钮
- [ ] 实现 QuickFocus.lua - 快速焦点+标记
- [ ] 创建 .toc 文件
- [ ] 游戏内测试验证
- [ ] 多语言本地化
- [ ] 性能优化

---

**文档结束**
