-- Core.lua
-- NamePlateMarkerWheel 核心模块

local _, NPW = ...
_G.NamePlateMarkerWheel = NPW

-- 版本信息
NPW.VERSION = "1.0.0"

-- 运行时状态
NPW.state = {
    isWheelVisible = false,
    currentUnit = nil,      -- 当前 unit token（临时）
    currentGUID = nil,      -- 当前目标的 GUID（主要标识）
    wheelFrame = nil,
    wheelOverlay = nil,
    lastClickTime = 0,
    lastClickUnit = nil,
    secureButtons = {},
}

-- 常量定义
NPW.constants = {
    NUM_MARKS = 8,
    DOUBLE_CLICK_THRESHOLD = 300, -- 毫秒
    DEFAULT_RADIUS = 100,
    DEFAULT_ICON_SIZE = 32,
}

-- 插件初始化
function NPW:OnInitialize()
    -- 初始化配置
    self:InitConfig()
    -- 创建轮盘UI
    self:CreateWheelFrame()
    -- 注册斜杠命令
    self:RegisterSlashCommands()
    self:Debug("Core initialized")
end

-- 插件启用
function NPW:OnEnable()
    -- 初始化事件监听
    self:InitEvents()
end

-- 注：现在操作的是集成在视觉按钮中的安全按钮
-- @param unit: 当前可用的 unit token（临时）
-- @param guid: 目标单位的 GUID（主要标识，可选）
function NPW:UpdateSecureButtonMacros(unit, guid)
    self:Debug("51 here,unit:"..tostring(unit).." guid:"..tostring(guid))
    if not unit then
        self:Debug("ERROR: unit is nil")
        return
    end

    local frame = self.state.wheelFrame
    self:Debug("58 here")
    if not frame or not frame.markButtons then
        self:Debug("ERROR: wheel frame or buttons not ready")
        return
    end

    -- 如果有 GUID，在按钮点击时重新解析（确保目标切换后仍能正确标记）
    local useGUID = guid and guid ~= ""
    self:Debug("66 here")

    if  UnitExists(unit) then
        -- 标准单位token：使用 [@unit] 语法
        self:Debug("Using unit token with macro: " .. unit .. (useGUID and " (with GUID backup)" or ""))

        for i = 1, 8 do
            local btn = frame.markButtons[i]
            if btn then
                 local macro = "/tm [@" .. unit .. "] " .. i
                btn:SetAttribute("macrotext", macro)
                btn:SetAttribute("npw-guid", guid or "")  -- 保存 GUID 供后续使用
                self:Debug("Button " .. i .. " macro: " .. macro)
            end
        end

        if frame.clearButton then
            local macro = "/tm [@" .. unit .. "] 0"
            frame.clearButton:SetAttribute("macrotext", macro)
            frame.clearButton:SetAttribute("npw-guid", guid or "")
            self:Debug("Clear button macro: " .. macro)
        end
    else
        -- 名称方式：使用 /targetexact（备用方案）
        self:Debug("Using name-based macro for: " .. unit)

        for i = 1, 8 do
            local btn = frame.markButtons[i]
            if btn then
                local macro = "/targetexact " .. unit .. "\n/tm " .. i .. "\n/targetlasttarget"
                btn:SetAttribute("macrotext", macro)
                btn:SetAttribute("npw-guid", guid or "")
            end
        end

        if frame.clearButton then
            local macro = "/targetexact " .. unit .. "\n/tm 0\n/targetlasttarget"
            frame.clearButton:SetAttribute("macrotext", macro)
            frame.clearButton:SetAttribute("npw-guid", guid or "")
        end
    end

    self:Debug("Secure button macros updated")
end





-- 插件加载完成
print("|cff00ffff[NPW]|r 插件文件已加载，等待 PLAYER_LOGIN...")

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    print("|cff00ffff[NPW]|r PLAYER_LOGIN 事件触发，开始初始化...")
    NPW:OnInitialize()
    NPW:OnEnable()
    print("|cff00ffff[NPW]|r 初始化完成！")
end)
