--[[
    MODULE: ConfigManager.lua
    Mô tả: Hệ thống lưu & tải cấu hình JSON độc lập (81 loại quặng & mọi cài đặt)
]]

local HttpService = game:GetService("HttpService")

local ConfigManager = {}
local CONFIG_FILE = "SellOres_UserConfig.json"

function ConfigManager.init(deps)
    local State = deps.State
    local defaultBuy = deps.defaultBuy
    local defaultFuse = deps.defaultFuse
    local Fluent = deps.Fluent

    local refreshBuyVisuals = nil
    local refreshFuseVisuals = nil

    function ConfigManager.setVisualCallbacks(buyCb, fuseCb)
        refreshBuyVisuals = buyCb
        refreshFuseVisuals = fuseCb
    end

    function ConfigManager.save(silent)
        local configData = {
            WantedBuyOres = State.WantedBuyOres,
            AllowedFuseOres = State.AllowedFuseOres,
            Settings = {
                AutoFarmMoney = State.AutoFarmMoney,
                MoneyPipelineInterval = State.MoneyPipelineInterval,
                MoneyStepDelay = State.MoneyStepDelay,
                AutoRollBuyEnabled = State.AutoRollBuyEnabled,
                RollScanDelay = State.RollScanDelay,
                BuyAllPedestals = State.BuyAllPedestals,
                AutoReRollAfterBuy = State.AutoReRollAfterBuy,
                AutoFuserLoop = State.AutoFuserLoop,
                FuserInterval = State.FuserInterval,
                AutoApplyGems = State.AutoApplyGems,
                AutoActivateBuff = State.AutoActivateBuff,
                WalkSpeedEnabled = State.WalkSpeedEnabled,
                WalkSpeedValue = State.WalkSpeedValue,
                JumpPowerEnabled = State.JumpPowerEnabled,
                JumpPowerValue = State.JumpPowerValue,
                InfiniteJump = State.InfiniteJump,
                Noclip = State.Noclip,
                AntiAFK = State.AntiAFK
            }
        }

        local ok, encoded = pcall(function() return HttpService:JSONEncode(configData) end)
        if not ok then
            if not silent then Fluent:Notify({ Title = "Lỗi Lưu Cấu Hình", Content = "Không thể mã hóa dữ liệu!", Duration = 3 }) end
            return false
        end

        local writeOk = pcall(function()
            if writefile then
                writefile(CONFIG_FILE, encoded)
            end
        end)

        if writeOk and writefile then
            local buyCount = 0
            for _, v in pairs(State.WantedBuyOres) do if v then buyCount = buyCount + 1 end end
            local fuseCount = 0
            for _, v in pairs(State.AllowedFuseOres) do if v then fuseCount = fuseCount + 1 end end

            if not silent then
                Fluent:Notify({
                    Title = "💾 ĐÃ LƯU CẤU HÌNH THÀNH CÔNG!",
                    Content = string.format("Đã lưu %d quặng mua, %d quặng nung & toàn bộ cài đặt vào file %s!", buyCount, fuseCount, CONFIG_FILE),
                    Duration = 4
                })
            end
            return true
        else
            if not silent then
                Fluent:Notify({
                    Title = "Lưu Thất Bại",
                    Content = "Executor của bạn không hỗ trợ hàm writefile!",
                    Duration = 3
                })
            end
            return false
        end
    end

    function ConfigManager.load(silent)
        if not isfile or not readfile then
            if not silent then
                Fluent:Notify({ Title = "Lỗi Tải Cấu Hình", Content = "Executor không hỗ trợ đọc file!", Duration = 3 })
            end
            return false
        end

        if not isfile(CONFIG_FILE) then
            if not silent then
                Fluent:Notify({ Title = "Không Tìm Thấy File", Content = "Chưa có file " .. CONFIG_FILE .. " đã lưu trước đó!", Duration = 3 })
            end
            return false
        end

        local content = nil
        local readOk = pcall(function() content = readfile(CONFIG_FILE) end)
        if not readOk or not content or content == "" then
            if not silent then Fluent:Notify({ Title = "Lỗi Đọc File", Content = "Không thể đọc nội dung file config!", Duration = 3 }) end
            return false
        end

        local decodeOk, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not decodeOk or type(data) ~= "table" then
            if not silent then Fluent:Notify({ Title = "Lỗi Giải Mã", Content = "File cấu hình bị lỗi định dạng!", Duration = 3 }) end
            return false
        end

        if type(data.WantedBuyOres) == "table" then
            table.clear(State.WantedBuyOres)
            for k, v in pairs(data.WantedBuyOres) do State.WantedBuyOres[k] = v end
            if refreshBuyVisuals then refreshBuyVisuals() end
        end

        if type(data.AllowedFuseOres) == "table" then
            table.clear(State.AllowedFuseOres)
            for k, v in pairs(data.AllowedFuseOres) do State.AllowedFuseOres[k] = v end
            if refreshFuseVisuals then refreshFuseVisuals() end
        end

        if type(data.Settings) == "table" then
            local s = data.Settings
            if s.AutoFarmMoney ~= nil then State.AutoFarmMoney = s.AutoFarmMoney end
            if s.AutoMoneyPipeline ~= nil and s.AutoFarmMoney == nil then State.AutoFarmMoney = s.AutoMoneyPipeline end
            if s.MoneyPipelineInterval ~= nil then State.MoneyPipelineInterval = s.MoneyPipelineInterval end
            if s.MoneyStepDelay ~= nil then State.MoneyStepDelay = s.MoneyStepDelay end
            if s.AutoRollBuyEnabled ~= nil then State.AutoRollBuyEnabled = s.AutoRollBuyEnabled end
            if s.RollScanDelay ~= nil then State.RollScanDelay = s.RollScanDelay end
            if s.BuyAllPedestals ~= nil then State.BuyAllPedestals = s.BuyAllPedestals end
            if s.AutoReRollAfterBuy ~= nil then State.AutoReRollAfterBuy = s.AutoReRollAfterBuy end
            if s.AutoFuserLoop ~= nil then State.AutoFuserLoop = s.AutoFuserLoop end
            if s.FuserInterval ~= nil then State.FuserInterval = s.FuserInterval end
            if s.AutoApplyGems ~= nil then State.AutoApplyGems = s.AutoApplyGems end
            if s.AutoActivateBuff ~= nil then State.AutoActivateBuff = s.AutoActivateBuff end
            if s.WalkSpeedEnabled ~= nil then State.WalkSpeedEnabled = s.WalkSpeedEnabled end
            if s.WalkSpeedValue ~= nil then State.WalkSpeedValue = s.WalkSpeedValue end
            if s.JumpPowerEnabled ~= nil then State.JumpPowerEnabled = s.JumpPowerEnabled end
            if s.JumpPowerValue ~= nil then State.JumpPowerValue = s.JumpPowerValue end
            if s.InfiniteJump ~= nil then State.InfiniteJump = s.InfiniteJump end
            if s.Noclip ~= nil then State.Noclip = s.Noclip end
            if s.AntiAFK ~= nil then State.AntiAFK = s.AntiAFK end

            -- Đồng bộ UI Toggles nếu đã được tạo
            local opt = Fluent and Fluent.Options
            if opt then
                pcall(function()
                    if opt.ToggleAutoFarmMoney and s.AutoFarmMoney ~= nil then opt.ToggleAutoFarmMoney:SetValue(s.AutoFarmMoney) end
                    if opt.ToggleAutoRollBuy and s.AutoRollBuyEnabled ~= nil then opt.ToggleAutoRollBuy:SetValue(s.AutoRollBuyEnabled) end
                    if opt.ToggleAutoFuser and s.AutoFuserLoop ~= nil then opt.ToggleAutoFuser:SetValue(s.AutoFuserLoop) end
                    if opt.ToggleAutoApplyGems and s.AutoApplyGems ~= nil then opt.ToggleAutoApplyGems:SetValue(s.AutoApplyGems) end
                    if opt.ToggleAutoBuff1H and s.AutoActivateBuff ~= nil then opt.ToggleAutoBuff1H:SetValue(s.AutoActivateBuff) end
                end)
            end
        end

        local buyCount = 0
        for _, v in pairs(State.WantedBuyOres) do if v then buyCount = buyCount + 1 end end
        local fuseCount = 0
        for _, v in pairs(State.AllowedFuseOres) do if v then fuseCount = fuseCount + 1 end end

        if not silent then
            Fluent:Notify({
                Title = "📂 ĐÃ TẢI CẤU HÌNH THÀNH CÔNG!",
                Content = string.format("Đã nạp %d quặng mua, %d quặng nung & toàn bộ cài đặt!", buyCount, fuseCount),
                Duration = 4
            })
        end
        return true
    end

    function ConfigManager.reset()
        table.clear(State.WantedBuyOres)
        for _, o in ipairs(defaultBuy) do State.WantedBuyOres[o] = true end
        table.clear(State.AllowedFuseOres)
        for _, o in ipairs(defaultFuse) do State.AllowedFuseOres[o] = true end

        if refreshBuyVisuals then refreshBuyVisuals() end
        if refreshFuseVisuals then refreshFuseVisuals() end

        Fluent:Notify({
            Title = "🔄 ĐÃ ĐẶT LẠI MẶC ĐỊNH",
            Content = "Đã khôi phục danh sách quặng về mặc định chuẩn!",
            Duration = 3
        })
    end
end

return ConfigManager
