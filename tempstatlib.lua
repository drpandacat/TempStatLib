

--[[
    Temporary Stat Library by Kerkel
    Version 1.1
]]

---@param GetData fun(entity: Entity): TempStatEntry[] Returns a persistent player-specific table used only for temporary stat data
return function (GetData)
    local VERSION = 2

    if TempStatLib then
        if TempStatLib.Internal.VERSION > VERSION then return end
        for _, v in ipairs(TempStatLib.Internal.CallbackEntries) do
            TempStatLib:RemoveCallback(v[1], v[3])
        end
    end

    TempStatLib = RegisterMod("Temporary Stat Library", 1)
    TempStatLib.Internal = {}
    TempStatLib.Internal.VERSION = VERSION
    TempStatLib.Internal.Game = Game()
    TempStatLib.Internal.DEFAULT_FREQUENCY = 10
    TempStatLib.Internal.CallbackEntries = {
        {
            ModCallbacks.MC_POST_PEFFECT_UPDATE,
            CallbackPriority.DEFAULT,
            ---@param player EntityPlayer
            function (_, player)
                local data = TempStatLib:GetData(player)
                local eval, frame

                for i = #data, 1, -1 do
                    local v = data[i]

                    if not v.Persistent and player.FrameCount == 0 then
                        table.remove(data, i)
                        player:AddCacheFlags(v.Stat)
                        eval = true
                    else
                        frame = frame or TempStatLib.Internal.Game:GetFrameCount() + 1

                        if (frame - v.ApplyFrame) % v.Frequency == 0 then
                            local increase = v.Amount > 0

                            v.Amount = v.Amount - v.ChangeAmount

                            if (increase and v.Amount <= 0) or (not increase and v.Amount >= 0) then
                                table.remove(data, i)
                            end

                            player:AddCacheFlags(v.Stat)

                            eval = true
                        end
                    end
                end

                if eval then
                    player:EvaluateItems()
                end
            end
        },
    }

    if REPENTOGON then
        TempStatLib.Internal.CallbackEntries[#TempStatLib.Internal.CallbackEntries + 1] = {
            ModCallbacks.MC_EVALUATE_CACHE,
            CallbackPriority.EARLY,
            ---@param player EntityPlayer
            ---@param flag CacheFlag
            function (_, player, flag)
                if flag == CacheFlag.CACHE_SHOTSPEED then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_SHOTSPEED then
                            player.ShotSpeed = player.ShotSpeed + v.Amount
                        end
                    end
                elseif flag == CacheFlag.CACHE_RANGE then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_RANGE then
                            player.TearRange = player.TearRange + v.Amount * 40
                        end
                    end
                elseif flag == CacheFlag.CACHE_SPEED then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_SPEED then
                            player.MoveSpeed = player.MoveSpeed + v.Amount
                        end
                    end
                elseif flag == CacheFlag.CACHE_LUCK then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_LUCK then
                            player.Luck = player.Luck + v.Amount
                        end
                    end
                end
            end
        }
        TempStatLib.Internal.CallbackEntries[#TempStatLib.Internal.CallbackEntries + 1] = {
            ModCallbacks.MC_EVALUATE_STAT,
            CallbackPriority.DEFAULT,
            ---@param player EntityPlayer
            ---@param stage EvaluateStatStage
            ---@param value number
            function (_, player, stage, value)
                if stage == EvaluateStatStage.FLAT_TEARS then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_FIREDELAY then
                            value = value + v.Amount
                        end
                    end
                    return value
                elseif stage == EvaluateStatStage.DAMAGE_UP then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_DAMAGE then
                            value = value + v.Amount
                        end
                    end
                    return value
                end
            end
        }
    else
        TempStatLib.Internal.CallbackEntries[#TempStatLib.Internal.CallbackEntries + 1] = {
            ModCallbacks.MC_EVALUATE_CACHE,
            CallbackPriority.EARLY,
            ---@param player EntityPlayer
            ---@param flag CacheFlag
            function (_, player, flag)
                if flag == CacheFlag.CACHE_DAMAGE then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_DAMAGE then
                            player.Damage = player.Damage + v.Amount
                        end
                    end
                elseif flag == CacheFlag.CACHE_FIREDELAY then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_FIREDELAY then
                            player.MaxFireDelay = 30 / (30 / (player.MaxFireDelay + 1) + v.Amount) - 1
                        end
                    end
                elseif flag == CacheFlag.CACHE_SHOTSPEED then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_SHOTSPEED then
                            player.ShotSpeed = player.ShotSpeed + v.Amount
                        end
                    end
                elseif flag == CacheFlag.CACHE_RANGE then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_RANGE then
                            player.TearRange = player.TearRange + v.Amount * 40
                        end
                    end
                elseif flag == CacheFlag.CACHE_SPEED then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_SPEED then
                            player.MoveSpeed = player.MoveSpeed + v.Amount
                        end
                    end
                elseif flag == CacheFlag.CACHE_LUCK then
                    local data = TempStatLib:GetData(player)
                    for _, v in ipairs(data) do
                        if v.Stat == CacheFlag.CACHE_LUCK then
                            player.Luck = player.Luck + v.Amount
                        end
                    end
                end
            end
        }
    end

    for _, v in ipairs(TempStatLib.Internal.CallbackEntries) do
        TempStatLib:AddPriorityCallback(v[1], v[2], v[3], v[4])
    end

    ---@param entity Entity
    function TempStatLib:GetData(entity)
        return GetData(entity)
    end

    ---@class TempStatConfig
    ---@field Stat CacheFlag
    ---@field Duration integer
    ---@field Amount number
    ---@field Persistent? boolean
    ---@field Frequency? integer
    ---@field Identifier string

    ---@class TempStatEntry
    ---@field Persistent boolean
    ---@field Frequency integer
    ---@field Amount number
    ---@field ChangeAmount number
    ---@field Stat CacheFlag
    ---@field ApplyFrame integer
    ---@field Identifier string

    ---@param player EntityPlayer
    ---@param config TempStatConfig
    function TempStatLib:AddTempStat(player, config)
        local data = TempStatLib:GetData(player)

        for i, v in ipairs(data) do
            if v.Identifier == config.Identifier then
                data[i].Amount = config.Amount + v.Amount
                data[i].ApplyFrame = TempStatLib.Internal.Game:GetFrameCount()
                player:AddCacheFlags(config.Stat)
                player:EvaluateItems()
                return data[i]
            end
        end

        config.Frequency = config.Frequency or TempStatLib.Internal.DEFAULT_FREQUENCY

        ---@type TempStatEntry
        local entry = {
            Persistent = config.Persistent,
            Frequency = config.Frequency,
            Amount = config.Amount,
            ChangeAmount = config.Amount / config.Duration * config.Frequency,
            Stat = config.Stat,
            ApplyFrame = TempStatLib.Internal.Game:GetFrameCount(),
            Identifier = config.Identifier,
        }

        data[#data + 1] = entry

        player:AddCacheFlags(config.Stat)
        player:EvaluateItems()

        return entry
    end

    ---@param player EntityPlayer
    ---@param identifier string
    ---@return TempStatEntry?
    function TempStatLib:GetTempStat(player, identifier)
        local data = TempStatLib:GetData(player)

        for i, v in ipairs(data) do
            if v.Identifier == identifier then
                return data[i]
            end
        end
    end
end
