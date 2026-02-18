-- Utils.lua
-- 工具函数和常量定义

local _, NPW = ...

-- 团队标记常量
NPW.MARKERS = {
    { index = 1, name = "星星", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
    { index = 2, name = "大饼", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" },
    { index = 3, name = "菱形", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" },
    { index = 4, name = "三角", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" },
    { index = 5, name = "月亮", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    { index = 6, name = "方块", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
    { index = 7, name = "叉叉", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    { index = 8, name = "骷髅", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
}

-- 计算轮盘位置（极坐标转直角坐标）
-- index: 1-8，从顶部开始顺时针
-- centerX, centerY: 中心点坐标
-- radius: 半径
function NPW:CalculateWheelPosition(index, centerX, centerY, radius)
    -- 从12点钟方向开始，顺时针排列
    -- 索引1(星星)在顶部(270度)，然后顺时针
    local angle = math.rad(270 + (index - 1) * 45)

    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)

    return x, y
end

-- 计算角度（从中心点到鼠标位置）
function NPW:CalculateAngle(centerX, centerY, mouseX, mouseY)
    local dx = mouseX - centerX
    local dy = mouseY - centerY
    local angle = math.deg(math.atan2(dy, dx))
    if angle < 0 then angle = angle + 360 end
    return angle
end

-- 根据角度获取最近的标记
function NPW:GetMarkerByAngle(angle)
    -- 8个标记均匀分布在360度上，每个标记占45度
    local sectorSize = 360 / 8
    -- 调整角度，使每个扇区的中心对应一个标记
    local adjustedAngle = (angle - 270 + sectorSize / 2) % 360
    local index = math.floor(adjustedAngle / sectorSize) + 1
    if index > 8 then index = 8 end
    if index < 1 then index = 1 end
    return self.MARKERS[index], index
end

-- 调试打印
function NPW:Debug(msg, ...)
    if self.db and self.db.debug then
        print(string.format("|cff00ffff[NPW]|r %s", select("#", ...) > 0 and string.format(msg, ...) or msg))
    end
end

-- 深拷贝表
function NPW:DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[self:DeepCopy(k)] = self:DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

-- 合并表
function NPW:MergeTables(destination, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(destination[k]) == "table" then
            self:MergeTables(destination[k], v)
        else
            destination[k] = v
        end
    end
    return destination
end
