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
    if not unit then return end

    local frame = self.state.wheelFrame
    if not frame or not frame.markButtons then return end

    if UnitExists(unit) then
        for i = 1, 8 do
            local btn = frame.markButtons[i]
            if btn then
                local macro = "/tm [@" .. unit .. "] " .. i
                btn:SetAttribute("macrotext", macro)
            end
        end

        if frame.clearButton then
            local macro = "/tm [@" .. unit .. "] 0"
            frame.clearButton:SetAttribute("macrotext", macro)
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
 
    NPW:OnInitialize()
    NPW:OnEnable()
  
end)
