local _, NPW = ...
-- 注册斜杠命令

function NPW:RegisterSlashCommands()
    SLASH_NAMEPLATEMARKERWHEEL1 = "/npw"
    SlashCmdList["NAMEPLATEMARKERWHEEL"] = function(msg)
        local cmd = string.lower(msg or "")
        if cmd == "test" or cmd == "t" then
            -- 测试命令：在屏幕中央显示轮盘（对自己使用player的GUID）
            local playerGUID = UnitGUID("player")
            self:ShowWheel(GetScreenWidth() / 2, GetScreenHeight() / 2, playerGUID)
        
        elseif cmd == "reset" then
            -- 重置配置
            self:ResetConfig()
        elseif cmd == "tar" then
            -- 使用当前目标的GUID来测试
            if UnitExists("target") then
                local guid = UnitGUID("target")
                self:ShowWheel(GetScreenWidth() / 2, GetScreenHeight() / 2, guid)
            end
        elseif cmd == "config" or cmd == "c" then
            -- 打开配置界面（如果支持）
            if Settings and Settings.OpenToCategory then
                Settings.OpenToCategory("NamePlateMarkerWheel")
            else
                print("|cff00ffff[NPW]|r 配置界面未实现，请直接编辑 SavedVariables")
            end
        elseif cmd == "debug" or cmd == "d" then
            -- 切换调试模式
            self.db.debug = not self.db.debug
            print("|cff00ffff[NPW]|r 调试模式: " .. (self.db.debug and "开启" or "关闭"))
        elseif cmd == "status" or cmd == "s" then
            -- 显示状态
            local namePlates = C_NamePlate.GetNamePlates()
            print("|cff00ffff[NPW]|r 状态:")
            print("  姓名板总数: " .. #namePlates)
            print("  鼠标监听: " .. (self.mouseFrame and self.mouseFrame:IsShown() and "启用" or "禁用"))
            print("  调试模式: " .. (self.db.debug and "开" or "关"))
        elseif cmd == "forcereset" or cmd == "f" then
            -- 完全重置插件状态
            print("|cff00ffff[NPW]|r 完全重置插件...")
            NamePlateMarkerWheelDB = nil
            self.db = self:DeepCopy(self.defaults)
            NamePlateMarkerWheelDB = { profile = self.db }
            print("|cff00ffff[NPW]|r 重置完成，请重载界面 (/reload)")
        else
            print("|cff00ffff[NPW]|r 命令列表:")
            print("  /npw test - 测试轮盘显示")
            print("  /npw tar - 测试目标展示轮盘")
            print("  /npw reset - 重置配置")
            print("  /npw config - 打开配置")
            print("  /npw debug - 切换调试模式")
            print("  /npw status - 查看状态")
            print("  /npw forcereset - 完全重置（需重载）")
        end
    end
end