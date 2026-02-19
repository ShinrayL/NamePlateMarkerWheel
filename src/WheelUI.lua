-- WheelUI.lua
-- 轮盘UI模块 - 使用安全按钮实现

local _, NPW = ...

-- 创建轮盘框架
function NPW:CreateWheelFrame()
    -- 轮盘主框架（直接创建在UIParent上）
    local frame = CreateFrame("Frame", "NPW_WheelFrame", UIParent, "BackdropTemplate")
    frame:SetSize(self.db.appearance.outLineRadius, self.db.appearance.outLineRadius)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(false)
    frame:Hide()

    -- 背景 - 仅作为视觉元素，不拦截鼠标
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()

    -- 创建圆形遮罩（将矩形背景裁剪为圆形）
    frame.mask = frame:CreateMaskTexture()
    frame.mask:SetAllPoints(frame.bg)
    frame.mask:SetTexture("Interface\CHARACTERFRAME\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

    -- 应用遮罩到背景
    frame.bg:AddMaskTexture(frame.mask)

    -- 创建圆形边框（增强视觉效果）
    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints()
    frame.border:SetColorTexture(0.8, 0.8, 0.8, 0.6)  -- 更明显的浅灰色边框
    frame.border:AddMaskTexture(frame.mask)

    -- 设置初始背景颜色
    frame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

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
      
    end)

    -- 调试用：点击前检查宏设置
    btn:SetScript("PreClick", function(self, button)
       
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

-- 创建清除按钮（集成安全按钮模板，与其他标记按钮风格一致）
function NPW:CreateClearButton(parent)
    local size = self.db.appearance.centerButtonSize

    -- 直接使用 SecureActionButtonTemplate 创建按钮
    local btn = CreateFrame("Button", "NPW_ClearButton", parent, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:SetPoint("CENTER", parent, "CENTER", 0, 0)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonDown")

    -- 图标（与其他标记按钮一致，使用 ARTWORK 层级）
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")

    -- 高亮边框（与其他标记按钮一致）
    local highlight = btn:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0)
    btn.highlight = highlight

    -- 设置安全按钮属性
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "/tm 0")

    -- 悬停效果（与其他标记按钮一致）
    btn:SetScript("OnEnter", function()
        highlight:SetAlpha(0.8)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("清除标记")
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        highlight:SetAlpha(0)
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

-- 更新轮盘背景材质
function NPW:UpdateWheelTexture()
    local frame = self.state.wheelFrame
    if not frame or not frame.bg then return end

    -- 确保 appearance 配置存在
    if not self.db.appearance then
        self.db.appearance = {}
    end

    local texture = self.db.appearance.wheelTexture or "circle"
    local bg = frame.bg

    -- 移除所有遮罩，准备重新应用
    bg:RemoveMaskTexture(frame.mask)

    if texture == "circle" or texture == "solid" then
        -- 圆形纯色背景（默认）
        local color = self.db.appearance.wheelBackgroundColor or {r=0, g=0, b=0, a=0.5}
        local opacity = self.db.appearance.opacity or 0.8
        -- 使用 color.a 和 opacity 的乘积作为最终不透明度
        local finalAlpha = (color.a or 0.5) * opacity
        bg:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, finalAlpha)
        -- 应用圆形遮罩
        bg:AddMaskTexture(frame.mask)
    elseif texture == "circle-blizzard" or texture == "blizzard" then
        -- 圆形暴雪对话框背景
        local opacity = self.db.appearance.opacity or 0.8
        bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        bg:SetVertexColor(1, 1, 1, opacity)
        -- 应用圆形遮罩
        bg:AddMaskTexture(frame.mask)
    elseif texture == "circle-tooltip" or texture == "tooltip" then
        -- 圆形工具提示背景
        local opacity = self.db.appearance.opacity or 0.8
        bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bg:SetVertexColor(1, 1, 1, opacity)
        -- 应用圆形遮罩
        bg:AddMaskTexture(frame.mask)
    elseif texture == "circle-custom" or texture == "custom" then
        -- 圆形自定义材质
        local path = self.db.appearance.wheelTexturePath
        local opacity = self.db.appearance.opacity or 0.8
        if path and path ~= "" then
            bg:SetTexture(path)
            bg:SetVertexColor(1, 1, 1, opacity)
        else
            -- 使用默认纯色
            bg:SetColorTexture(0, 0, 0, opacity)
        end
        -- 应用圆形遮罩
        bg:AddMaskTexture(frame.mask)
    else
        -- 未知材质类型，使用默认圆形纯色
        local opacity = self.db.appearance.opacity or 0.8
        bg:SetColorTexture(0, 0, 0, opacity)
        bg:AddMaskTexture(frame.mask)
    end

    -- 更新边框遮罩和不透明度（确保边框也是圆形）
    if frame.border then
        local opacity = self.db.appearance.opacity or 0.8
        frame.border:RemoveMaskTexture(frame.mask)
        frame.border:SetColorTexture(0.8, 0.8, 0.8, 0.6 * opacity)
        frame.border:AddMaskTexture(frame.mask)
    end
end

-- 创建轮盘动画组（简化版，使用独立的缩放和淡入淡出）
function NPW:CreateWheelAnimations(frame)
    if frame.animationsCreated then return end

    -- 打开动画 - 使用缩放
    frame.showAnim = frame:CreateAnimationGroup()
    local scaleIn = frame.showAnim:CreateAnimation("Scale")
    scaleIn:SetTarget(frame)
    scaleIn:SetOrigin("CENTER", 0, 0)
    scaleIn:SetScaleFrom(0.1, 0.1)
    scaleIn:SetScaleTo(1, 1)
    scaleIn:SetDuration(0.2)
    scaleIn:SetSmoothing("OUT")

    -- 关闭动画
    frame.hideAnim = frame:CreateAnimationGroup()
    local scaleOut = frame.hideAnim:CreateAnimation("Scale")
    scaleOut:SetTarget(frame)
    scaleOut:SetOrigin("CENTER", 0, 0)
    scaleOut:SetScaleFrom(1, 1)
    scaleOut:SetScaleTo(0.1, 0.1)
    scaleOut:SetDuration(0.15)
    scaleOut:SetSmoothing("IN")

    -- 关闭动画完成回调
    frame.hideAnim:SetScript("OnFinished", function()
        frame:Hide()
        frame:SetScale(1)
        frame:SetAlpha(1)
    end)

    frame.animationsCreated = true
end

-- 显示轮盘
-- @param x, y: 屏幕坐标
-- @param guid: 目标单位的 GUID（主要标识）
function NPW:ShowWheel(x, y, guid)
    local frame = self.state.wheelFrame
    if not frame then
        self:Debug("ShowWheel: frame is nil")
        return
    end

    -- 从 GUID 获取当前可用的 unit token
    local unit = self:GetUnitFromGUID(guid)
    -- 如果无法获取unit但有目标，直接使用target（副本内必需）
    if not unit and UnitExists("target") then
        unit = "target"
    end
    if not unit then
        self:Debug("ShowWheel: no unit available")
        return
    end

    self:Debug("ShowWheel: unit=%s, guid=%s", tostring(unit), tostring(guid))

    -- 检查frame状态
    local frameWidth, frameHeight = frame:GetSize()
    self:Debug("ShowWheel: frame size=%s x %s", tostring(frameWidth), tostring(frameHeight))
    self:Debug("ShowWheel: position=%s, %s", tostring(x), tostring(y))

    -- 更新安全按钮的宏（使用从GUID解析出的unit token）
    self:UpdateSecureButtonMacros(unit, guid)

    -- 更新当前标记高亮
    self:UpdateCurrentMarkHighlight(unit)

    -- 应用当前材质
    self:UpdateWheelTexture()

    -- 设置位置
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

    -- 显示轮盘（带/不带动画）
    local enableAnimation = self.db.behavior and self.db.behavior.enableAnimation
    if enableAnimation then
        -- 确保动画组已创建
        if not frame.showAnim then
            self:CreateWheelAnimations(frame)
        end

        -- 检查动画组是否有效
        if frame.showAnim and frame.showAnim.Play then
            -- 停止之前的动画
            if frame.showAnim:IsPlaying() then
                frame.showAnim:Stop()
            end

            -- 更新动画持续时间
            local animSpeed = self.db.behavior.animationSpeed or 200
            local duration = animSpeed / 1000
            local scaleAnim = frame.showAnim:GetAnimations()
            if scaleAnim and scaleAnim.SetDuration then
                scaleAnim:SetDuration(duration)
            end

            -- 显示并播放动画
            frame:SetAlpha(1)
            frame:Show()
            frame.showAnim:Play()
            self:Debug("ShowWheel: playing show animation, duration=" .. duration)
        else
            -- 动画组无效，直接显示
            frame:SetScale(1)
            frame:SetAlpha(1)
            frame:Show()
            self:Debug("ShowWheel: animation invalid, showing directly")
        end
    else
        frame:SetScale(1)
        frame:SetAlpha(1)
        frame:Show()
        self:Debug("ShowWheel: showing directly (no animation)")
    end

    self.state.isWheelVisible = true
    self.state.currentGUID = guid
    self.state.currentUnit = unit

    -- 注册 ESC 关闭和世界点击关闭
    self:RegisterWheelCloseHandlers()
end

-- 从 GUID 获取可用的 unit token
function NPW:GetUnitFromGUID(guid)
    if not guid then return nil end
    return "target"
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


-- 隐藏轮盘
function NPW:HideWheel()
    local frame = self.state.wheelFrame
    if not frame or not frame:IsShown() then return end

    local enableAnimation = self.db.behavior and self.db.behavior.enableAnimation
    if enableAnimation then
        -- 确保动画组已创建
        if not frame.hideAnim then
            self:CreateWheelAnimations(frame)
        end

        -- 检查动画组是否有效
        if frame.hideAnim and frame.hideAnim.Play then
            -- 停止打开动画（如果正在播放）
            if frame.showAnim and frame.showAnim:IsPlaying() then
                frame.showAnim:Stop()
            end

            -- 更新动画持续时间（关闭动画稍快）
            local animSpeed = self.db.behavior.animationSpeed or 200
            local duration = (animSpeed / 1000) * 0.75
            local scaleAnim = frame.hideAnim:GetAnimations()
            if scaleAnim and scaleAnim.SetDuration then
                scaleAnim:SetDuration(duration)
            end

            -- 播放关闭动画
            frame.hideAnim:Play()
        else
            -- 动画组无效，直接隐藏
            frame:Hide()
        end
    else
        frame:Hide()
    end

    -- 更新状态
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

end

-- 更新当前标记高亮
function NPW:UpdateCurrentMarkHighlight(unit)
    if not unit then return end

    local success, currentMark = pcall(GetRaidTargetIndex, unit)
    if not success then return end

    local frame = self.state.wheelFrame
    if not frame or not frame.markButtons then return end

    for i = 1, 8 do
        local btn = frame.markButtons[i]
        if btn then
            pcall(function()
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
            end)
        end
    end
end

-- 更新轮盘布局（配置更改后调用）
function NPW:UpdateWheelLayout()
    local frame = self.state.wheelFrame
    if not frame then return end

    -- 确保 appearance 配置存在
    local appearance = self.db.appearance or {}
    local radius = appearance.wheelRadius or 25
    local iconSize = appearance.iconSize or 30
    local outLineRadius = appearance.outLineRadius or 100
    local centerButtonSize = appearance.centerButtonSize or 30

    -- 更新主框架大小
    frame:SetSize(outLineRadius, outLineRadius)

    -- 更新背景材质
    self:UpdateWheelTexture()

    -- 更新标记按钮位置和大小
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
        frame.clearButton:SetSize(centerButtonSize, centerButtonSize)
    end
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
