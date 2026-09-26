LobbyNui, LobbyEvents = {}, {}
clientTemp = clientTemp or {}
soundChannelSettings = soundChannelSettings or { ui = 100, notify = 100, machine = 100 }

local function lobbyOwner()
    return CoopDataClient and CoopDataClient.roomSetting and CoopDataClient.roomSetting.owneridentifier
end

function LobbyNui.closeNUI()
    SetNuiFocus(false, false)
    TriggerServerEvent(_event('server:forceCloseNUI'))
    if openUI and lobbyOwner() then
        TriggerServerEvent(_event('server:closeNUI'), lobbyOwner())
    end
    if openUI or cam then
        ExitCamera()
        openUI = false
    end
end

function LobbyNui.releaseMenu()
    SetNuiFocus(false, false)
    if openUI or cam then
        ExitCamera()
        openUI = false
    end
end

function LobbyNui.closeTutoNUI()
    SetNuiFocus(false, false)
end

function LobbyNui.invitePlayer(data)
    TriggerServerEvent(_event('server:invitePlayer'), data)
end

function LobbyNui.kickPlayer(data)
    TriggerServerEvent(_event('server:kickPlayer'), data)
end

function LobbyNui.leaveLobby(data)
    TriggerServerEvent(_event('server:leavePlayer'), lobbyOwner() or data)
end

function LobbyNui.acceptInvite(data)
    if not openUI then SetNuiFocus(false, false) end
    activeInvite = nil
    TriggerServerEvent(_event('server:acceptInvite'), data)
end

function LobbyNui.declineInvite()
    if not openUI then SetNuiFocus(false, false) end
    activeInvite = nil
    NuiMessage('CLOSE_INVITE_MENU')
    TriggerServerEvent(_event('server:declineInvite'))
end

function LobbyNui.updateSoundSetting(data)
    if data and data.key then
        soundChannelSettings[data.key] = (data.enabled == false) and 0 or (tonumber(data.volume) or 100)
    end
end

function LobbyNui.selectRegion(data)
    TriggerServerEvent(_event('server:selectRegion'), data)
end

function LobbyNui.resetJob()
    if jobStartBusy or not lobbyOwner() then return end
    TriggerServerEvent(_event('server:resetJobButton'), lobbyOwner())
end

function LobbyNui.updateRewardSplit(data)
    TriggerServerEvent(_event('server:updateRewardSplit'), data)
end

function LobbyNui.leaveOtherJob()
    if TriggerServerCallback(_event('server:leaveOtherJob')) then
        clientTemp = TriggerServerCallback(_event('server:CreatePlayerLobby')) or {}
        NuiMessage('LOAD_LOBBY', clientTemp)
    else
        NuiMessage('CLOSENUI')
    end
end

function LobbyNui.saveSettings(data)
    TriggerServerEvent(_event('server:saveUISettings'), data)
end

for name in pairs(LobbyNui) do
    RegisterNUICallback(name, function(data, cb)
        LobbyNui[name](data)
        cb('ok')
    end)
end

function LobbyEvents.RefreshLobby(lobbyData)
    local playerData = TriggerServerCallback(_event('server:getPlayerData'))
    CoopDataClient = lobbyData
    clientTemp = CoopDataClient.players
    if playerData then
        if not openUI and CreateCamera then CreateCamera() end
        SetNuiFocus(true, true)
        NuiMessage('OPEN_MENU', playerData)
        NuiMessage('LOAD_LOBBY', CoopDataClient.players)
        NuiMessage('REFRESH_LOBBY', CoopDataClient.roomSetting.Mission)
        openUI = true
    end
end

function LobbyEvents.RefreshPlayers(lobbyData)
    CoopDataClient = lobbyData
    clientTemp = CoopDataClient.players
    NuiMessage('LOAD_LOBBY', CoopDataClient.players)
    NuiMessage('REFRESH_LOBBY', CoopDataClient.roomSetting.Mission)
end

function LobbyEvents.UpdateLobby(lobbyData)
    CoopDataClient = lobbyData
    clientTemp = CoopDataClient.players
    NuiMessage('LOAD_LOBBY', CoopDataClient.players)
end

function LobbyEvents.TakeLooby()
    NuiMessage('CLOSENUI')
    SetNuiFocus(false, false)
    CoopDataClient, joobTaskClient, clientTemp = {}, {}, {}
end

function LobbyEvents.ClearCoopData()
    NuiMessage('RESET_JOB')
    SetNuiFocus(false, false)
    CoopDataClient, joobTaskClient, clientTemp = {}, {}, {}
    if cam then ExitCamera() end
    openUI = false
end

function LobbyEvents.RefreshJob(jobTask)
    joobTaskClient = jobTask
    NuiMessage('REFRESH_JOBTASK', joobTaskClient)
    PushJobProgress()
end

function LobbyEvents.saveUISettings()
    local playerData = TriggerServerCallback(_event('server:getPlayerData'))
    if playerData then
        Config.Locale = playerData.locale or Config.Locale
        NuiMessage('UPDATE_LOCALES', Locales[Config.Locale])
        Config.OpenTrigger(false)
        Wait(600)
        Config.OpenTrigger(true)
    end
end

function LobbyEvents.updateJobStatus(statusType, statusValue)
    if CoopDataClient and CoopDataClient.roomSetting then
        CoopDataClient.roomSetting[statusType] = statusValue
    end
end

function LobbyEvents.updateVehiclePlate(plates)
    if not plates then return end
    CoopDataClient.roomSetting.Mission.regionJobVehiclePlate = plates
end

for name in pairs(LobbyEvents) do
    RegisterNetEvent(_event('client:' .. name), function(...)
        LobbyEvents[name](...)
    end)
end

function updateJobStatus(statusType, statusValue)
    if CoopDataClient and CoopDataClient.roomSetting then
        TriggerServerEvent(_event('server:updateJobStatus'), CoopDataClient.roomSetting.owneridentifier, statusType,
            statusValue)
    end
end

function getStartJob()
    return CoopDataClient and CoopDataClient.roomSetting and true
end

local jobProgressVersion = 0

function PushJobProgress()
    local rows = joobTaskClient and joobTaskClient.regionJobTask
    if not rows or #rows == 0 then
        NuiMessage('HIDE_PROGRESS')
        return
    end

    local done, total, currentLabel = 0, 0, nil
    for _, task in ipairs(rows) do
        local count, made = 0, 0
        if type(task.jobCount) == 'table' then
            for color, need in pairs(task.jobCount) do
                count = count + (tonumber(need) or 0)
                made = made + math.min(tonumber((task.madeAmount or {})[color]) or 0, tonumber(need) or 0)
            end
        else
            count = tonumber(task.jobCount) or 0
            made = tonumber(task.madeAmount) or 0
        end
        local step = task.madeCountFinish or count < 0
        if step then count = 1 end
        if made > count then made = count end
        done = done + made
        total = total + count
        if not currentLabel and (step and made < 1 or not step and not task.finish) then
            currentLabel = task.jobLabel
        end
    end

    if total <= 0 then
        NuiMessage('HIDE_PROGRESS')
        return
    end

    jobProgressVersion = jobProgressVersion + 1
    NuiMessage('UPDATE_PROGRESS', {
        label     = currentLabel,
        completed = done,
        required  = total,
        overall   = math.floor((done / total) * 100 + 0.5),
        version   = jobProgressVersion,
    })
end

local keyCheckActive = false
keyGivenVehicles = {}

function ensureVehicleKeysGiven()
    if keyCheckActive then return end
    keyCheckActive = true

    CreateThread(function()
        local attempts, allGiven = 0, false
        while getStartJob() do
            Wait(attempts < 20 and 1000 or 5000)
            local netIds = CoopDataClient and CoopDataClient.roomSetting and CoopDataClient.roomSetting.VehicleNetId
            if not netIds then break end

            allGiven = true
            for _, netId in ipairs(netIds) do
                if not keyGivenVehicles[netId] then
                    local vehicle = NetworkDoesNetworkIdExist(netId) and NetToVeh(netId)
                    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                        local plate, model
                        if JobVehicleKey then plate, model = JobVehicleKey(netId, vehicle) end
                        Config.GiveVehicleKey(plate or GetVehicleNumberPlateText(vehicle),
                            model or GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), vehicle)
                        keyGivenVehicles[netId] = true
                    else
                        allGiven = false
                    end
                end
            end

            attempts = attempts + 1
            if allGiven then break end
        end
        keyCheckActive = false
        if Config.Debug and not allGiven then
            print(('^3[%s]^7 vehicle keys: not every lobby vehicle reached this client'):format(GetCurrentResourceName()))
        end
    end)
end

function resetVehicleKeyCheck()
    keyCheckActive = false
    keyGivenVehicles = {}
end
