-- Events.lua
-- 事件处理和双击检测模块 - 使用WorldFrame钩子方式

local _, NPW = ...

-- 初始化事件监听
function NPW:InitEvents()

    -- 钩住WorldFrame的鼠标事件（游戏世界点击）
    self:HookWorldFrame()

    -- 也钩住目标改变事件（用于重置点击状态）
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    self.eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            -- 目标改变时：如果当前没有目标，则重置点击状态
            -- 注意：我们不立即重置，让点击检测逻辑处理不同目标的情况
            if not UnitExists("target") then
                self:ResetClickState()
            end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            -- 检查是否移除了当前目标
            local removedGUID = unit and UnitGUID(unit)
            if removedGUID and removedGUID == self.state.lastClickGUID then
                self:ResetClickState()
            end
        end
    end)

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
    end
end

-- WorldFrame鼠标按下处理
function NPW:OnWorldFrameMouseDown()
    -- 检查当前是否有目标
    if not UnitExists("target") then
        self:ResetClickState()
        return
    end

    -- 获取目标GUID（GUID是最可靠的标识）
    local targetGUID = UnitGUID("target")
    if not targetGUID then
        -- 目标存在但无法获取信息，延迟处理
        C_Timer.After(0.05, function()
            self:OnWorldFrameMouseDownDelayed()
        end)
        return
    end

    -- 处理点击检测
    self:ProcessClick(targetGUID)
end

-- 处理点击检测（统一逻辑）
function NPW:ProcessClick(targetGUID)
    local currentTime = GetTime() * 1000 -- 转换为毫秒
    local isAltClick = IsAltKeyDown()

    -- 先记录当前状态用于检测
    local lastGUID = self.state.lastClickGUID
    local lastTime = self.state.lastClickTime

    -- 更新点击状态（无论是否触发都要更新）
    self.state.lastClickTime = currentTime
    self.state.lastClickGUID = targetGUID

    -- 检查是否触发轮盘
    local shouldShowWheel = false
    local triggerMethod = nil

    -- 检测1：Alt+点击（优先）
    if isAltClick then
        shouldShowWheel = true
        triggerMethod = "Alt+Click"
    -- 检测2：双击（同一目标，时间间隔内）
    elseif lastGUID == targetGUID then
        local timeDiff = currentTime - lastTime
        if timeDiff <= self.constants.DOUBLE_CLICK_THRESHOLD then
            shouldShowWheel = true
            triggerMethod = "Double click"
        else
        end
    else
        -- 不同目标，视为该目标的第一次点击
    end

    -- 不触发则直接返回
    if not shouldShowWheel then
        return
    end


    -- 获取鼠标位置
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    -- 显示轮盘
    self:ShowWheel(x, y, targetGUID)
end

-- 重置点击状态
function NPW:ResetClickState()
    self.state.lastClickTime = 0
    self.state.lastClickGUID = nil
end

-- 延迟处理的双击/Alt+点击
function NPW:OnWorldFrameMouseDownDelayed()
    if not UnitExists("target") then
        self:ResetClickState()
        return
    end

    local targetGUID = UnitGUID("target")
    if not targetGUID then
        return
    end

    -- 使用统一的点击处理逻辑
    self:ProcessClick(targetGUID)
end
