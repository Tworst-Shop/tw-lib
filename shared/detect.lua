TwLib = TwLib or {}
local D = { cache = {}, custom = {} }
TwLib.Detect = D

D.lists = {
    framework = {
        { resource = 'qbx_core', id = 'qbx' },
        { resource = 'qb-core', id = 'qb' },
        { resource = 'es_extended', id = 'esx' },
        { resource = 'core', id = 'tmc', probe = 'tmc' },
        { resource = 'vrp', id = 'vrp' },
    },
    inventory = {
        { resource = 'codem-inventoryv2', id = 'codem-inventoryv2' },
        { resource = 'origen_inventory', id = 'origen_inventory' },
        { resource = 'ox_inventory', id = 'ox_inventory' },
        { resource = 'qs-inventory-pro', id = 'qs-inventory-pro' },
        { resource = 'qs-inventory', id = 'qs_inventory' },
        { resource = 'tgiann-inventory', id = 'tgiann-inventory' },
        { resource = 'codem-inventory', id = 'codem-inventory' },
        { resource = 'ak47_qb_inventory', id = 'ak47_qb_inventory' },
        { resource = 'ak47_inventory', id = 'ak47_inventory' },
        { resource = 'core_inventory', id = 'core_inventory' },
        { resource = 'jaksam_inventory', id = 'jaksam_inventory' },
        { resource = 'one_inventory', id = 'one_inventory' },
    },
    keys = {
        { resource = 'qbx_vehiclekeys', id = 'qbx_vehiclekeys' },
        { resource = 'qs-vehiclekeys', id = 'qs-vehiclekeys' },
        { resource = 'wasabi_carlock', id = 'wasabi_carlock' },
        { resource = 'MrNewbVehicleKeys', id = 'MrNewbVehicleKeys' },
        { resource = 'jc_vehiclekeys', id = 'jc_vehiclekeys' },
        { resource = 'Renewed-Vehiclekeys', id = 'Renewed-Vehiclekeys' },
        { resource = 'vehicles_keys', id = 'vehicles_keys' },
        { resource = 'tgiann-hotwire', id = 'tgiann-hotwire' },
        { resource = '0r-vehiclekeys', id = '0r-vehiclekeys' },
        { resource = 'LifeSaver_KeySystem', id = 'LifeSaver_KeySystem' },
        { resource = 'ak47_qb_vehiclekeys', id = 'ak47_qb_vehiclekeys' },
        { resource = 'ak47_vehiclekeys', id = 'ak47_vehiclekeys' },
        { resource = 'filo_vehiclekey', id = 'filo_vehiclekey' },
        { resource = 'ic3d_vehiclekeys', id = 'ic3d_vehiclekeys' },
        { resource = 'is_vehiclekeys', id = 'is_vehiclekeys' },
        { resource = 'mk_vehiclekeys', id = 'mk_vehiclekeys' },
        { resource = 'mm_carkeys', id = 'mm_carkeys' },
        { resource = 'p_carkeys', id = 'p_carkeys' },
        { resource = 'rd_vehiclekeys', id = 'rd_vehiclekeys' },
        { resource = 't1ger_keys', id = 't1ger_keys' },
        { resource = 'mx_carkeys', id = 'mx_carkeys' },
        { resource = 'qb-vehiclekeys', id = 'qb-vehiclekeys' },
        { resource = 'cd_garage', id = 'cd_garage' },
        { resource = 'okokGarage', id = 'okokGarage' },
        { resource = 'mVehicle', id = 'mVehicle' },
    },
    fuel = {
        { resource = 'LegacyFuel', id = 'LegacyFuel' },
        { resource = 'x-fuel', id = 'x-fuel' },
        { resource = 'cdn-fuel', id = 'cdn-fuel' },
        { resource = 'ps-fuel', id = 'ps-fuel' },
        { resource = 'lc_fuel', id = 'lc_fuel' },
        { resource = 'qb-fuel', id = 'qb-fuel' },
        { resource = 'Renewed-Fuel', id = 'Renewed-Fuel' },
        { resource = 'myFuel', id = 'myFuel' },
        { resource = 'okokGasStation', id = 'okokGasStation' },
        { resource = 'qs-fuelstations', id = 'qs-fuelstations' },
        { resource = 'BigDaddy-Fuel', id = 'BigDaddy-Fuel' },
        { resource = 'esx-sna-fuel', id = 'esx-sna-fuel' },
        { resource = 'lj-fuel', id = 'lj-fuel' },
        { resource = 'hyon_gas_station', id = 'hyon_gas_station' },
        { resource = 'nd_fuel', id = 'nd_fuel' },
        { resource = 'rcore_fuel', id = 'rcore_fuel' },
        { resource = 'ti_fuel', id = 'ti_fuel' },
        { resource = 'ox_fuel', id = 'ox_fuel' },
    },
    clothing = {
        { resource = 'codem-clothing', id = 'codem-clothing' },
        { resource = 'codem-appearance', id = 'codem-appearance' },
        { resource = 'illenium-appearance', id = 'illenium-appearance' },
        { resource = 'fivem-appearance', id = 'fivem-appearance' },
        { resource = 'rcore_clothing', id = 'rcore_clothing' },
        { resource = 'qs-appearance', id = 'qs-appearance' },
        { resource = '4bit_appearance', id = '4bit_appearance' },
        { resource = 'qf_skinmenu', id = 'qf_skinmenu' },
        { resource = 'crm-appearance', id = 'crm-appearance' },
        { resource = 'tgiann-clothing', id = 'tgiann-clothing' },
        { resource = '0r-clothing', id = '0r-clothing' },
        { resource = 'qb-clothing', id = 'qb-clothing' },
        { resource = 'esx_skin', id = 'esx_skin' },
    },
}

D.fallback = { framework = 'standalone', inventory = 'framework', keys = 'none', fuel = 'native', clothing = 'none' }

D.probes = {
    tmc = function()
        local ok, obj = pcall(function() return exports.core:getCoreObject() end)
        return ok and type(obj) == 'table'
    end,
}

function D.resolve(kind, getState, manual)
    local list = D.lists[kind]
    if not list then error('tw-lib detect: unknown kind ' .. tostring(kind)) end
    if manual and manual ~= 'auto' then
        local known = manual == D.fallback[kind] or (manual == 'custom' and D.custom[kind] ~= nil)
        for _, entry in ipairs(list) do known = known or entry.id == manual end
        if known then return manual, 'manual' end
        print(('^3[tw-lib]^7 bridge.%s = %s is not a known choice, detecting instead'):format(kind, tostring(manual)))
    end
    if D.custom[kind] then return 'custom', 'custom' end
    for _, entry in ipairs(list) do
        if getState(entry.resource) == 'started' and (not entry.probe or D.probes[entry.probe]()) then
            return entry.id, entry.resource
        end
    end
    return D.fallback[kind], nil
end

function D.get(kind)
    local hit = D.cache[kind]
    if not hit then
        local manual = TwLib.Manual and TwLib.Manual(kind) or nil
        local id, from = D.resolve(kind, GetResourceState, manual)
        hit = { id = id, from = from }
        D.cache[kind] = hit
    end
    return hit.id, hit.from
end

function D.invalidate(resource)
    for kind, list in pairs(D.lists) do
        for _, entry in ipairs(list) do
            if entry.resource == resource then D.cache[kind] = nil end
        end
    end
end

function D.clear()
    D.cache = {}
end
