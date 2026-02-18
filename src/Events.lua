-- Events.lua
-- 事件处理和双击检测模块 - 使用WorldFrame钩子方式

local _, NPW = ...

-- 初始化事件监听
function NPW:InitEvents()
    self:Debug("Initializing events (WorldFrame hook mode)...")

    -- 钩住WorldFrame的鼠标事件（游戏世界点击）
    self:HookWorldFrame()

    -- 也钩住目标改变事件（用于重置点击状态）
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    self.eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            -- 目标改变时重置点击记录
            self.state.lastClickTime = 0
            self.state.lastClickUnit = nil
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            -- 检查是否移除了当前目标
            if unit == self.state.lastClickUnit then
                self.state.lastClickTime = 0
                self.state.lastClickUnit = nil
            end
        end
    end)

    self:Debug("Events initialized (WorldFrame hook mode)")
end

-- 钩住WorldFrame
function NPW:HookWorldFrame()
    if self.worldFrameHooked then
        return
    end

    -- 使用HookScript安全地添加处理
    local success = pcall(function()
        WorldFrame:HookScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                self:OnWorldFrameMouseDown()
            end
        end)
    end)

    if success then
        self.worldFrameHooked = true
        self:Debug("WorldFrame hooked successfully")
    else
        self:Debug("Failed to hook WorldFrame")
    end
end

-- WorldFrame鼠标按下处理
function NPW:OnWorldFrameMouseDown()
    -- 检查是否按住 Alt 键
    if not IsAltKeyDown() then
        return
    end

    -- 检查当前是否有目标
    if not UnitExists("target") then
        return
    end

    -- 获取目标名称和GUID（GUID是最可靠的标识）
    local targetName = UnitName("target")
    local targetGUID = UnitGUID("target")
    if not targetName or not targetGUID then
        -- 目标存在但无法获取信息，延迟处理
        C_Timer.After(0.05, function()
            self:OnWorldFrameMouseDownDelayed()
        end)
        return
    end

    -- 获取鼠标位置
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    -- 显示轮盘（传递GUID作为主要标识）
    self:ShowWheel(x, y, targetGUID)
end

-- 延迟处理的 Alt+点击
function NPW:OnWorldFrameMouseDownDelayed()
    -- 再次检查
    if not IsAltKeyDown() then
        return
    end

    if not UnitExists("target") then
        return
    end

    local targetName = UnitName("target")
    local targetGUID = UnitGUID("target")

    print("|cff00ffff[NPW]|r *** ALT+CLICK (delayed) on: " .. (targetName or "unknown") .. " ***)")

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    -- 使用 GUID 作为标识
    self:ShowWheel(x, y, targetGUID)
end
