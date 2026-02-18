-- Config.lua
-- 配置管理模块

local _, NPW = ...

-- 默认配置
NPW.defaults = {
    -- 外观设置
    appearance = {
        outLineRadius=100,          --外盘半径
        wheelRadius = 25,          -- 轮盘半径
        iconSize = 30,              -- 图标大小
        opacity = 0.8,              -- 不透明度
        borderSize = 2,             -- 边框大小
        centerButtonSize = 30,      -- 中心按钮大小
    },

    -- 行为设置
    behavior = {
        doubleClickInterval = 300,  -- 双击间隔(毫秒)
        animationSpeed = 200,       -- 动画速度(毫秒)
        enableSound = false,         -- 启用音效
        closeOnMarkSet = true,      -- 设置标记后关闭
    },

    -- 调试 (强制开启以排查问题)
    debug = true,
}

-- 初始化配置
function NPW:InitConfig()
    -- 从 SavedVariables 加载或创建新配置
    if not NamePlateMarkerWheelDB then
        NamePlateMarkerWheelDB = {}
    end

    -- 深拷贝默认配置
    self.db = self:DeepCopy(self.defaults)

    -- 合并已保存的配置
    if NamePlateMarkerWheelDB.profile then
        self:MergeTables(self.db, NamePlateMarkerWheelDB.profile)
    end

    -- 保存引用到全局以便持久化
    NamePlateMarkerWheelDB.profile = self.db


end

-- 保存配置
function NPW:SaveConfig()
    NamePlateMarkerWheelDB.profile = self.db
  
end

-- 重置配置
function NPW:ResetConfig()
    self.db = self:DeepCopy(self.defaults)
    NamePlateMarkerWheelDB.profile = self.db
 
end

-- 获取配置值
function NPW:GetConfig(key)
    local keys = {strsplit(".", key)}
    local value = self.db
    for _, k in ipairs(keys) do
        value = value[k]
        if value == nil then
            return nil
        end
    end
    return value
end

-- 设置配置值
function NPW:SetConfig(key, value)
    local keys = {strsplit(".", key)}
    local target = self.db
    for i = 1, #keys - 1 do
        if not target[keys[i]] then
            target[keys[i]] = {}
        end
        target = target[keys[i]]
    end
    target[keys[#keys]] = value
    self:SaveConfig()
end

-- 创建配置界面
function NPW:CreateConfigPanel()
    -- 基础配置面板
    local panel = CreateFrame("Frame", "NamePlateMarkerWheelConfig", UIParent)
    panel.name = "NamePlateMarkerWheel"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Name Plate Marker Wheel")

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("版本: " .. self.VERSION)

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)
    desc:SetText("双击姓名板唤出标记轮盘\nShift+点击快速设置焦点+标记")

    -- 使用设置系统注册
    if Settings then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    end

    self.configPanel = panel
    return panel
end
