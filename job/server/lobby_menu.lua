function awardJobTask(owneridentifier, identifier, key)
    local lobby, jobTask = coopData[owneridentifier], JoobTask[owneridentifier]
    if not (lobby and jobTask and lobby.roomSetting.startJob) then return false end

    for _, task in ipairs(jobTask.regionJobTask) do
        if (task.id == key or task.jobName == key) and not task.finish then
            local need = tonumber(task.jobCount)
            task.madeAmount = task.madeAmount + 1
            if need < 0 then
                need = task.madeAmount
            elseif task.madeAmount >= need then
                task.finish = true
                task.invisible = true
                Citizen.SetTimeout(3000, function()
                    TriggerEvent(_event('server:FinishJob'), owneridentifier)
                end)
            end

            if need < task.madeAmount then
                task.madeAmount = need
            else
                for _, player in ipairs(jobTask.Players) do
                    if player.playerIdentifier == identifier then
                        player.scoreAmount = player.scoreAmount + 1
                        break
                    end
                end
            end
        end
    end

    for _, player in ipairs(lobby.players) do
        if not player.offline then TriggerClientEvent(_event('client:RefreshJob'), player.source, jobTask) end
    end
    return true
end

function completeTasks(owneridentifier, identifier, count)
    local jobTask = JoobTask[owneridentifier]
    if not jobTask then return false end
    for _, task in ipairs(jobTask.regionJobTask) do
        for _ = 1, count do
            if task.finish then break end
            awardJobTask(owneridentifier, identifier, task.id or task.jobName)
        end
    end
    return true
end

if base.fastCommand then
    local name, tag = base.fastCommand, '[' .. GetCurrentResourceName() .. ']'
    RegisterCommand(name, function(src, args)
        if not Config.Debug then
            if src == 0 then print(('%s %s needs Config.Debug = true'):format(tag, name)) end
            return
        end

        local target, count = src, tonumber(args[1]) or 500
        if src == 0 then
            target, count = tonumber(args[1]) or 0, tonumber(args[2]) or 500
            if target == 0 then return print(('%s %s <serverId> [count]'):format(tag, name)) end
        end

        local identifier = GetIdentifier(target)
        if not identifier then return end

        local owneridentifier
        for ownerId, lobby in pairs(coopData) do
            for _, player in ipairs(lobby.players or {}) do
                if player.source == target then owneridentifier = ownerId break end
            end
            if owneridentifier then break end
        end
        if not owneridentifier or not JoobTask[owneridentifier] then
            return print(('%s %s: that player is not in a started job'):format(tag, name))
        end

        completeTasks(owneridentifier, identifier, count)
        print(('%s %s: %s tasks pushed up to %d times for %s'):format(tag, name,
            #JoobTask[owneridentifier].regionJobTask, count, identifier))
    end, true)
end

exports('TwLibLobbies', function()
    local out = {}
    for ownerId, lobby in pairs(coopData) do
        local setting = lobby.roomSetting or {}
        local mission = setting.Mission or {}
        local members, owner = {}, nil
        for _, player in ipairs(lobby.players or {}) do
            local member = { identifier = tostring(player.playerIdentifier), name = player.playerName, source = not player.offline and player.source or nil }
            members[#members + 1] = member
            if player.playerOwner then owner = member end
        end
        out[#out + 1] = {
            id = ownerId,
            owner = owner and { identifier = owner.identifier, name = owner.name } or { identifier = tostring(ownerId) },
            members = members,
            max = Config.MaxPlayersInLobby,
            region = (mission.regionInfo and mission.regionInfo.regionName) or '',
            seconds = setting.startedAt and (os.time() - setting.startedAt) or 0,
            started = setting.startJob == true,
        }
    end
    return out
end)

exports('TwLibLobbyAction', function(lobbyId, action)
    local lobby = coopData[lobbyId]
    if not lobby then return false end
    if action == 'finish' then
        if not lobby.roomSetting.startJob then return false end
        local credited = lobbyId
        for _, player in ipairs(lobby.players) do
            if player.playerOwner then credited = player.playerIdentifier end
        end
        return completeTasks(lobbyId, credited, 500)
    elseif action == 'close' then
        return resetLobby(lobbyId)
    end
    return false
end)
