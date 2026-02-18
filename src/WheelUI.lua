-- WheelUI.lua
-- 轮盘UI模块 - 使用安全按钮实现

local _, NPW = ...

-- 创建轮盘框架
function NPW:CreateWheelFrame()
    -- 轮盘主框架（直接创建在UIParent上）
    local frame = CreateFrame("Frame", "NPW_WheelFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(false)
    frame:Hide()

    -- 背景 - 仅作为视觉元素，不拦截鼠标
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)

    -- 禁用主框架的鼠标捕获，让子按钮直接接收点击
    frame:EnableMouse(false)
    frame:SetMouseClickEnabled(false)

    -- 创建8个标记按钮
    frame.markButtons = {}
    for i = 1, 8 do
        frame.markButtons[i] = self:CreateMarkButton(frame, i)
    end

    -- 中心清除按钮
    frame.clearButton = self:CreateClearButton(frame)

    self.state.wheelFrame = frame
    self:Debug("Wheel frame created")
    return frame
end

-- 创建标记按钮（集成安全按钮模板）
function NPW:CreateMarkButton(parent, index)
    local config = self.MARKERS[index]
    local iconSize = self.db.appearance.iconSize

    -- 直接使用 SecureActionButtonTemplate 创建按钮
    local btn = CreateFrame("Button", "NPW_MarkButton" .. index, parent, "SecureActionButtonTemplate")
    btn:SetSize(iconSize, iconSize)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonDown")

    -- 调试用：确认点击事件
    btn:SetScript("OnMouseDown", function(self, button)
        NPW:Debug("OnMouseDown Button " .. index .. " with " .. button)
    end)

    -- 调试用：点击前检查宏设置
    btn:SetScript("PreClick", function(self, button)
        NPW:Debug("PreClick Button " .. index .. ": type=" .. tostring(self:GetAttribute("type")) .. ", macro=" .. tostring(self:GetAttribute("macrotext")))
    end)

    -- 计算位置
    local radius = self.db.appearance.wheelRadius
    local x, y = self:CalculateWheelPosition(index, 0, 0, radius)
    btn:SetPoint("CENTER", parent, "CENTER", x, y)

    -- 图标
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(config.icon)

    -- 高亮边框
    local highlight = btn:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0)
    btn.highlight = highlight

    -- 设置安全按钮属性
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "/tm " .. index)

    -- 悬停效果
    btn:SetScript("OnEnter", function()
        highlight:SetAlpha(0.8)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(config.name)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        highlight:SetAlpha(0)
        GameTooltip:Hide()
    end)

    -- 点击后关闭轮盘（使用 PostClick 确保宏先执行）
    btn:SetScript("PostClick", function()
        if self.db.behavior.closeOnMarkSet then
            C_Timer.After(0.1, function()
                self:HideWheel()
            end)
        end
    end)

    -- 保存引用
    btn.index = index
    btn.icon = icon

    return btn
end

-- 创建清除按钮（集成安全按钮模板）
function NPW:CreateClearButton(parent)
    local size = self.db.appearance.centerButtonSize

    -- 直接使用 SecureActionButtonTemplate 创建按钮
    local btn = CreateFrame("Button", "NPW_ClearButton", parent, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:SetPoint("CENTER", parent, "CENTER", 0, 0)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonDown")

    -- 背景
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    btn.bg = bg

    -- 图标
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")

    -- 设置安全按钮属性
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "/tm 0")

    -- 调试用：点击前检查宏设置
    btn:SetScript("PreClick", function(self, button)
        NPW:Debug("PreClick ClearButton: type=" .. tostring(self:GetAttribute("type")) .. ", macro=" .. tostring(self:GetAttribute("macrotext")))
    end)

    -- 悬停效果
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(0.5, 0.2, 0.2, 0.9)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("清除标记")
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        GameTooltip:Hide()
    end)

    -- 点击后关闭轮盘
    btn:SetScript("PostClick", function()
        if self.db.behavior.closeOnMarkSet then
            C_Timer.After(0.1, function()
                self:HideWheel()
            end)
        end
    end)

    return btn
end

-- 显示轮盘
-- @param x, y: 屏幕坐标
-- @param guid: 目标单位的 GUID（主要标识）
function NPW:ShowWheel(x, y, guid)
    self:Debug("ShowWheel called, guid=" .. tostring(guid))

    local frame = self.state.wheelFrame
    if not frame then
        self:Debug("ERROR: wheelFrame is nil!")
        return
    end

    -- 从 GUID 获取当前可用的 unit token
    local unit = self:GetUnitFromGUID(guid)
    -- 如果无法获取unit但有目标，直接使用target（副本内必需）
    if not unit and UnitExists("target") then
        unit = "target"
        self:Debug("Using target directly")
    end
    if not unit then
        self:Debug("ERROR: No unit available")
        return
    end

    -- 更新安全按钮的宏（使用从GUID解析出的unit token）
    self:UpdateSecureButtonMacros(unit, guid)

    -- 设置轮盘位置
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

    -- 更新当前标记高亮
    self:UpdateCurrentMarkHighlight(unit)

    -- 显示轮盘
    frame:Show()

    self.state.isWheelVisible = true
    self.state.currentGUID = guid  -- 保存 GUID（主要标识）
    self.state.currentUnit = unit  -- 保存当前 unit token（临时）

    self:Debug("Wheel shown at: " .. x .. ", " .. y .. ", unit=" .. unit)

    -- 注册 ESC 关闭和世界点击关闭
    self:RegisterWheelCloseHandlers()
end

-- 从 GUID 获取可用的 unit token
function NPW:GetUnitFromGUID(guid)
    if not guid then
        self:Debug("GetUnitFromGUID: guid is nil")
        return nil
    end

    -- 方法1: 如果当前目标匹配，使用 target（副本内最可靠）
    if UnitGUID("target") == guid then
        self:Debug("GetUnitFromGUID: found via target")
        return "target"
    end

    -- 方法2: 使用 UnitTokenFromGUID
    local token = UnitTokenFromGUID(guid)
    if token and UnitExists(token) then
        self:Debug("GetUnitFromGUID: found via UnitTokenFromGUID = " .. token)
        return token
    end

    -- 方法3: 遍历姓名板查找匹配的GUID
    local nameplates = C_NamePlate.GetNamePlates()
    for _, np in ipairs(nameplates) do
        if np.unit and UnitGUID(np.unit) == guid then
            self:Debug("GetUnitFromGUID: found via nameplate = " .. np.unit)
            return np.unit
        end
    end

    -- 方法4: 尝试 focus
    if UnitGUID("focus") == guid then
        self:Debug("GetUnitFromGUID: found via focus")
        return "focus"
    end

    -- 方法5: 如果是玩家自己
    if UnitGUID("player") == guid then
        self:Debug("GetUnitFromGUID: found via player")
        return "player"
    end

    self:Debug("GetUnitFromGUID: not found")
    return nil
end

-- 注册轮盘关闭处理器
function NPW:RegisterWheelCloseHandlers()
    -- ESC 键关闭
    if not self.escHandler then
        self.escHandler = CreateFrame("Frame")
        self.escHandler:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" and self:IsWheelVisible() then
                self:HideWheel()
            end
        end)
    end
    self.escHandler:SetPropagateKeyboardInput(true)

    -- 点击外部关闭：使用低层级的透明帧只覆盖轮盘外部区域
    -- 注意：不能使用全屏覆盖，否则会拦截安全按钮的点击
    C_Timer.After(0.1, function()
        if not self:IsWheelVisible() then return end

        -- 创建4个边缘帧来包围轮盘（形成一个"洞"让轮盘可以接收点击）
        if not self.clickOutFrames then
            self.clickOutFrames = {}
            for i = 1, 4 do
                local f = CreateFrame("Frame")
                f:SetFrameStrata("BACKGROUND")
                f:SetFrameLevel(1)
                f:EnableMouse(true)
                f:SetScript("OnMouseDown", function()
                    if self:IsWheelVisible() then
                        self:HideWheel()
                    end
                end)
                self.clickOutFrames[i] = f
            end
        end

        local frame = self.state.wheelFrame
        if not frame then return end

        local scale = UIParent:GetEffectiveScale()
        local screenW, screenH = GetScreenWidth(), GetScreenHeight()
        local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()

        -- 左边缘
        self.clickOutFrames[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        self.clickOutFrames[1]:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", left, 0)
        self.clickOutFrames[1]:Show()

        -- 右边缘
        self.clickOutFrames[2]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right, 0)
        self.clickOutFrames[2]:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        self.clickOutFrames[2]:Show()

        -- 上边缘（轮盘上方）
        self.clickOutFrames[3]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, 0)
        self.clickOutFrames[3]:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", right, top - screenH)
        self.clickOutFrames[3]:Show()

        -- 下边缘（轮盘下方）
        self.clickOutFrames[4]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, bottom)
        self.clickOutFrames[4]:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        self.clickOutFrames[4]:Show()
    end)
end

-- 注：PositionSecureButtons 不再需要
-- 安全按钮已直接集成到视觉按钮中，位置在创建时已设置
function NPW:PositionSecureButtons()
    -- 此函数保留用于向后兼容，不再执行任何操作
    self:Debug("PositionSecureButtons deprecated - buttons are now integrated")
end

-- 隐藏轮盘
function NPW:HideWheel()
    local frame = self.state.wheelFrame
    if not frame or not frame:IsShown() then return end

    frame:Hide()

    self.state.isWheelVisible = false
    self.state.currentUnit = nil
    self.state.currentGUID = nil

    -- 隐藏点击外部检测帧
    if self.clickOutFrames then
        for i = 1, 4 do
            if self.clickOutFrames[i] then
                self.clickOutFrames[i]:Hide()
            end
        end
    end

    -- 注：安全按钮现在集成在视觉按钮中，会随着 frame:Hide() 自动隐藏

    self:Debug("Wheel hidden")

    -- 播放音效
    if self.db.behavior.enableSound then
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end
end

-- 更新当前标记高亮
function NPW:UpdateCurrentMarkHighlight(unit)
    if not unit then return end

    local currentMark = GetRaidTargetIndex(unit)
    local frame = self.state.wheelFrame
    if not frame or not frame.markButtons then return end

    for i = 1, 8 do
        local btn = frame.markButtons[i]
        if btn then
            if i == currentMark then
                -- 当前标记高亮
                btn.icon:SetVertexColor(1, 1, 1, 1)
                btn.highlight:SetAlpha(1)
                btn:SetScale(1.2)
            else
                -- 其他标记正常
                btn.icon:SetVertexColor(1, 1, 1, 0.6)
                btn.highlight:SetAlpha(0)
                btn:SetScale(1)
            end
        end
    end

    self:Debug("Current mark highlight updated: " .. tostring(currentMark))
end

-- 更新轮盘布局（配置更改后调用）
function NPW:UpdateWheelLayout()
    local frame = self.state.wheelFrame
    if not frame then return end

    local radius = self.db.appearance.wheelRadius
    local iconSize = self.db.appearance.iconSize

    -- 更新标记按钮位置
    for i = 1, 8 do
        local btn = frame.markButtons[i]
        if btn then
            btn:SetSize(iconSize, iconSize)
            local x, y = self:CalculateWheelPosition(i, 0, 0, radius)
            btn:ClearAllPoints()
            btn:SetPoint("CENTER", frame, "CENTER", x, y)
        end
    end

    -- 更新中心按钮大小
    if frame.clearButton then
        frame.clearButton:SetSize(self.db.appearance.centerButtonSize, self.db.appearance.centerButtonSize)
    end

    self:Debug("Wheel layout updated")
end

-- 检查轮盘是否可见
function NPW:IsWheelVisible()
    local frame = self.state.wheelFrame
    return frame and frame:IsShown()
end

-- 切换轮盘显示（用于快捷键）
function NPW:ToggleWheel(x, y, unit)
    if self:IsWheelVisible() then
        self:HideWheel()
    else
        -- 获取鼠标位置
        if not x or not y then
            local mx, my = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = mx / scale
            y = my / scale
        end
        self:ShowWheel(x, y, unit or "mouseover")
    end
end
