-- Events.lua
-- 事件处理和双击检测模块 - 使用WorldFrame钩子方式

local _, NPW = ...

-- 初始化事件监听
function NPW:InitEvents()

    -- 钩住WorldFrame的鼠标事件（游戏世界点击）
    self:HookWorldFrame()

    -- 钩住姓名板点击
    self:HookNamePlates()

    -- 也钩住目标改变事件（用于重置点击状态）
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self.eventFrame:RegisterEvent("NAME_PLATE_CREATED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- 战斗结束

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
        elseif event == "NAME_PLATE_CREATED" then
            -- 新的姓名板创建时，钩住它的点击事件
            -- 注意：NAME_PLATE_CREATED 的 unit 参数是 nameplate 框架对象
            local nameplate = unit
            if nameplate then
                local unitToken = self:GetUnitFromNamePlate(nameplate)
                if unitToken then
                    self:HookNamePlate(nameplate, unitToken)
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- 战斗结束，检查是否有待处理的队列更新
            if self.state.pendingQueueAdvance then
                self.state.pendingQueueAdvance = false
                self:AdvanceMarkQueue()
            else
                -- 没有待处理的更新，重置队列到开始
                self:ResetMarkQueue()
            end
        end
    end)

end

-- 钩住WorldFrame
function NPW:HookWorldFrame()
    if self.worldFrameHooked then
        return
    end

    -- 保存原有的 OnMouseDown 处理函数
    local originalOnMouseDown = WorldFrame:GetScript("OnMouseDown")

    -- 设置新的鼠标按下事件处理
    WorldFrame:SetScript("OnMouseDown", function(frame, button)
        -- 先调用原有的处理函数（如果有）
        if originalOnMouseDown then
            originalOnMouseDown(frame, button)
        end

        -- 然后处理我们的逻辑
        if button == "LeftButton" then
            -- 使用 pcall 防止错误中断游戏
            local success, err = pcall(function()
                self:OnWorldFrameMouseDown()
            end)
            if not success and self.db and self.db.debug then
                print("|cff00ffff[NPW]|r Error: " .. tostring(err))
            end
        end
    end)

    self.worldFrameHooked = true
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
    local shouldTrigger = false
    local triggerMethod = nil

    -- 检测1：Alt+点击（优先）
    if isAltClick then
        shouldTrigger = true
        triggerMethod = "Alt+Click"
    -- 检测2：双击（同一目标，时间间隔内）- 需要启用双击功能
    elseif self.db.behavior.enableDoubleClick and lastGUID == targetGUID then
        local timeDiff = currentTime - lastTime
        if timeDiff <= self.constants.DOUBLE_CLICK_THRESHOLD then
            shouldTrigger = true
            triggerMethod = "Double click"
        else
        end
    else
        -- 不同目标，视为该目标的第一次点击
    end

    -- 不触发则直接返回
    if not shouldTrigger then
        return
    end

    -- 检查是否在战斗中
    if InCombatLockdown() then
        -- 战斗中：SetOverrideBindingClick 已经绑定了 Alt+点击到安全按钮
        -- 直接返回，让绑定处理标记
        if self.db and self.db.debug then
            local currentMark = self.state.combatMarkQueue[self.state.combatMarkIndex]
            print("|cff00ffff[NPW]|r 战斗中 Alt+点击 -> 标记 " .. currentMark)
        end
        return
    end

    -- 非战斗：获取鼠标位置并显示轮盘
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale
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

-- 钩住所有已存在的姓名板（支持默认和 ElvUI）
function NPW:HookNamePlates()
    -- 获取所有可见的姓名板
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in ipairs(nameplates) do
        local unitToken = self:GetUnitFromNamePlate(nameplate)
        self:HookNamePlate(nameplate, unitToken)
    end

    -- 额外检查 ElvUI 姓名板
    if _G.ElvUI and _G.ElvUI[1] and _G.ElvUI[1].NamePlates then
        local ElvUI = _G.ElvUI[1]
        if ElvUI.NamePlates.displayedPlates then
            for _, plate in pairs(ElvUI.NamePlates.displayedPlates) do
                if plate and not plate.npwHooked then
                    self:HookNamePlate(plate, plate.unit)
                end
            end
        end
    end
end

-- 从姓名板获取单位 token（支持默认和 ElvUI）
function NPW:GetUnitFromNamePlate(nameplate)
    if not nameplate then return nil end

    -- 默认姓名板
    if nameplate.namePlateUnitToken then
        return nameplate.namePlateUnitToken
    end

    -- ElvUI 姓名板支持
    -- ElvUI 使用 .unit 属性或存储在 ElvUI_NamePlates 全局表中
    if nameplate.unit then
        return nameplate.unit
    end

    -- 尝试从 ElvUI 数据结构获取
    if _G.ElvUI and _G.ElvUI[1] and _G.ElvUI[1].NamePlates then
        local ElvUI = _G.ElvUI[1]
        -- ElvUI 可能使用 displayedPlates 表
        if ElvUI.NamePlates.displayedPlates then
            for _, plate in pairs(ElvUI.NamePlates.displayedPlates) do
                if plate == nameplate or (plate.GetName and plate:GetName() == nameplate:GetName()) then
                    return plate.unit or plate.namePlateUnitToken
                end
            end
        end
    end

    -- 尝试通过姓名板名称获取单位
    local name = nameplate:GetName()
    if name then
        -- 默认姓名板格式: NamePlate1, NamePlate2, etc.
        local plateIndex = name:match("NamePlate(%d+)")
        if plateIndex then
            -- 尝试获取 nameplateX token
            local token = "nameplate" .. plateIndex
            if UnitExists(token) then
                return token
            end
        end
    end

    return nil
end

-- 钩住单个姓名板
function NPW:HookNamePlate(nameplate, unit)
    if not nameplate or nameplate.npwHooked then
        return
    end

    -- 标记已钩住，避免重复
    nameplate.npwHooked = true

    -- 保存原有的 OnMouseDown 处理函数
    local originalOnMouseDown = nameplate:GetScript("OnMouseDown")

    -- 设置新的鼠标按下事件处理
    nameplate:SetScript("OnMouseDown", function(frame, button)
        -- 先调用原有的处理函数（如果有）
        if originalOnMouseDown then
            originalOnMouseDown(frame, button)
        end

        -- 然后处理我们的逻辑
        if button == "LeftButton" then
            -- 获取此姓名板对应的单位（支持默认和 ElvUI）
            local unitToken = self:GetUnitFromNamePlate(nameplate) or unit
            if unitToken and UnitExists(unitToken) then
                local guid = UnitGUID(unitToken)
                if guid then
                    -- 检查是否需要唤出轮盘
                    self:CheckNamePlateClick(guid)
                end
            end
        end
    end)
end

-- 检查姓名板点击是否应该唤出轮盘
function NPW:CheckNamePlateClick(guid)
    if not guid then return end

    -- 检查Alt+点击
    if IsAltKeyDown() then
        -- 检查是否在战斗中
        if InCombatLockdown() then
            -- 战斗中：SetOverrideBindingClick 已经绑定了 Alt+点击到安全按钮
            if self.db and self.db.debug then
                local currentMark = self.state.combatMarkQueue[self.state.combatMarkIndex]
                print("|cff00ffff[NPW]|r 战斗中 Alt+点击姓名板 -> 标记 " .. currentMark)
            end
        else
            -- 获取鼠标位置
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = x / scale
            y = y / scale
            self:ShowWheel(x, y, guid)
        end
        return
    end

    -- 检查双击
    local currentTime = GetTime() * 1000
    local lastGUID = self.state.lastClickGUID
    local lastTime = self.state.lastClickTime

    -- 更新点击状态
    self.state.lastClickTime = currentTime
    self.state.lastClickGUID = guid

    -- 同一目标，时间间隔内 -> 双击
    if lastGUID == guid then
        local timeDiff = currentTime - lastTime
        if timeDiff <= self.constants.DOUBLE_CLICK_THRESHOLD then
            -- 检查是否在战斗中
            if InCombatLockdown() then
                -- 战斗中：SetOverrideBindingClick 已经绑定了双击到安全按钮
                -- 注意：这里需要额外处理，因为双击不是直接绑定
                if self.db and self.db.debug then
                    local currentMark = self.state.combatMarkQueue[self.state.combatMarkIndex]
                    print("|cff00ffff[NPW]|r 战斗中双击姓名板 -> 标记 " .. currentMark)
                end
            else
                -- 获取鼠标位置
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                x = x / scale
                y = y / scale
                self:ShowWheel(x, y, guid)
            end
        end
    end
end
