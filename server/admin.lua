TwLib = TwLib or {}
local Admin = {}
TwLib.Admin = Admin

local ACE = 'tw-lib.admin'
local QB_PERMISSIONS = { 'qbcore.god', 'qbcore.admin', 'god', 'admin' }

function Admin.isAllowed(src)
    src = tonumber(src)
    if src == 0 then return true end
    if not src then return false end
    if IsPlayerAceAllowed(src, ACE) then return true end

    local framework = TwLib.Detect.get('framework')
    if framework == 'qb' or framework == 'qbx' then
        for _, permission in ipairs(QB_PERMISSIONS) do
            if IsPlayerAceAllowed(src, permission) then return true end
        end
    end

    print(('^3[tw-lib]^7 %s asked for the economy menu without permission (needs the %s ace).'):format(
        tostring(GetPlayerName and GetPlayerName(src) or src), ACE))
    return false
end

exports('IsAdmin', function(src) return Admin.isAllowed(src) end)

local RANGES = { today = true, ['7d'] = true, ['30d'] = true, all = true }

local function localeCode()
    local store = TwLib.Store
    local code = store and store.get and store.get('tw-lib', { 'locale' })
    if type(code) == 'string' and TwLib.Locales and TwLib.Locales[code] then return code end
    return 'en'
end

local function text(key, vars)
    local strings = TwLib.Locales and TwLib.Locales[localeCode()]
    local value = strings and strings.toast and strings.toast[key]
    if type(value) ~= 'string' then
        strings = TwLib.Locales and TwLib.Locales.en
        value = strings and strings.toast and strings.toast[key] or key
    end
    for k, v in pairs(vars or {}) do value = value:gsub('{' .. k .. '}', tostring(v)) end
    return value
end

local LIB = 'tw-lib'

local function isJob(res)
    for _, name in ipairs(TwLib.JobResources and TwLib.JobResources() or {}) do
        if name == res then return true end
    end
    return false
end

local function onlineIdentifiers()
    local out = {}
    local bridge = TwLib.Server
    if not (bridge and bridge.GetIdentifier and GetPlayers) then return out end
    for _, id in ipairs(GetPlayers()) do
        local ok, identifier = pcall(bridge.GetIdentifier, tonumber(id))
        if ok and identifier then out[tostring(identifier)] = tonumber(id) end
    end
    return out
end

local function merge(into, from)
    for k, v in pairs(from or {}) do into[k] = v end
    return into
end

local function answer(request)
    request = request or {}
    local tab = request.tab or 'overview'
    local range = RANGES[request.range] and request.range or '7d'
    local code = localeCode()
    local jobs = TwLib.JobResources and TwLib.JobResources() or {}
    local live = TwLib.Stats.lobbies()
    local data = {
        tab = tab, range = range, locale = code, jobs = jobs, currency = '$', liveCount = #live.lobbies,
        i18n = TwLib.Locales and TwLib.Locales[code] or nil,
        version = GetCurrentResourceName and GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or nil,
    }

    if tab == 'overview' then
        merge(data, TwLib.Stats.overview(range, request.fresh == true))
        local players = 0
        for _, l in ipairs(live.lobbies) do players = players + (l.players or 0) end
        data.working = { players = players, lobbies = #live.lobbies }
        data.live = { table.unpack(live.lobbies, 1, math.min(5, #live.lobbies)) }
    elseif tab == 'jobs' then
        data.list = TwLib.Stats.jobs(range, jobs)
        for _, entry in ipairs(data.list) do
            entry.live = 0
            for _, l in ipairs(live.lobbies) do
                if l.job == entry.job then entry.live = entry.live + 1 end
            end
        end
    elseif tab == 'job' then
        merge(data, TwLib.Stats.job(tostring(request.resource or ''), range))
    elseif tab == 'live' then
        data.lobbies, data.quiet = live.lobbies, live.quiet
    elseif tab == 'players' then
        merge(data, TwLib.Stats.players(range, type(request.search) == 'string' and request.search or ''))
        local online = onlineIdentifiers()
        for _, p in ipairs(data.list or {}) do p.online = online[p.identifier] ~= nil end
    elseif tab == 'player' then
        merge(data, TwLib.Stats.player(tostring(request.identifier or ''), range))
        data.online = onlineIdentifiers()[tostring(request.identifier or '')] ~= nil
    elseif tab == 'ledger' then
        merge(data, TwLib.Stats.ledger(request))
    elseif tab == 'economy' then
        local res = request.resource
        data.resource = (type(res) == 'string' and res ~= '' and res) or jobs[1]
        data.settings = data.resource and Admin.settings(data.resource) or {}
        data.lobbies = 0
        for _, l in ipairs(live.lobbies) do
            if l.job == data.resource or data.resource == LIB then data.lobbies = data.lobbies + 1 end
        end
        local perHour = {}
        for _, r in ipairs(data.resource and TwLib.Stats.regions(data.resource, '7d') or {}) do perHour[r.region] = r.perHour end
        data.regionStats = {}
        for _, field in ipairs(data.settings) do
            if field.groupKey == 'regionData' and perHour[field.entryName] then
                data.regionStats[tostring(field.groupIndex)] = perHour[field.entryName]
            end
        end
    end
    return data
end

RegisterNetEvent('tw-lib:server:menu', function(request)
    local src = source
    if not Admin.isAllowed(src) then return end
    TriggerClientEvent('tw-lib:client:menu', src, answer(request))
end)

local EDITABLE = {
    jobCoolDownHours     = 1,
    MaxPlayersInLobby    = 2,
    jobLevelCheck        = 3,
    regionMinimumLevel   = 4,
    money                = 5,
    xp                   = 6,
    onlineJobExtraAwards = 7,
    bonusExtraMoney      = 8,
    bonusExtraXP         = 9,
    extraMoneyperClothes = 10,
    LetOwnerSplitRewards = 12,
}

local RANGE = {
    MaxPlayersInLobby = { 1, 4, true },
    regionMinimumLevel = { 0, math.huge, true },
    onlineJobExtraAwards = { -math.huge, math.huge },
}

local CHOICES = {
    InteractionHandler = { order = 11, options = { 'default', 'drawtext', 'ox-target', 'qb-target', 'auto' } },
}

local LIB_SETTINGS = {
    interaction = { options = { 'drawtext', 'ox-target', 'qb-target', 'auto' }, default = 'drawtext' },
    reconnect = { options = { '0', '60', '180', '300', '600' }, default = '180' },
}
local LIB_ORDER = { 'interaction', 'reconnect' }

local function listed(options, value)
    for _, option in ipairs(options) do
        if option == value then return true end
    end
    return false
end

local SKIP_LISTS = { dailyMission = true, itemList = true, TutorialList = true }

local function entryName(entry, index)
    local info = type(entry) == 'table' and entry.regionInfo
    local name = (type(info) == 'table' and info.regionName)
        or entry.header or entry.label or entry.name
    if type(name) == 'string' and name ~= '' then return name end
    return '#' .. tostring(index)
end

local function isListOfTables(value)
    return TwLib.Merge.isList(value) and type(value[1]) == 'table'
end

local function splitPath(text)
    local path = {}
    for part in tostring(text):gmatch('[^%.]+') do path[#path + 1] = tonumber(part) or part end
    return path
end

local function valueAt(root, path)
    local node = root
    for _, part in ipairs(path) do
        if type(node) ~= 'table' then return nil end
        node = node[part]
    end
    return node
end

local function collect(node, path, out, saved, group)
    for key, value in pairs(node) do
        local kind = TwLib.Merge.typeOf(value)
        local here = { table.unpack(path) }
        here[#here + 1] = key

        if kind == 'table' then
            if SKIP_LISTS[key] then
            elseif isListOfTables(value) then
                for index, entry in ipairs(value) do
                    local entryPath = { table.unpack(here) }
                    entryPath[#entryPath + 1] = index
                    collect(entry, entryPath, out, saved,
                        { key = tostring(key), index = index, name = entryName(entry, index) })
                end
            else
                collect(value, here, out, saved, group)
            end
        elseif ((kind == 'number' or kind == 'boolean') and EDITABLE[key]) or (kind == 'string' and CHOICES[key] and not group) then
            local pathKey = TwLib.Merge.pathKey(here)
            out[#out + 1] = {
                path = pathKey,
                key = tostring(key),
                group = group and group.name or '',
                groupKey = group and group.key or nil,
                groupIndex = group and group.index or 0,
                entryName = group and group.name or nil,
                order = EDITABLE[key] or CHOICES[key].order,
                value = value,
                type = kind == 'string' and 'choice' or kind,
                options = kind == 'string' and CHOICES[key].options or nil,
                changed = saved[pathKey] ~= nil,
            }
        end
    end
end

local function libSettings()
    local out = {}
    for i, path in ipairs(LIB_ORDER) do
        local s = LIB_SETTINGS[path]
        local saved = TwLib.Store.get(LIB, { path })
        out[#out + 1] = { path = path, key = path, group = '', groupIndex = 0, order = i, type = 'choice',
            options = s.options, default = s.default, value = saved or s.default, changed = saved ~= nil }
    end
    return out
end

function Admin.settings(res)
    if res == LIB then return libSettings() end
    local defaults = TwLib.Import and TwLib.Import.loadDefaults and TwLib.Import.loadDefaults(res)
    if not defaults or type(defaults.Config) ~= 'table' then return {} end

    local rows = (TwLib.Store and TwLib.Store.overrides and TwLib.Store.overrides(res)) or {}
    local saved = {}
    for _, row in ipairs(rows) do saved[TwLib.Merge.pathKey(row.path)] = row.value end

    local merged = TwLib.Merge.apply({ Config = defaults.Config }, rows)
    local out = {}
    collect(merged.Config, { 'Config' }, out, saved, nil)
    for _, field in ipairs(out) do
        field.default = valueAt({ Config = defaults.Config }, splitPath(field.path))
        if field.options and not listed(field.options, field.default) then
            field.options = { field.default, table.unpack(field.options) }
        end
    end

    local seen = {}
    for _, field in ipairs(out) do
        if field.groupKey then
            local names = seen[field.groupKey] or {}
            seen[field.groupKey] = names
            names[field.group] = names[field.group] or {}
            names[field.group][field.groupIndex] = true
        end
    end
    for _, field in ipairs(out) do
        if field.groupKey then
            local indexes = seen[field.groupKey][field.group]
            local count = 0
            for _ in pairs(indexes) do count = count + 1 end
            if count > 1 then field.group = field.group .. ' #' .. tostring(field.groupIndex) end
        end
    end
    table.sort(out, function(a, b)
        local ak, bk = a.groupKey or '', b.groupKey or ''
        if ak ~= bk then return ak < bk end
        if a.groupIndex ~= b.groupIndex then return a.groupIndex < b.groupIndex end
        if a.order ~= b.order then return a.order < b.order end
        return a.path < b.path
    end)
    return out
end

function Admin.saveSetting(res, pathText, value)
    if res == LIB then
        local s = LIB_SETTINGS[pathText]
        if not s then return 'not-editable' end
        if not listed(s.options, value) then return 'choice' end
        TwLib.Store.set(LIB, { pathText }, value)
        return nil
    end
    local defaults = TwLib.Import and TwLib.Import.loadDefaults and TwLib.Import.loadDefaults(res)
    if not defaults or type(defaults.Config) ~= 'table' then return 'missing' end

    local path = splitPath(pathText)
    if path[1] ~= 'Config' then return 'missing' end
    local key = path[#path]
    if not EDITABLE[key] and not (CHOICES[key] and #path == 2) then return 'not-editable' end
    if CHOICES[key] and not listed(CHOICES[key].options, value) and value ~= valueAt(defaults, path) then return 'choice' end
    local range = RANGE[key] or { 0, math.huge }
    if type(value) == 'number' and (value ~= value or value < range[1] or value > range[2] or (range[3] and value % 1 ~= 0)) then
        return 'range'
    end

    local probe = TwLib.Merge.copy({ Config = defaults.Config })
    local reason = TwLib.Merge.set(probe, path, value)
    if reason then return reason end

    TwLib.Store.set(res, path, value)
    return nil
end

RegisterNetEvent('tw-lib:server:setting', function(request)
    local src = source
    if not Admin.isAllowed(src) then return end
    request = type(request) == 'table' and request or {}
    local res = request.resource
    local saved, errors = 0, {}
    if type(res) == 'string' and TwLib.CaptureEdits then TwLib.CaptureEdits(res) end

    for _, change in ipairs(type(request.changes) == 'table' and request.changes or {}) do
        local reason = Admin.saveSetting(res, change.path, change.value)
        if reason then
            local path = splitPath(change.path)
            errors[#errors + 1] = { path = tostring(change.path), key = tostring(path[#path]), reason = reason }
        else
            saved = saved + 1
            print(('^2[tw-lib]^7 settings: %s set %s %s = %s'):format(GetPlayerName(src) or src, res, change.path, tostring(change.value)))
        end
    end
    for _, pathText in ipairs(type(request.resets) == 'table' and request.resets or {}) do
        local path = splitPath(pathText)
        if res == LIB and LIB_SETTINGS[pathText] then
            TwLib.Store.remove(LIB, path)
            saved = saved + 1
            print(('^2[tw-lib]^7 settings: %s reset %s for every job'):format(GetPlayerName(src) or src, pathText))
        elseif path[1] == 'Config' and (EDITABLE[path[#path]] or (CHOICES[path[#path]] and #path == 2)) then
            TwLib.Store.remove(res, path)
            saved = saved + 1
            print(('^2[tw-lib]^7 settings: %s reset %s %s to the default'):format(GetPlayerName(src) or src, res, pathText))
        end
    end

    if saved > 0 and TwLib.Publish then TwLib.Publish(res, true) end
    local data = answer({ tab = 'economy', resource = res })
    local liveOnly = res == LIB
    for _, change in ipairs(type(request.changes) == 'table' and request.changes or {}) do
        if change.path ~= 'reconnect' then liveOnly = false end
    end
    for _, pathText in ipairs(type(request.resets) == 'table' and request.resets or {}) do
        if pathText ~= 'reconnect' then liveOnly = false end
    end
    data.saved, data.errors, data.restartNeeded = saved, errors, saved > 0 and not liveOnly
    TriggerClientEvent('tw-lib:client:menu', src, data)
end)

local function findLobby(res, id)
    for _, l in ipairs(TwLib.Stats.lobbies().lobbies) do
        if l.job == res and tostring(l.id) == tostring(id) then return l end
    end
end

local ACTIONS = {
    restart = function(src, res)
        local list = res == LIB and (TwLib.JobResources and TwLib.JobResources() or {}) or { res }
        CreateThread(function()
            for _, name in ipairs(list) do StopResource(name) end
            Wait(500)
            for _, name in ipairs(list) do StartResource(name) end
        end)
        return 'live', text('restarted', { job = res })
    end,

    teleport = function(src, res, request)
        local lobby = findLobby(res, request.lobby)
        if not lobby then return 'live', text('failed'), true end
        local target
        for _, m in ipairs(lobby.members) do
            if m.source and (not target or (lobby.owner and m.identifier == lobby.owner.identifier)) then target = m.source end
        end
        local ped = target and GetPlayerPed(target)
        if not ped or ped == 0 then return 'live', text('failed'), true end
        local at = GetEntityCoords(ped)
        SetEntityCoords(GetPlayerPed(src), at.x + 1.0, at.y, at.z)
        return nil, text('teleported')
    end,

    endJob = function(src, res, request) return 'lobby', 'finish', 'jobEnded' end,
    closeLobby = function(src, res, request) return 'lobby', 'close', 'lobbyClosed' end,
}

RegisterNetEvent('tw-lib:server:action', function(request)
    local src = source
    if not Admin.isAllowed(src) then return end
    request = type(request) == 'table' and request or {}
    local res, run = request.resource, ACTIONS[request.action]
    if not run or type(res) ~= 'string' or not (isJob(res) or (res == LIB and request.action == 'restart')) then return end

    local tab, message, failed = run(src, res, request)
    if tab == 'lobby' then
        local action, done = message, failed
        local ok, result = pcall(function() return exports[res]:TwLibLobbyAction(request.lobby, action) end)
        tab = 'live'
        if not ok or result == nil then
            message, failed = text('unsupported'), true
        elseif result == false then
            message, failed = text('failed'), true
        else
            message, failed = text(done), false
        end
    end
    print(('^3[tw-lib]^7 menu action: %s -> %s %s %s (%s)'):format(GetPlayerName(src) or src, tostring(request.action), res,
        tostring(request.lobby or ''), failed and 'failed' or 'ok'))

    local data = answer({ tab = tab or 'live' })
    data.toast = { text = message, error = failed == true }
    TriggerClientEvent('tw-lib:client:menu', src, data)
end)
