--[[
    Temporary Stat Library by Kerkel
    Version 1.0
]]

---@param GetData fun(entity: Entity): TempStatEntry[] Returns a persistent player-specific table used only for temporary stat data
return function (GetData)
    local VERSION = 1

    if TempStatLib then
        if TempStatLib.Internal.VERSION > VERSION then
            return
        end
        TempStatLib.Internal:RemoveCallbacks()
    end

    TempStatLib = RegisterMod("Temporary Stat Library", 1)
    TempStatLib.Internal = {}
    TempStatLib.Internal.VERSION = VERSION
    TempStatLib.Internal.CallbackEntries = {}
    TempStatLib.Internal.DEFAULT_FREQUENCY = 10

    local game = Game()
    ---@param ID ModCallbacks
    ---@param fn function
    ---@param filter any
    ---@param priority? CallbackPriority
    function TempStatLib.Internal:AddCallback(ID, fn, filter, priority)
        TempStatLib.Internal.CallbackEntries[#TempStatLib.Internal.CallbackEntries + 1] = {
            ID = ID,
            Fn = fn,
            Filter = filter,
            Priority = priority
        }
    end

    function TempStatLib.Internal:RemoveCallbacks()
        for _, v in ipairs(TempStatLib.Internal.CallbackEntries) do
            TempStatLib:RemoveCallback(v.ID, v.Fn)
        end
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
                data[i].ApplyFrame = game:GetFrameCount()
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
            ApplyFrame = game:GetFrameCount(),
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

    ---@param player EntityPlayer
    TempStatLib.Internal:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
        local data = TempStatLib:GetData(player)
        local eval, frame

        for i = #data, 1, -1 do
            local v = data[i]

            if not v.Persistent and player.FrameCount == 0 then
                table.remove(data, i)
                player:AddCacheFlags(v.Stat)
                eval = true
            else
                frame = frame or game:GetFrameCount() + 1

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
    end)

    ---@param player EntityPlayer
    ---@param flag CacheFlag
    TempStatLib.Internal:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
        local data = TempStatLib:GetData(player)

        if #data > 0 then
            for _, v in ipairs(data) do
                if v.Stat == CacheFlag.CACHE_DAMAGE and flag == CacheFlag.CACHE_DAMAGE then
                    player.Damage = player.Damage + v.Amount
                elseif v.Stat == CacheFlag.CACHE_FIREDELAY and flag == CacheFlag.CACHE_FIREDELAY then
                    player.MaxFireDelay = 30 / (30 / (player.MaxFireDelay + 1) + v.Amount) - 1
                elseif v.Stat == CacheFlag.CACHE_SHOTSPEED and flag == CacheFlag.CACHE_SHOTSPEED then
                    player.ShotSpeed = player.ShotSpeed + v.Amount
                elseif v.Stat == CacheFlag.CACHE_RANGE and flag == CacheFlag.CACHE_RANGE then
                    player.TearRange = player.TearRange + v.Amount * 40
                elseif v.Stat == CacheFlag.CACHE_SPEED and flag == CacheFlag.CACHE_SPEED then
                    player.MoveSpeed = player.MoveSpeed + v.Amount
                elseif v.Stat == CacheFlag.CACHE_LUCK and flag == CacheFlag.CACHE_LUCK then
                    player.Luck = player.Luck + v.Amount
                end
            end
        end
    end)

    for _, v in ipairs(TempStatLib.Internal.CallbackEntries) do
        if v.Priority then
            TempStatLib:AddPriorityCallback(v.ID, v.Priority, v.Fn, v.Filter)
        else
            TempStatLib:AddCallback(v.ID, v.Fn, v.FIlter)
        end
    end
end
