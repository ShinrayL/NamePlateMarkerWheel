-- Core.lua
-- NamePlateMarkerWheel 核心模块

local _, NPW = ...
_G.NamePlateMarkerWheel = NPW

-- 版本信息
NPW.VERSION = "1.0.0"

-- 运行时状态
NPW.state = {
    isWheelVisible = false,
    currentUnit = nil, -- 当前 unit token（临时）
    currentGUID = nil, -- 当前目标的 GUID（主要标识）
    wheelFrame = nil,
    wheelOverlay = nil,
    lastClickTime = 0,      -- 上次点击时间（毫秒）
    lastClickGUID = nil,    -- 上次点击目标的 GUID（用于双击检测）
    secureButtons = {},
    lastWheelX = nil,       -- 上次轮盘X位置（用于战斗中显示）
    lastWheelY = nil,       -- 上次轮盘Y位置（用于战斗中显示）
    wheelPositionSet = false, -- 轮盘位置是否已设置
    -- 战斗中标记队列
    combatMarkQueue = {1, 2, 3, 4, 5, 6, 7, 8}, -- 标记队列 1-8
    combatMarkIndex = 1,    -- 当前队列位置
    pendingQueueAdvance = false, -- 战斗中有待处理的队列更新
}

-- 常量定义
NPW.constants = {
    NUM_MARKS = 8,
    DOUBLE_CLICK_THRESHOLD = 500, -- 毫秒（双击时间阈值）
    DEFAULT_RADIUS = 100,
    DEFAULT_ICON_SIZE = 32,
}

-- 插件初始化
function NPW:OnInitialize()
    -- 初始化配置
    self:InitConfig()
    -- 创建轮盘UI
    self:CreateWheelFrame()
    -- 创建配置界面
    self:CreateConfigPanel()
    -- 注册斜杠命令
    self:RegisterSlashCommands()
    -- 初始化战斗标记绑定（必须在战斗外完成）
    self:InitCombatMarkBindings()
end

-- 插件启用
function NPW:OnEnable()
    -- 初始化事件监听
    self:InitEvents()
end

-- 注：现在操作的是集成在视觉按钮中的安全按钮
-- 战斗中不能调用 SetAttribute，所以宏使用 [@target] 避免战斗中修改
-- @param unit: 当前可用的 unit token（仅用于高亮显示，不影响宏）
-- @param guid: 目标单位的 GUID（主要标识）
function NPW:UpdateSecureButtonMacros(unit, guid)
    -- 战斗中不能修改安全按钮属性，跳过
    if InCombatLockdown() then
        return
    end

    local frame = self.state.wheelFrame
    if not frame or not frame.markButtons then return end

    -- 宏使用 /tm N 格式（默认对当前目标生效）
    -- 这样战斗中也能正常使用，无需修改宏
    for i = 1, 8 do
        local btn = frame.markButtons[i]
        if btn then
            btn:SetAttribute("macrotext", "/tm " .. i)
        end
    end

    if frame.clearButton then
        frame.clearButton:SetAttribute("macrotext", "/tm 0")
    end
end

-- 创建战斗中使用的安全按钮（预创建，用于SetOverrideBindingClick绑定）
function NPW:CreateCombatMarkButtons()
    if self.combatMarkButtons then return end

    self.combatMarkButtons = {}

    for i = 1, 8 do
        local btn = CreateFrame("Button", "NPW_CombatMarkBtn" .. i, UIParent, "SecureActionButtonTemplate")
        btn:SetSize(1, 1)
        btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "/tm " .. i)
        btn:RegisterForClicks("AnyDown")
        btn:Hide()

        -- PostClick 在安全动作执行后触发，用于更新队列
        btn:SetScript("PostClick", function()
            -- 推进队列索引（这个操作在战斗中也是安全的）
            NPW.state.combatMarkIndex = NPW.state.combatMarkIndex + 1
            if NPW.state.combatMarkIndex > #NPW.state.combatMarkQueue then
                NPW.state.combatMarkIndex = 1
            end

            if not InCombatLockdown() then
                -- 非战斗中：立即更新绑定
                NPW:UpdateCombatMarkBinding()
            else
                -- 战斗中：设置标志，战斗结束后更新绑定
                NPW.state.pendingQueueAdvance = true
                if NPW.db and NPW.db.debug then
                    local nextMark = NPW.state.combatMarkQueue[NPW.state.combatMarkIndex]
                    print("|cff00ffff[NPW]|r 队列前进 -> 标记 " .. nextMark .. " (待更新绑定)")
                end
            end
        end)

        self.combatMarkButtons[i] = btn
    end

    -- 创建清除标记按钮
    local clearBtn = CreateFrame("Button", "NPW_CombatMarkBtn0", UIParent, "SecureActionButtonTemplate")
    clearBtn:SetSize(1, 1)
    clearBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    clearBtn:SetAttribute("type", "macro")
    clearBtn:SetAttribute("macrotext", "/tm 0")
    clearBtn:RegisterForClicks("AnyDown")
    clearBtn:Hide()
    self.combatMarkButtons[0] = clearBtn
end

-- 初始化战斗标记绑定（在战斗外预先绑定）
function NPW:InitCombatMarkBindings()
    -- 预创建战斗按钮
    self:CreateCombatMarkButtons()

    -- 创建用于存储绑定状态的虚拟帧
    if not self.combatBindingFrame then
        self.combatBindingFrame = CreateFrame("Frame")
    end

    -- 绑定各种修饰键+点击组合到不同标记（战斗中可用）
    self:BindDirectMarkKeys()
end

-- 预绑定所有修饰键+点击组合到不同标记（战斗中可用）
function NPW:BindDirectMarkKeys()
    if not self.combatMarkButtons then return end
    if not self.db.combatBindings or not self.db.combatBindings.enabled then
        return
    end

    -- 从配置中读取绑定设置
    local config = self.db.combatBindings

    -- 绑定8个标记
    for i = 1, 8 do
        local bind = config[i]
        if bind and bind.modifier and bind.button then
            local keyCombo = bind.modifier .. "-" .. bind.button
            if bind.modifier == "" then
                keyCombo = bind.button  -- 无修饰键
            end
            local btnName = "NPW_CombatMarkBtn" .. i  -- 按钮名对应标记编号
            SetOverrideBindingClick(self.combatBindingFrame, true, keyCombo, btnName)

            if self.db and self.db.debug then
                local modText = bind.modifier == "" and "无修饰" or bind.modifier
                local btnText = bind.button == "BUTTON1" and "左键" or (bind.button == "BUTTON2" and "右键" or "中键")
                print("|cff00ffff[NPW]|r 绑定: " .. modText .. "+" .. btnText .. " -> 标记 " .. i)
            end
        end
    end

    -- 绑定清除按钮
    if config.clear and config.clear.modifier and config.clear.button then
        local keyCombo = config.clear.modifier .. "-" .. config.clear.button
        if config.clear.modifier == "" then
            keyCombo = config.clear.button
        end
        SetOverrideBindingClick(self.combatBindingFrame, true, keyCombo, "NPW_CombatMarkBtn0")

        if self.db and self.db.debug then
            local modText = config.clear.modifier == "" and "无修饰" or config.clear.modifier
            local btnText = config.clear.button == "BUTTON1" and "左键" or (config.clear.button == "BUTTON2" and "右键" or "中键")
            print("|cff00ffff[NPW]|r 绑定: " .. modText .. "+" .. btnText .. " -> 清除")
        end
    end

    if self.db and self.db.debug then
        print("|cff00ffff[NPW]|r 战斗快捷标记绑定完成")
    end
end

-- 重新应用战斗绑定（配置变更后调用）
function NPW:ReapplyCombatBindings()
    if not self.combatBindingFrame then return end

    -- 清除现有绑定
    ClearOverrideBindings(self.combatBindingFrame)

    -- 重新应用绑定
    self:BindDirectMarkKeys()

    if self.db and self.db.debug then
        print("|cff00ffff[NPW]|r 战斗快捷标记绑定已更新")
    end
end

-- 清除所有插件绑定的辅助函数
function NPW:ClearOverrideBindings()
    if self.combatBindingFrame then
        ClearOverrideBindings(self.combatBindingFrame)
        if self.db and self.db.debug then
            print("|cff00ffff[NPW]|r 已清除所有插件绑定")
        end
    end
end

-- 更新战斗标记绑定（指向当前队列位置的标记）
-- 注意：此函数现在只更新队列状态，实际绑定在 BindDirectMarkKeys 中配置
function NPW:UpdateCombatMarkBinding()
    if not self.combatMarkButtons then return end

    local mark = self.state.combatMarkQueue[self.state.combatMarkIndex]

    if self.db and self.db.debug then
        print("|cff00ffff[NPW]|r 当前队列位置: 标记 " .. mark)
    end
end

-- 移动到下一个标记并更新绑定
function NPW:AdvanceMarkQueue()
    -- 移动到队列下一个位置
    self.state.combatMarkIndex = self.state.combatMarkIndex + 1
    if self.state.combatMarkIndex > #self.state.combatMarkQueue then
        self.state.combatMarkIndex = 1
    end

    -- 更新绑定到新的标记
    self:UpdateCombatMarkBinding()

    if self.db and self.db.debug then
        local nextMark = self.state.combatMarkQueue[self.state.combatMarkIndex]
        print("|cff00ffff[NPW]|r 队列前进，下一个标记: " .. nextMark)
    end
end

-- 旧的绑定函数（已废弃，保留兼容）
function NPW:RegisterCombatMarkBindings()
    -- 现在使用 SetOverrideBindingClick 方案，无需手动绑定
    -- 此函数保留用于兼容旧代码
    self:AdvanceMarkQueue()
end

-- 重置标记队列
function NPW:ResetMarkQueue()
    self.state.combatMarkIndex = 1
    self:UpdateCombatMarkBinding()
end

-- 设置队列位置到指定标记的下一个
function NPW:SetMarkQueueToIndex(markIndex)
    -- 找到该标记在队列中的位置
    for i, mark in ipairs(self.state.combatMarkQueue) do
        if mark == markIndex then
            -- 设置到下一个位置
            self.state.combatMarkIndex = i + 1
            if self.state.combatMarkIndex > #self.state.combatMarkQueue then
                self.state.combatMarkIndex = 1
            end
            -- 更新绑定
            self:UpdateCombatMarkBinding()
            if self.db and self.db.debug then
                local nextMark = self.state.combatMarkQueue[self.state.combatMarkIndex]
                print("|cff00ffff[NPW]|r 队列同步 -> 标记 " .. nextMark)
            end
            break
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
 
    NPW:OnInitialize()
    NPW:OnEnable()
  
end)
