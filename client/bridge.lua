local Detect = TwLib.Detect
local Client = { custom = {} }
TwLib.Client = Client

local function modelName(vehicle, model)
    if vehicle and DoesEntityExist(vehicle) then return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) end
    return model
end

local function serverKey(give)
    return function(plate, vehicle)
        local netId = vehicle and DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) and VehToNet(vehicle) or 0
        TriggerServerEvent('tw-lib:server:vehicleKey', give, netId, plate, GetInvokingResource())
    end
end

local function nothing() end

local function ak47Keys(res)
    local function localOnly(vehicle) return not (vehicle and NetworkGetEntityIsNetworked(vehicle)) end
    return {
        give = function(plate, vehicle) exports[res]:GiveKey(plate, localOnly(vehicle)) end,
        remove = function(plate, vehicle) exports[res]:RemoveKey(plate, localOnly(vehicle)) end,
    }
end

local keys = {
    qbx_vehiclekeys = { give = serverKey(true), remove = serverKey(false) },
    ['qs-vehiclekeys'] = {
        give = function(plate, vehicle, model) exports['qs-vehiclekeys']:GiveKeys(plate, modelName(vehicle, model), true) end,
        remove = function(plate, vehicle, model) exports['qs-vehiclekeys']:RemoveKeys(plate, modelName(vehicle, model)) end,
    },
    wasabi_carlock = {
        give = function(plate) exports.wasabi_carlock:GiveKey(plate) end,
        remove = function(plate) exports.wasabi_carlock:RemoveKey(plate) end,
    },
    MrNewbVehicleKeys = {
        give = function(plate) exports.MrNewbVehicleKeys:GiveKeysByPlate(plate) end,
        remove = function(plate) exports.MrNewbVehicleKeys:RemoveKeysByPlate(plate) end,
    },
    jc_vehiclekeys = {
        give = function(plate) exports['jc_vehiclekeys']:GiveTempKey(plate) end,
        remove = function(plate) exports['jc_vehiclekeys']:RemoveTempKey(plate) end,
    },
    ['Renewed-Vehiclekeys'] = {
        give = function(plate) exports['Renewed-Vehiclekeys']:addKey(plate) end,
        remove = function(plate) exports['Renewed-Vehiclekeys']:removeKey(plate) end,
    },
    vehicles_keys = {
        give = function(plate) TriggerServerEvent('vehicles_keys:selfGiveVehicleKeys', plate) end,
        remove = function(plate) TriggerServerEvent('vehicles_keys:selfRemoveKeys', plate) end,
    },
    ['tgiann-hotwire'] = { give = function(plate) exports['tgiann-hotwire']:GiveKeyPlate(plate, true) end, remove = nothing },
    ['0r-vehiclekeys'] = {
        give = function(plate) exports['0r-vehiclekeys']:GiveKeys(plate) end,
        remove = function(plate) exports['0r-vehiclekeys']:RemoveKeys(plate) end,
    },
    LifeSaver_KeySystem = {
        give = function(plate, vehicle, model) exports['LifeSaver_KeySystem']:AddCarkey(plate, modelName(vehicle, model)) end,
        remove = function(plate, vehicle, model) exports['LifeSaver_KeySystem']:RemoveCarkey(plate, modelName(vehicle, model)) end,
    },
    ak47_qb_vehiclekeys = ak47Keys('ak47_qb_vehiclekeys'),
    ak47_vehiclekeys = ak47Keys('ak47_vehiclekeys'),
    filo_vehiclekey = {
        give = function(plate) exports.filo_vehiclekey:GiveKeys(plate) end,
        remove = function(plate) exports.filo_vehiclekey:RemoveKeys(plate) end,
    },
    ic3d_vehiclekeys = {
        give = function(plate) exports.ic3d_vehiclekeys:ClientInventoryKeys('add', plate) end,
        remove = function(plate) exports.ic3d_vehiclekeys:ClientInventoryKeys('remove', plate) end,
    },
    is_vehiclekeys = {
        give = function(plate) exports['is_vehiclekeys']:GiveKey(plate) end,
        remove = function(plate) exports['is_vehiclekeys']:RemoveKey(plate) end,
    },
    mk_vehiclekeys = {
        give = function(_, vehicle) exports['mk_vehiclekeys']:AddKey(vehicle) end,
        remove = function(_, vehicle) exports['mk_vehiclekeys']:RemoveKey(vehicle) end,
    },
    mm_carkeys = {
        give = function(plate, vehicle) exports.mm_carkeys:GiveKeyItem(plate, vehicle) end,
        remove = function(plate) exports.mm_carkeys:RemoveKeyItem(plate) end,
    },
    p_carkeys = {
        give = function(plate) TriggerServerEvent('p_carkeys:CreateKeys', plate) end,
        remove = function(plate) TriggerServerEvent('p_carkeys:RemoveKeys', plate) end,
    },
    rd_vehiclekeys = {
        give = function(plate) TriggerServerEvent('rd_vehiclekeys:server:GiveKeys', plate) end,
        remove = function(plate) TriggerServerEvent('rd_vehiclekeys:server:RemoveKeys', plate) end,
    },
    t1ger_keys = {
        give = function(plate, vehicle, model) exports['t1ger_keys']:GiveJobKeys(plate, modelName(vehicle, model), true) end,
        remove = nothing,
    },
    mx_carkeys = {
        give = function(plate, vehicle) exports['mx_carkeys']:createTempKey(vehicle, plate, 2) end,
        remove = function(_, vehicle) exports['mx_carkeys']:removeVehicleKey(vehicle) end,
    },
    ['qb-vehiclekeys'] = { give = serverKey(true), remove = serverKey(false) },
    okokGarage = {
        give = function(plate) TriggerServerEvent('okokGarage:GiveKeys', plate) end,
        remove = function(plate) TriggerServerEvent('okokGarage:RemoveKeys', plate, GetPlayerServerId(PlayerId())) end,
    },
    mVehicle = { give = function(_, vehicle) exports.mVehicle:AddTemporalVehicleClient(vehicle) end, remove = nothing },
    cd_garage = {
        give = function(_, vehicle) TriggerEvent('cd_garage:AddKeys', exports['cd_garage']:GetPlate(vehicle)) end,
        remove = function(_, vehicle) TriggerServerEvent('cd_garage:RemovePersistentVehicles', exports['cd_garage']:GetPlate(vehicle)) end,
    },
    tmc = { give = serverKey(true), remove = function() end },
}

local function setFuel(res)
    return function(vehicle, level) exports[res]:SetFuel(vehicle, level) end
end

local fuel = {
    LegacyFuel = setFuel('LegacyFuel'),
    ['x-fuel'] = setFuel('x-fuel'),
    ['cdn-fuel'] = setFuel('cdn-fuel'),
    ['ps-fuel'] = setFuel('ps-fuel'),
    lc_fuel = setFuel('lc_fuel'),
    ['qb-fuel'] = setFuel('qb-fuel'),
    ['Renewed-Fuel'] = setFuel('Renewed-Fuel'),
    myFuel = setFuel('myFuel'),
    okokGasStation = setFuel('okokGasStation'),
    ['qs-fuelstations'] = setFuel('qs-fuelstations'),
    ['BigDaddy-Fuel'] = setFuel('BigDaddy-Fuel'),
    ['esx-sna-fuel'] = setFuel('esx-sna-fuel'),
    ['lj-fuel'] = setFuel('lj-fuel'),
    hyon_gas_station = setFuel('hyon_gas_station'),
    nd_fuel = setFuel('nd_fuel'),
    rcore_fuel = function(vehicle, level) exports.rcore_fuel:SetVehicleFuel(vehicle, level) end,
    ti_fuel = function(vehicle, level)
        local _, kind = exports['ti_fuel']:getFuel(vehicle)
        exports['ti_fuel']:setFuel(vehicle, level, kind)
    end,
    ox_fuel = function(vehicle, level)
        SetVehicleFuelLevel(vehicle, level)
        Entity(vehicle).state:set('fuel', level, true)
    end,
    native = function(vehicle, level) SetVehicleFuelLevel(vehicle, level) end,
}

local clothing = {
    ['illenium-appearance'] = function() TriggerEvent('illenium-appearance:client:reloadSkin') end,
    ['fivem-appearance'] = function()
        if GetResourceState('es_extended') ~= 'started' then return end
        exports['es_extended']:getSharedObject().TriggerServerCallback('esx_skin:getPlayerSkin', function(appearance)
            exports['fivem-appearance']:setPlayerAppearance(appearance)
        end)
    end,
    esx_skin = function()
        TriggerEvent('esx_skin:getLastSkin', function(lastSkin) TriggerEvent('skinchanger:loadSkin', lastSkin) end)
    end,
    rcore_clothing = function() TriggerServerEvent('rcore_clothing:reloadSkin') end,
    ['qb-clothing'] = function()
        TriggerEvent('qb-clothing:reloadSkin')
        ExecuteCommand('refreshskin')
    end,
}

local function safe(kind, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then print(('^1[tw-lib]^7 %s script call failed: %s'):format(kind, tostring(err))) end
end

local function keyAdapter()
    local id, from = Detect.get('keys')
    if from == 'manual' and id == 'none' then return nil end
    if id == 'custom' then return Client.custom.keys.impl end
    if keys[id] then return keys[id] end
    local fw = Detect.get('framework')
    if fw == 'qb' or fw == 'qbx' then return keys['qb-vehiclekeys'] end
    if fw == 'tmc' then return keys.tmc end
    return nil
end

function Client.GiveVehicleKey(plate, model, vehicle)
    local adapter = keyAdapter()
    if adapter then safe('keys', adapter.give, plate, vehicle, model) end
end

function Client.RemoveVehicleKey(plate, model, vehicle)
    local adapter = keyAdapter()
    if adapter then safe('keys', adapter.remove, plate, vehicle, model) end
end

function Client.SetVehicleFuel(vehicle, level)
    level = tonumber(level) or 100.0
    local id = Detect.get('fuel')
    local fn = id == 'custom' and Client.custom.fuel.impl.set or fuel[id] or fuel.native
    safe('fuel', fn, vehicle, level)
end

function Client.RefreshSkin()
    local id = Detect.get('clothing')
    local fn = id == 'custom' and Client.custom.clothing.impl.refresh or clothing[id]
    if fn then safe('clothing', fn) end
end

local clientCores = {}
local coreGetters = {
    qb = function() return exports['qb-core']:GetCoreObject() end,
    qbx = function() return exports['qb-core']:GetCoreObject() end,
    esx = function() return exports['es_extended']:getSharedObject() end,
    tmc = function() return exports.core:getCoreObject() end,
}
local function clientCore(id)
    if clientCores[id] == nil then
        local get = coreGetters[id]
        local ok, obj = pcall(function() return get and get() end)
        clientCores[id] = ok and obj or false
    end
    return clientCores[id] or nil
end

function Client.GetPlayerJob()
    local fw = Detect.get('framework')
    local core = clientCore(fw)
    if not core then return nil end
    if fw == 'qb' or fw == 'qbx' then
        local job = (core.Functions.GetPlayerData() or {}).job
        return job and { name = job.name, label = job.label, grade = job.grade and job.grade.level or 0 } or nil
    elseif fw == 'esx' then
        local job = (core.GetPlayerData() or {}).job
        return job and { name = job.name, label = job.label, grade = tonumber(job.grade) or 0 } or nil
    elseif fw == 'tmc' then
        local job, grade = core.Functions.IsOnDuty()
        return job and { name = job, label = job, grade = grade or 0 } or nil
    end
    return nil
end

function Client.IsPlayerLoaded()
    local fw = Detect.get('framework')
    local core = clientCore(fw)
    if fw == 'qb' or fw == 'qbx' then
        local data = core and core.Functions.GetPlayerData()
        return data ~= nil and data.metadata ~= nil
    elseif fw == 'esx' then
        local data = core and core.GetPlayerData()
        return data ~= nil and data.job ~= nil
    elseif fw == 'tmc' then
        return core ~= nil and core.Functions.IsPlayerLoaded() == true
    end
    return true
end

local function relay(families, event)
    return function()
        if families[Detect.get('framework')] then TriggerEvent(event) end
    end
end
local QB, ESX, TMC = { qb = true, qbx = true }, { esx = true }, { tmc = true }
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', relay(QB, 'tw-lib:client:playerLoaded'))
RegisterNetEvent('QBCore:Client:OnJobUpdate', relay(QB, 'tw-lib:client:jobUpdated'))
RegisterNetEvent('QBCore:Client:OnPlayerUnload', relay(QB, 'tw-lib:client:playerUnloaded'))
RegisterNetEvent('esx:playerLoaded', relay(ESX, 'tw-lib:client:playerLoaded'))
RegisterNetEvent('esx:setJob', relay(ESX, 'tw-lib:client:jobUpdated'))
RegisterNetEvent('esx:onPlayerLogout', relay(ESX, 'tw-lib:client:playerUnloaded'))
RegisterNetEvent('TMC:Client:OnPlayerLoaded', relay(TMC, 'tw-lib:client:playerLoaded'))
RegisterNetEvent('TMC:Client:OnPlayerSpawned', relay(TMC, 'tw-lib:client:playerLoaded'))
AddStateBagChangeHandler('JobTracking', nil, relay(TMC, 'tw-lib:client:jobUpdated'))

local vrpLoaded = false
for _, name in ipairs({ 'vRP:Active', 'vRP:playerSpawn', 'vRP:NUIready' }) do
    AddEventHandler(name, function()
        if vrpLoaded or Detect.get('framework') ~= 'vrp' then return end
        vrpLoaded = true
        TriggerEvent('tw-lib:client:playerLoaded')
    end)
end

CreateThread(function()
    Wait(1000)
    if Detect.get('framework') == 'standalone' then TriggerEvent('tw-lib:client:playerLoaded') end
end)

function Client.RegisterBridge(kind, impl)
    if kind ~= 'keys' and kind ~= 'fuel' and kind ~= 'clothing' then
        error('tw-lib: client RegisterBridge supports keys, fuel, clothing')
    end
    Client.custom[kind] = { impl = impl, owner = GetInvokingResource() }
    Detect.custom[kind] = true
    Detect.cache[kind] = nil
end

TwLib.Manual = function(kind)
    for _, row in ipairs(GlobalState['twlib:manual'] or {}) do
        if row.path[1] == 'bridge' and row.path[2] == kind then return row.value end
    end
    return nil
end

AddEventHandler('onClientResourceStart', function(res)
    Detect.invalidate(res)
    clientCores = {}
end)
AddEventHandler('onClientResourceStop', function(res)
    Detect.invalidate(res)
    clientCores = {}
    for kind, c in pairs(Client.custom) do
        if c.owner == res then
            Client.custom[kind], Detect.custom[kind], Detect.cache[kind] = nil, nil, nil
        end
    end
end)

for _, name in ipairs({ 'GiveVehicleKey', 'RemoveVehicleKey', 'SetVehicleFuel', 'RefreshSkin', 'GetPlayerJob', 'IsPlayerLoaded', 'RegisterBridge' }) do
    exports(name, Client[name])
end
