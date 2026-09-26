local RES = GetCurrentResourceName()
local Merge = TwLib.Merge
local isServer = IsDuplicityVersion()

local rows
if isServer then
    rows = exports['tw-lib']:GetOverrides(RES)
else
    rows = GlobalState['twlib:' .. RES]
end
if rows == nil then
    print(('^1[tw-lib]^7 %s: saved settings not available, running with defaults'):format(RES))
    rows = {}
end

for _, row in ipairs(rows) do
    local lang = row.path[1] == 'Locales' and #row.path == 2 and row.path[2]
    if lang and type(row.value) == 'table' and type(Locales) == 'table' and Locales[lang] == nil then
        Locales[lang] = Merge.copy(row.value)
    end
end

if type(Locales) == 'table' and type(Locales.en) == 'table' then
    for lang, texts in pairs(Locales) do
        if lang ~= 'en' and type(texts) == 'table' then
            for key, value in pairs(Locales.en) do
                if texts[key] == nil then texts[key] = value end
            end
        end
    end
end

local locale, localeRow
for i, row in ipairs(rows) do
    if Merge.pathKey(row.path) == 'Config.Locale' then locale, localeRow = row.value, i end
end
if type(locale) == 'string' and type(Config) == 'table' and locale ~= Config.Locale then
    if type(Locales) ~= 'table' or type(Locales[locale]) ~= 'table' then
        print(('^3[tw-lib]^7 %s: saved language %s has no locale file, keeping %s'):format(RES, locale, tostring(Config.Locale)))
        table.remove(rows, localeRow)
    else
        local loaded = Config
        TwLibLocale = locale
        local ok, err = pcall(function()
            for i = 0, GetNumResourceMetadata(RES, 'tw_lib_config') - 1 do
                local path = GetResourceMetadata(RES, 'tw_lib_config', i)
                local src = assert(LoadResourceFile(RES, path), 'missing file ' .. tostring(path))
                assert(load(src, ('@@%s/%s'):format(RES, path)))()
            end
        end)
        TwLibLocale = nil
        if not ok then
            Config = loaded
            print(('^1[tw-lib]^7 %s: re-running config for language %s failed, shipped texts stay: %s'):format(RES, locale, tostring(err)))
        end
    end
end

local merged, report = Merge.apply({ Config = Config, Locales = Locales, Server = Server }, rows)
Config, Locales, Server = merged.Config, merged.Locales, merged.Server
for _, d in ipairs(report.dropped) do
    print(('^3[tw-lib]^7 %s: saved setting ignored (%s): %s'):format(RES, d.reason, Merge.pathKey(d.path)))
end

local SPELLING = { ox_target = 'ox-target' }
local function libInteraction()
    local libRows = isServer and exports['tw-lib']:GetOverrides('tw-lib') or GlobalState['twlib:manual']
    for _, row in ipairs(libRows or {}) do
        if row.path[1] == 'interaction' and #row.path == 1 then return row.value end
    end
    return 'drawtext'
end
local function interaction(value)
    if value == nil or value == 'default' then value = libInteraction() end
    value = SPELLING[value] or value
    if value == 'auto' then
        value = GetResourceState('ox_target') == 'started' and 'ox-target'
            or GetResourceState('qb-target') == 'started' and 'qb-target' or 'drawtext'
    end
    return value
end
if type(Config) == 'table' then
    if Config.InteractionHandler ~= nil then Config.InteractionHandler = interaction(Config.InteractionHandler) end
    local ts = Config.TargetSystem
    if type(ts) == 'table' and (ts.resource == nil or ts.resource == 'default') then
        local own = Config.InteractionHandler
        local pick = (own == 'drawtext' or own == 'ox-target' or own == 'qb-target') and own or interaction('default')
        ts.resource = pick == 'ox-target' and 'ox_target' or pick
    end
end

local function lib(name, ...)
    local tw = exports['tw-lib']
    return tw[name](tw, ...)
end

if isServer then
    for _, name in ipairs({ 'GetPlayer', 'GetIdentifier', 'GetName', 'AddMoney', 'RemoveMoney', 'GetPlayerMoney', 'addItem', 'removeItem', 'HasItem' }) do
        _G[name] = function(...) return lib(name, ...) end
    end
else
    Config.GiveVehicleKey = function(plate, model, vehicle)
        if Config.Vehiclekey == false then return end
        return lib('GiveVehicleKey', plate, model, vehicle)
    end
    Config.RemoveVehiclekey = function(plate, model, vehicle)
        if Config.Removekeys == false then return end
        return lib('RemoveVehicleKey', plate, model, vehicle)
    end
    Config.SetVehicleFuel = function(vehicle)
        return lib('SetVehicleFuel', vehicle, 100.0)
    end
    Config.RefreshSkin = function()
        if Config.ChangeClothesSystem == false then return end
        return lib('RefreshSkin')
    end
end
