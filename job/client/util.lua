isInteracting = isInteracting or false
showBar = showBar or false

AddEventHandler('tw-lib:client:playerLoaded', function()
    Wait(1000)
    TriggerServerEvent(_event(base.loadDataEvent or 'server:loadData'))
    SetPlayerJob()
end)

CreateThread(function()
    if Config.UI and Config.UI.primary then exports['tw-lib']:SetPromptColor(Config.UI.primary) end
    if exports['tw-lib']:IsPlayerLoaded() then
        TriggerServerEvent(_event(base.loadDataEvent or 'server:loadData'))
        SetPlayerJob()
    end
end)

AddEventHandler('tw-lib:client:jobUpdated', function()
    Wait(1000)
    SetPlayerJob()
end)

function WaitPlayer()
    local tries = 0
    while not exports['tw-lib']:IsPlayerLoaded() and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
end

local wornOutfit
local OUTFIT_COMPONENTS, OUTFIT_PROPS = { 1, 3, 4, 6, 7, 8, 9, 10, 11 }, { 0, 1, 6, 7 }

local function currentOutfit(ped)
    local outfit = { model = GetEntityModel(ped), components = {}, props = {} }
    for _, id in ipairs(OUTFIT_COMPONENTS) do
        outfit.components[id] = { GetPedDrawableVariation(ped, id), GetPedTextureVariation(ped, id), GetPedPaletteVariation(ped, id) }
    end
    for _, id in ipairs(OUTFIT_PROPS) do
        outfit.props[id] = { GetPedPropIndex(ped, id), GetPedPropTextureIndex(ped, id) }
    end
    return outfit
end

function GiveJobClothing()
    if Config.ChangeClothesSystem then
        local gender
        if GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") then
            gender = 'male'
        elseif GetEntityModel(PlayerPedId()) == GetHashKey("mp_f_freemode_01") then
            gender = 'female'
        else
            return
        end

        wornOutfit = wornOutfit or currentOutfit(PlayerPedId())
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent("esx_skin:setLastSkin", skin)
        end)

        local clothes = Config.JobClothes[gender]
        if clothes then
            for _, cloth in ipairs(clothes) do
                for part, id in pairs(cloth) do
                    if part ~= "texture" then
                        ChangeClothes(part, id, cloth.texture)
                    end
                end
            end
        end
    end
end

function ChangeClothes(key, value, texture)
    local playerPed = PlayerPedId()
    value = tonumber(value)
    texture = tonumber(texture)

    if key == 'jacket' then
        SetPedComponentVariation(playerPed, 11, value, texture, 2)
    end
    if key == 'shirt' then
        SetPedComponentVariation(playerPed, 8, value, texture, 2)
    end
    if key == 'arms' then
        SetPedComponentVariation(playerPed, 3, value, texture, 2)
    end
    if key == 'legs' then
        SetPedComponentVariation(playerPed, 4, value, texture, 2)
    end
    if key == 'shoes' then
        SetPedComponentVariation(playerPed, 6, value, texture, 2)
    end
    if key == 'mask' then
        SetPedComponentVariation(playerPed, 1, value, texture, 2)
    end
    if key == 'chain' then
        SetPedComponentVariation(playerPed, 7, value, texture, 2)
    end
    if key == 'decals' then
        SetPedComponentVariation(playerPed, 10, value, texture, 2)
    end
    if key == 'helmet' then
        SetPedPropIndex(playerPed, 0, value, texture, 2)
    end
    if key == 'glasses' then
        SetPedPropIndex(playerPed, 1, value, texture, 2)
    end
    if key == 'watches' then
        SetPedPropIndex(playerPed, 6, value, texture, 2)
    end
    if key == 'bracelets' then
        SetPedPropIndex(playerPed, 7, value, texture, 2)
    end
    if key == 'armor' then
        SetPedComponentVariation(playerPed, 9, value, texture, 2)
    end
end

function RefreshSkin()
    Config.RefreshSkin()
    local ped, outfit = PlayerPedId(), wornOutfit
    wornOutfit = nil
    if not outfit or GetEntityModel(ped) ~= outfit.model then return end
    for id, c in pairs(outfit.components) do SetPedComponentVariation(ped, id, c[1], c[2], c[3]) end
    for id, p in pairs(outfit.props) do
        if p[1] < 0 then ClearPedProp(ped, id) else SetPedPropIndex(ped, id, p[1], p[2], true) end
    end
end

function GetVehicles()
    return GetGamePool('CVehicle')
end

function GetVehiclesInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(GetVehicles(), false, coords, maxDistance)
end

function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = PlayerPedId()
        coords = GetEntityCoords(playerPed)
    end
    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end
    return nearbyEntities
end

function v2(coords) return vec3(coords.x, coords.y, 0.0) end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function WaitForModel(model)
    if not IsModelValid(model) then
        return
    end

    if not HasModelLoaded(model) then
        RequestModel(model)
    end

    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

function LoadAnimation(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

function LoadParticleLib(dict)
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Citizen.Wait(0)
        end
    end
    UseParticleFxAssetNextCall(dict)
end

function PlayEffect(dict, particleName, entity, off, rot, time, cb)
    CreateThread(function()
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(0)
        end
        UseParticleFxAssetNextCall(dict)
        Wait(10)
        local particleHandle = StartParticleFxLoopedOnEntity(particleName, entity, off.x, off.y, off.z, rot.x, rot.y,
            rot.z, 1.0)
        SetParticleFxLoopedColour(particleHandle, 0, 255, 0, 0)
        Wait(time)
        StopParticleFxLooped(particleHandle, false)
        cb()
    end)
end

function CreateProp(modelHash, ...)
    local timeout = 3000
    local waited = 0
    while not IsModelInCdimage(modelHash) do
        Wait(100)
        waited = waited + 100
        if waited >= timeout then
            print(('[%s] Model not in cdimage after %dms: %s'):format(GetCurrentResourceName(), timeout, tostring(modelHash)))
            return
        end
    end
    RequestModel(modelHash)
    waited = 0
    while not HasModelLoaded(modelHash) do
        Wait(0)
        waited = waited + 1
        if waited >= 5000 then
            print(('[%s] Model load timeout: %s'):format(GetCurrentResourceName(), tostring(modelHash)))
            return
        end
    end
    local obj = CreateObject(modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return obj
end

function awaitNetEntity(netId, ms)
    local deadline = GetGameTimer() + (ms or 5000)
    repeat
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity ~= 0 and DoesEntityExist(entity) then return entity end
        Wait(100)
    until GetGameTimer() > deadline
    return 0
end

function waitForClient(cb, errMessage, timeout)
    local value = cb()
    if value ~= nil then return value end

    if timeout or timeout == nil then
        if type(timeout) ~= 'number' then timeout = 1000 end
    end

    local startTime = timeout and GetGameTimer()

    while value == nil do
        Wait(0)

        if timeout then
            local elapsed = GetGameTimer() - startTime
            if elapsed > timeout then
                return error(('%s (waited %.1fms)'):format(errMessage or 'failed to resolve callback', elapsed), 2)
            end
        end

        value = cb()
    end

    return value
end

function StartInteraction()
    isInteracting = true
end

function EndInteraction()
    isInteracting = false
end

function FormatInteractionText(text)
    local color = Config.InteractionKeyColor or ""
    if color ~= "" then
        text = text:gsub("%[E%]", color .. "[E]~w~")
        text = text:gsub("%[G%]", color .. "[G]~w~")
    end
    return text
end

function showProgressBar(title, time)
    if showBar then return end
    showBar = true
    NuiMessage('showProgressBar', { label = title, time = time })
    Citizen.SetTimeout(time * 1000, function()
        showBar = false
    end)
end

function CreateFinishCamera()
    local invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
    if invehicle then return end
    local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), -0.3, -2.0, 0.0)

    RenderScriptCams(true, true, 500, true, true)
    DestroyCam(cam, false)
    if (not DoesCamExist(cam)) then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 500, true, true)
        SetCamCoord(cam, coords.x, coords.y, coords.z + 0.2)
        SetCamRot(cam, 5.0, 0.0, GetEntityHeading(PlayerPedId()))
        SetCamNearClip(cam, 0.1)
        SetCamFarClip(cam, 1000.0)
        SetCamFov(cam, 40.0)
        SetCamDofFnumberOfLens(cam, 24.0)
        SetCamDofFocalLengthMultiplier(cam, 50.0)
        local heading = GetEntityHeading(PlayerPedId())
        SetEntityHeading(PlayerPedId(), heading + 180.0)
    end
end

function ExitCamera()
    SetEntityAlpha(PlayerPedId(), 255, false)
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(cam, false)
    ClearFocus()
    cam = nil
end
