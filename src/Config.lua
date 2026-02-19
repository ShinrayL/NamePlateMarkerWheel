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
        wheelTexture = "circle",                -- 轮盘材质预设: "circle" | "circle-blizzard" | "circle-tooltip" | "circle-custom" | "solid" | "blizzard" | "tooltip" | "custom"
        wheelTexturePath = "",                  -- 自定义材质路径
        wheelBackgroundColor = {r=0, g=0, b=0, a=0.5},  -- 纯色背景颜色
    },

    -- 行为设置
    behavior = {
        doubleClickInterval = 300,  -- 双击间隔(毫秒)
        animationSpeed = 200,       -- 动画速度(毫秒)
        enableSound = false,         -- 启用音效
        closeOnMarkSet = true,      -- 设置标记后关闭
        enableAnimation = true,     -- 启用打开/关闭动画
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

    -- 确保所有必需的配置键都存在（处理新增配置项）
    self:ValidateConfig()

    -- 保存引用到全局以便持久化
    NamePlateMarkerWheelDB.profile = self.db

end

-- 验证并修复配置（确保所有必需键存在）
function NPW:ValidateConfig()
    -- 确保 appearance 存在
    if not self.db.appearance then
        self.db.appearance = self:DeepCopy(self.defaults.appearance)
    else
        -- 检查所有 appearance 子键
        for k, v in pairs(self.defaults.appearance) do
            if self.db.appearance[k] == nil then
                self.db.appearance[k] = self:DeepCopy(v)
            end
        end
    end

    -- 确保 behavior 存在
    if not self.db.behavior then
        self.db.behavior = self:DeepCopy(self.defaults.behavior)
    else
        -- 检查所有 behavior 子键
        for k, v in pairs(self.defaults.behavior) do
            if self.db.behavior[k] == nil then
                self.db.behavior[k] = self:DeepCopy(v)
            end
        end
    end

    -- 确保 debug 存在
    if self.db.debug == nil then
        self.db.debug = self.defaults.debug
    end
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

-- 配置变更回调
function NPW:OnConfigChanged(key, value)
    -- 检查是否是外观相关配置
    local appearanceKeys = {
        ["appearance.outLineRadius"] = true,
        ["appearance.wheelRadius"] = true,
        ["appearance.iconSize"] = true,
        ["appearance.opacity"] = true,
        ["appearance.centerButtonSize"] = true,
        ["appearance.wheelTexture"] = true,
        ["appearance.wheelTexturePath"] = true,
        ["appearance.wheelBackgroundColor"] = true,
    }

    if appearanceKeys[key] then
        -- 外观配置变更，实时更新轮盘布局和材质
        self:UpdateWheelLayout()
        self:UpdateWheelTexture()
    end

    -- 特殊处理：颜色变更也需要刷新面板显示
    if key == "appearance.wheelBackgroundColor" then
        self:RefreshConfigPanel()
    end
end

-- 创建分隔线
local function CreateSectionHeader(parent, text, offsetY)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, offsetY)
    header:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-TabLine")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, offsetY - 4)
    line:SetHeight(16)
    line:SetTexCoord(0, 1, 0.25, 0.35)

    return offsetY - 40
end

-- 创建滑块控件
local function CreateSlider(parent, label, tooltip, minVal, maxVal, step, defaultVal, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(40)
    frame:SetWidth(340)

    local labelText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    labelText:SetText(label)

    local valueText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    valueText:SetText(tostring(getter()))

    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(320)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(getter())

    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))

    slider:SetScript("OnValueChanged", function(self, value)
        -- 根据步进值格式化
        local formattedValue
        if step < 1 then
            formattedValue = tonumber(string.format("%.1f", value))
        else
            formattedValue = math.floor(value / step + 0.5) * step
        end
        valueText:SetText(tostring(formattedValue))
        setter(formattedValue)
    end)

    -- 鼠标提示
    slider:SetScript("OnEnter", function()
        GameTooltip:SetOwner(slider, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    slider:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 保存引用以便刷新
    frame.slider = slider
    frame.valueText = valueText

    return frame
end

-- 创建复选框控件
local function CreateCheckbox(parent, label, tooltip, getter, setter)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetChecked(getter())

    checkbox.text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    checkbox.text:SetText(label)

    checkbox:SetScript("OnClick", function(self)
        setter(self:GetChecked())
    end)

    -- 鼠标提示
    checkbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(checkbox, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return checkbox
end

-- 创建下拉菜单控件
local function CreateDropdown(parent, label, tooltip, options, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(40)
    frame:SetWidth(340)

    local labelText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    labelText:SetText(label)

    local dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -16, -4)
    dropdown:SetWidth(320)

    local currentValue = getter()

    local function OnClick(self)
        UIDropDownMenu_SetSelectedValue(dropdown, self.value)
        setter(self.value)
    end

    local function Initialize(self)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = OnClick
            info.checked = currentValue == option.value
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
    UIDropDownMenu_SetText(dropdown, options[1].text)
    for _, opt in ipairs(options) do
        if opt.value == currentValue then
            UIDropDownMenu_SetText(dropdown, opt.text)
            break
        end
    end

    -- 鼠标提示
    dropdown:SetScript("OnEnter", function()
        GameTooltip:SetOwner(dropdown, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.dropdown = dropdown
    return frame
end

-- 创建文本输入框控件
local function CreateEditBox(parent, label, tooltip, width, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(50)
    frame:SetWidth(width or 340)

    local labelText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    labelText:SetText(label)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
    editBox:SetWidth((width or 340) - 20)
    editBox:SetHeight(24)
    editBox:SetAutoFocus(false)
    editBox:SetText(getter() or "")

    editBox:SetScript("OnTextChanged", function(self, isUserInput)
        if isUserInput then
            setter(self:GetText())
        end
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        setter(self:GetText())
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- 鼠标提示
    editBox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(editBox, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    editBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.editBox = editBox
    return frame
end

-- 创建配置界面
function NPW:CreateConfigPanel()
    -- 如果已经存在则返回
    if self.configPanel then
        return self.configPanel
    end

    -- 创建独立窗口
    local frame = CreateFrame("Frame", "NPW_ConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- 背景
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- 标题栏
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetPoint("TOP", 0, 12)
    titleBg:SetSize(350, 64)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", titleBg, "TOP", 0, -14)
    title:SetText("NPW 配置")

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- 滚动框架
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 48)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(340)
    scrollFrame:SetScrollChild(content)

    local currentY = 0
    local currentX = 10
    -- ========== 外观设置 ==========
    currentY = CreateSectionHeader(content, "外观设置", currentY)

    -- 外盘半径滑块
    local outLineRadiusSlider = CreateSlider(
        content,
        "外盘半径",
        "设置轮盘外圈的半径大小（50-200）",
        50, 200, 5,
        self.defaults.appearance.outLineRadius,
        function() return self:GetConfig("appearance.outLineRadius") end,
        function(val)
            self:SetConfig("appearance.outLineRadius", val)
            self:OnConfigChanged("appearance.outLineRadius", val)
        end
    )
    outLineRadiusSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 轮盘半径滑块
    local wheelRadiusSlider = CreateSlider(
        content,
        "轮盘半径",
        "设置标记按钮的分布半径（20-100）",
        20, 100, 5,
        self.defaults.appearance.wheelRadius,
        function() return self:GetConfig("appearance.wheelRadius") end,
        function(val)
            self:SetConfig("appearance.wheelRadius", val)
            self:OnConfigChanged("appearance.wheelRadius", val)
        end
    )
    wheelRadiusSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 图标大小滑块
    local iconSizeSlider = CreateSlider(
        content,
        "图标大小",
        "设置标记图标的大小（16-64）",
        16, 64, 2,
        self.defaults.appearance.iconSize,
        function() return self:GetConfig("appearance.iconSize") end,
        function(val)
            self:SetConfig("appearance.iconSize", val)
            self:OnConfigChanged("appearance.iconSize", val)
        end
    )
    iconSizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 不透明度滑块
    local opacitySlider = CreateSlider(
        content,
        "不透明度",
        "设置轮盘背景的不透明度（0-1.0）",
        0, 1.0, 0.05,
        self.defaults.appearance.opacity,
        function() return self:GetConfig("appearance.opacity") end,
        function(val)
            self:SetConfig("appearance.opacity", val)
            self:OnConfigChanged("appearance.opacity", val)
        end
    )
    opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 中心按钮大小滑块
    local centerBtnSlider = CreateSlider(
        content,
        "中心按钮大小",
        "设置中心清除按钮的大小（20-50）",
        20, 50, 2,
        self.defaults.appearance.centerButtonSize,
        function() return self:GetConfig("appearance.centerButtonSize") end,
        function(val)
            self:SetConfig("appearance.centerButtonSize", val)
            self:OnConfigChanged("appearance.centerButtonSize", val)
        end
    )
    centerBtnSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 60

    -- 轮盘材质下拉菜单
    local textureOptions = {
        { text = "圆形纯色", value = "circle" },
        { text = "圆形暴雪风格", value = "circle-blizzard" },
        { text = "圆形工具提示", value = "circle-tooltip" },
        { text = "圆形自定义", value = "circle-custom" },
        { text = "矩形纯色", value = "solid" },
        { text = "矩形暴雪风格", value = "blizzard" },
        { text = "矩形工具提示", value = "tooltip" },
        { text = "矩形自定义", value = "custom" },
    }
    local textureDropdown = CreateDropdown(
        content,
        "轮盘材质",
        "选择轮盘背景材质样式",
        textureOptions,
        function() return self:GetConfig("appearance.wheelTexture") end,
        function(val)
            self:SetConfig("appearance.wheelTexture", val)
            self:OnConfigChanged("appearance.wheelTexture", val)
            -- 刷新面板显示/隐藏条件控件
            if self.configPanel then
                self:RefreshConfigPanel()
            end
        end
    )
    textureDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 纯色颜色选择器容器（条件显示）
    local colorContainer = CreateFrame("Frame", nil, content)
    colorContainer:SetHeight(140)
    colorContainer:SetWidth(340)
    colorContainer:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)

    -- RGBA颜色滑块
    local function CreateColorSlider(parent, label, colorKey, minVal, maxVal, step)
        local sliderFrame = CreateFrame("Frame", nil, parent)
        sliderFrame:SetHeight(30)
        sliderFrame:SetWidth(340)

        local labelText = sliderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        labelText:SetPoint("LEFT", sliderFrame, "LEFT", 0, 0)
        labelText:SetText(label)
        labelText:SetWidth(60)

        local valueText = sliderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        valueText:SetPoint("RIGHT", sliderFrame, "RIGHT", 0, 0)
        valueText:SetWidth(40)

        local slider = CreateFrame("Slider", nil, sliderFrame, "OptionsSliderTemplate")
        slider:SetPoint("LEFT", labelText, "RIGHT", 10, 0)
        slider:SetPoint("RIGHT", valueText, "LEFT", -10, 0)
        slider:SetHeight(16)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)

        local function UpdateValue()
            local color = NPW:GetConfig("appearance.wheelBackgroundColor") or {r=0, g=0, b=0, a=0.5}
            return color[colorKey] or 0
        end

        slider:SetValue(UpdateValue())
        valueText:SetText(string.format("%.2f", UpdateValue()))

        slider.Low:SetText(tostring(minVal))
        slider.High:SetText(tostring(maxVal))

        slider:SetScript("OnValueChanged", function(_, value)
            local formattedValue = tonumber(string.format("%.2f", value))
            valueText:SetText(string.format("%.2f", formattedValue))
            local color = NPW:GetConfig("appearance.wheelBackgroundColor") or {r=0, g=0, b=0, a=0.5}
            color[colorKey] = formattedValue
            NPW:SetConfig("appearance.wheelBackgroundColor", color)
            NPW:OnConfigChanged("appearance.wheelBackgroundColor", color)
        end)

        sliderFrame.slider = slider
        sliderFrame.valueText = valueText
        return sliderFrame
    end

    local colorRSlider = CreateColorSlider(colorContainer, "红色", "r", 0, 1, 0.05)
    colorRSlider:SetPoint("TOPLEFT", colorContainer, "TOPLEFT", 0, 0)

    local colorGSlider = CreateColorSlider(colorContainer, "绿色", "g", 0, 1, 0.05)
    colorGSlider:SetPoint("TOPLEFT", colorContainer, "TOPLEFT", 0, -30)

    local colorBSlider = CreateColorSlider(colorContainer, "蓝色", "b", 0, 1, 0.05)
    colorBSlider:SetPoint("TOPLEFT", colorContainer, "TOPLEFT", 0, -60)

    local colorASlider = CreateColorSlider(colorContainer, "透明度", "a", 0, 1, 0.05)
    colorASlider:SetPoint("TOPLEFT", colorContainer, "TOPLEFT", 0, -90)

    currentY = currentY - 140

    -- 保存颜色滑块引用
    frame.colorSliders = {
        r = colorRSlider,
        g = colorGSlider,
        b = colorBSlider,
        a = colorASlider,
    }

    -- 自定义材质路径输入框（条件显示）
    local customPathEdit = CreateEditBox(
        content,
        "自定义材质路径",
        "输入自定义材质路径，例如：Interface\\AddOns\\YourAddon\\texture.tga",
        340,
        function() return self:GetConfig("appearance.wheelTexturePath") end,
        function(val)
            self:SetConfig("appearance.wheelTexturePath", val)
            self:OnConfigChanged("appearance.wheelTexturePath", val)
        end
    )
    customPathEdit:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 60

    -- 保存条件控件引用以便刷新
    frame.conditionalControls = {
        colorContainer = colorContainer,
        customPathEdit = customPathEdit,
    }

    -- 初始更新条件显示
    local initialTexture = self:GetConfig("appearance.wheelTexture")
    local isSolid = initialTexture == "solid" or initialTexture == "circle"
    local isCustom = initialTexture == "custom" or initialTexture == "circle-custom"
    colorContainer:SetShown(isSolid)
    customPathEdit:SetShown(isCustom)

    -- ========== 行为设置 ==========
    currentY = CreateSectionHeader(content, "行为设置", currentY)

    -- 双击间隔滑块
    local doubleClickSlider = CreateSlider(
        content,
        "双击间隔",
        "设置双击检测的时间间隔（毫秒）",
        200, 500, 50,
        self.defaults.behavior.doubleClickInterval,
        function() return self:GetConfig("behavior.doubleClickInterval") end,
        function(val)
            self:SetConfig("behavior.doubleClickInterval", val)
        end
    )
    doubleClickSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 50

    -- 动画速度滑块
    local animSpeedSlider = CreateSlider(
        content,
        "动画速度",
        "设置轮盘打开/关闭动画的速度（毫秒）",
        100, 500, 50,
        self.defaults.behavior.animationSpeed,
        function() return self:GetConfig("behavior.animationSpeed") end,
        function(val)
            self:SetConfig("behavior.animationSpeed", val)
        end
    )
    animSpeedSlider:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 40

    -- 启用动画复选框
    local enableAnimCheckbox = CreateCheckbox(
        content,
        "启用动画",
        "启用轮盘打开/关闭的缩放和淡入淡出动画",
        function() return self:GetConfig("behavior.enableAnimation") end,
        function(val)
            self:SetConfig("behavior.enableAnimation", val)
        end
    )
    enableAnimCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 35

    -- 设置标记后关闭复选框
    local closeOnMarkCheckbox = CreateCheckbox(
        content,
        "设置标记后关闭轮盘",
        "设置标记后自动关闭轮盘",
        function() return self:GetConfig("behavior.closeOnMarkSet") end,
        function(val)
            self:SetConfig("behavior.closeOnMarkSet", val)
        end
    )
    closeOnMarkCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 60

    -- ========== 调试设置 ==========
    currentY = CreateSectionHeader(content, "调试", currentY)

    -- 调试模式复选框
    local debugCheckbox = CreateCheckbox(
        content,
        "调试模式",
        "启用调试输出到聊天窗口",
        function() return self:GetConfig("debug") end,
        function(val)
            self:SetConfig("debug", val)
        end
    )
    debugCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", currentX, currentY)
    currentY = currentY - 60

    -- 设置内容高度
    content:SetHeight(math.abs(currentY) + 20)

    -- 更新滚动范围
    scrollFrame:UpdateScrollChildRect()

    -- 保存所有控件引用以便刷新
    frame.controls = {
        { type = "slider", key = "appearance.outLineRadius", control = outLineRadiusSlider.slider, valueText = outLineRadiusSlider.valueText },
        { type = "slider", key = "appearance.wheelRadius", control = wheelRadiusSlider.slider, valueText = wheelRadiusSlider.valueText },
        { type = "slider", key = "appearance.iconSize", control = iconSizeSlider.slider, valueText = iconSizeSlider.valueText },
        { type = "slider", key = "appearance.opacity", control = opacitySlider.slider, valueText = opacitySlider.valueText },
        { type = "slider", key = "appearance.centerButtonSize", control = centerBtnSlider.slider, valueText = centerBtnSlider.valueText },
        { type = "slider", key = "behavior.doubleClickInterval", control = doubleClickSlider.slider, valueText = doubleClickSlider.valueText },
        { type = "slider", key = "behavior.animationSpeed", control = animSpeedSlider.slider, valueText = animSpeedSlider.valueText },
        { type = "checkbox", key = "behavior.enableAnimation", control = enableAnimCheckbox },
        { type = "checkbox", key = "behavior.closeOnMarkSet", control = closeOnMarkCheckbox },
        { type = "checkbox", key = "debug", control = debugCheckbox },
    }

    -- 刷新配置面板显示
    function self:RefreshConfigPanel()
        if not self.configPanel or not self.configPanel.conditionalControls then return end

        local texture = self:GetConfig("appearance.wheelTexture")
        local isSolid = texture == "solid" or texture == "circle"
        local isCustom = texture == "custom" or texture == "circle-custom"
        self.configPanel.conditionalControls.colorContainer:SetShown(isSolid)
        self.configPanel.conditionalControls.customPathEdit:SetShown(isCustom)

        -- 更新颜色滑块值
        local sliders = self.configPanel.colorSliders
        if isSolid and sliders then
            local color = NPW:GetConfig("appearance.wheelBackgroundColor") or {r=0, g=0, b=0, a=0.5}
            sliders.r.slider:SetValue(color.r or 0)
            sliders.g.slider:SetValue(color.g or 0)
            sliders.b.slider:SetValue(color.b or 0)
            sliders.a.slider:SetValue(color.a or 0.5)
        end
    end

    -- ========== 重置按钮 ==========
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 24)
    resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    resetButton:SetText("恢复默认配置")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("NPW_RESET_CONFIG")
    end)

    -- 创建静态弹窗用于确认重置
    if not StaticPopupDialogs["NPW_RESET_CONFIG"] then
        StaticPopupDialogs["NPW_RESET_CONFIG"] = {
            text = "确定要恢复所有配置到默认值吗？此操作不可撤销。",
            button1 = "确定",
            button2 = "取消",
            OnAccept = function()
                NPW:ResetConfig()
                -- 刷新配置面板控件值
                if NPW.configPanel and NPW.configPanel.controls then
                    for _, item in ipairs(NPW.configPanel.controls) do
                        local value = NPW:GetConfig(item.key)
                        if item.type == "slider" then
                            item.control:SetValue(value)
                            if item.valueText then
                                item.valueText:SetText(tostring(value))
                            end
                        elseif item.type == "checkbox" then
                            item.control:SetChecked(value)
                        end
                    end
                end
                -- 刷新条件显示控件
                NPW:RefreshConfigPanel()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
    end

    self.configPanel = frame
    return frame
end
