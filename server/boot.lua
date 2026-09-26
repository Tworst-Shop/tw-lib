local Store, Detect, Version, Merge = TwLib.Store, TwLib.Detect, TwLib.Version, TwLib.Merge
local LIB = GetCurrentResourceName()
local LIB_VERSION = GetResourceMetadata(LIB, 'version', 0) or '0.0.0'
local READY_TIMEOUT_MS = 10000
local held = {}
local tried, importDisabled, capturing = {}, false, {}
local loaded, degraded = false, false
local following = {}

local RESUME_KEY = 'twlib:resume'
local RESUME_MAX_AGE = 60
local RESUME_TOGETHER = 2
local stoppedAt = {}

local warned = {}
local function call(module, method, ...)
    local fn = TwLib[module] and TwLib[module][method]
    if not fn then
        local key = module .. '.' .. method
        if not warned[key] then
            warned[key] = true
            print(('^1[tw-lib]^7 %s is missing: check that server/%s.lua loaded.'):format(key, module:lower()))
        end
        return nil
    end
    local ok, result = pcall(fn, ...)
    if not ok then
        print(('^1[tw-lib]^7 %s failed: %s'):format(module .. '.' .. method, tostring(result)))
        return nil
    end
    return result
end

local function isTwJob(res)
    return res ~= LIB and GetResourceMetadata(res, 'tw_lib', 0) ~= nil
end

local function rowsFor(res, forClient)
    local out = {}
    for _, row in ipairs(Store.overrides(res)) do
        local root = row.path[1]
        if root ~= '_meta' and not (forClient and root == 'Server') then out[#out + 1] = row end
    end
    return out
end

local function publish(res, fileOnly)
    if not fileOnly then
        GlobalState['twlib:' .. res] = rowsFor(res, true)
        GlobalState['twlib:manual'] = Store.overrides(LIB)
    end
    if loaded then call('ConfigFile', 'sync', res, rowsFor(res, false)) end
end
TwLib.Publish = publish

function TwLib.JobResources()
    local out = {}
    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and res ~= LIB and GetResourceState(res) == 'started' and GetResourceMetadata(res, 'tw_lib', 0) ~= nil then
            out[#out + 1] = res
        end
    end
    table.sort(out)
    return out
end

local function otherJob(src, caller)
    for _, res in ipairs(TwLib.JobResources()) do
        if res ~= caller then
            local ok, name = pcall(function() return exports[res]:TwLibInLobby(src) end)
            if ok and name then return res, name end
        end
    end
end

exports('OtherJob', function(src)
    local _, name = otherJob(src, GetInvokingResource())
    return name
end)

exports('LeaveOtherJob', function(src)
    local res = otherJob(src, GetInvokingResource())
    if not res then return true end
    local ok, done = pcall(function() return exports[res]:TwLibLeaveLobby(src) end)
    return ok and done == true
end)

local function releaseHeld()
    local list = held
    held = {}
    for _, res in ipairs(list) do StartResource(res) end
end

local function statusLine()
    local parts = {}
    for _, kind in ipairs({ 'framework', 'inventory', 'keys', 'fuel', 'clothing' }) do
        parts[#parts + 1] = kind .. '=' .. tostring((Detect.get(kind)))
    end
    print(('^2[tw-lib]^7 %s | %s'):format(LIB_VERSION, table.concat(parts, ' | ')))
end

local function needsImport(res)
    return not importDisabled and not tried[res] and call('Import', 'needs', res) == true
end

TwLib.Manual = function(kind)
    return Store.get(LIB, { 'bridge', kind })
end

local function saveEdits(res, edits)
    local ok, err = pcall(function()
        local keys = {}
        for _, e in ipairs(edits) do
            if e.value == nil then Store.remove(res, e.path) else Store.set(res, e.path, e.value) end
            keys[#keys + 1] = Merge.pathKey(e.path)
        end
        print(('^2[tw-lib]^7 %s: kept your config file edits: %s'):format(res, table.concat(keys, ', ')))
    end)
    if not ok then print(('^1[tw-lib]^7 %s: config file edits not saved: %s'):format(res, tostring(err))) end
end

local function captureEdits(res)
    if importDisabled then return end
    local edits = call('Import', 'edits', res) or {}
    if #edits > 0 then saveEdits(res, edits) end
end
TwLib.CaptureEdits = captureEdits

AddEventHandler('onResourceStarting', function(res)
    if not isTwJob(res) then return end
    local need = GetResourceMetadata(res, 'tw_lib_min', 0)
    if need and not Version.atLeast(LIB_VERSION, need) then
        print(('^1[tw-lib]^7 %s needs tw-lib %s or newer, installed %s. Download the latest tw-lib: https://github.com/Tworst-Shop/tw-lib/releases/latest'):format(res, need, LIB_VERSION))
        CancelEvent()
        return
    end
    if not Store.ready then
        held[#held + 1] = res
        CancelEvent()
        return
    end
    if needsImport(res) then
        tried[res] = true
        CancelEvent()
        CreateThread(function()
            call('Import', 'run', res)
            StartResource(res)
        end)
        return
    end
    local edits = not importDisabled and not capturing[res] and call('Import', 'edits', res) or {}
    capturing[res] = nil
    if #edits > 0 then
        capturing[res] = true
        CancelEvent()
        CreateThread(function()
            saveEdits(res, edits)
            StartResource(res)
        end)
        return
    end
    local plan = loaded and not following[res] and call('Import', 'follow', res)
    following[res] = nil
    if plan then
        following[res] = true
        CancelEvent()
        CreateThread(function()
            call('Import', 'applyFollow', res, plan)
            StartResource(res)
        end)
        return
    end
    publish(res)
end)

local early = {}

local function restartEarly()
    local list = early
    early = {}
    for _, res in ipairs(list) do
        print(('^3[tw-lib]^7 %s started before tw-lib loaded saved settings (ensure order). Restarting it once.'):format(res))
        StopResource(res)
        StartResource(res)
    end
end

AddEventHandler('onResourceStart', function(res)
    Detect.invalidate(res)
    call('Server', 'reset')
    if not Store.ready and isTwJob(res) then early[#early + 1] = res end
end)

AddEventHandler('onResourceStop', function(res)
    Detect.invalidate(res)
    call('Server', 'reset')
    if isTwJob(res) then
        stoppedAt[res] = os.time()
        return
    end
    if res ~= LIB then return end
    local now, list = os.time(), {}
    for job, at in pairs(stoppedAt) do
        if now - at <= RESUME_TOGETHER then list[#list + 1] = job end
    end
    if #list > 0 then SetResourceKvp(RESUME_KEY, json.encode({ at = now, jobs = list })) end
end)

local function resumeStoppedJobs()
    local raw = GetResourceKvpString(RESUME_KEY)
    if not raw then return end
    DeleteResourceKvp(RESUME_KEY)
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' or type(data.jobs) ~= 'table' then return end
    if os.time() - (tonumber(data.at) or 0) > RESUME_MAX_AGE then return end
    for _, res in ipairs(data.jobs) do
        if GetResourceState(res) == 'stopped' then
            print(('^3[tw-lib]^7 starting %s again: it was stopped because tw-lib restarted'):format(res))
            StartResource(res)
        end
    end
end

exports('GetOverrides', function(res)
    if not Store.ready then return nil end
    return rowsFor(res, false)
end)

print('^2[tw-lib]^7 server loaded')

CreateThread(function()
    local ok, err = pcall(Store.load)
    loaded = ok
    if ok and degraded then
        importDisabled = false
        for _, res in ipairs(TwLib.JobResources()) do publish(res) end
    end
    if not ok then
        print(('^1[tw-lib]^7 settings could not be loaded (%s). Jobs run with defaults; saved settings are not lost. Fix the database and restart.'):format(tostring(err)))
        Store.ready = true
        importDisabled = true
    end
    Detect.clear()
    call('Schema', 'ensure')
    GlobalState['twlib:manual'] = Store.overrides(LIB)
    releaseHeld()
    restartEarly()
    resumeStoppedJobs()
    statusLine()
end)

SetTimeout(READY_TIMEOUT_MS, function()
    if Store.ready then return end
    print('^1[tw-lib]^7 database did not answer in 10s. Starting tw jobs with the values in their config files; restart them once the database is up.')
    Store.ready = true
    degraded = true
    importDisabled = true
    releaseHeld()
end)

local function dotPath(s)
    local path = {}
    for part in s:gmatch('[^%.]+') do path[#path + 1] = tonumber(part) or part end
    return path
end

for name, back in pairs({ twdrop = false, twback = true }) do
    RegisterCommand(name, function(src, args)
        if not call('Admin', 'isAllowed', src) then return end
        local target = tonumber(args[1]) or (src ~= 0 and src or nil)
        if not target then return print(('[tw-lib] %s <serverId>'):format(name)) end
        TriggerEvent('twlib:simulateDrop', target, back)
    end, false)
end

RegisterCommand('twlib', function(src, args)
    if src ~= 0 then return end
    local sub, res, pathArg = args[1], args[2], args[3]
    if sub == 'set' and res and pathArg and args[4] then
        local raw = table.concat(args, ' ', 4)
        local ok, value = pcall(json.decode, raw)
        if not ok or value == nil then value = raw end
        local path = dotPath(pathArg)
        if path[1] == 'Config' then
            local defaults = call('Import', 'loadDefaults', res)
            if type(defaults) == 'table' and type(defaults.Config) == 'table' then
                local reason = Merge.set(Merge.copy({ Config = defaults.Config }), path, Merge.decode(value))
                if reason then return print(('[tw-lib] %s %s not saved: %s'):format(res, pathArg, reason)) end
            end
        end
        captureEdits(res)
        Store.set(res, dotPath(pathArg), Merge.decode(value))
        publish(res, true)
        print(('[tw-lib] %s %s = %s  (restart %s to apply)'):format(res, pathArg, raw, res))
        return
    end
    if sub == 'unset' and res and pathArg then
        captureEdits(res)
        Store.remove(res, dotPath(pathArg))
        publish(res, true)
        print(('[tw-lib] %s %s back to default  (restart %s to apply)'):format(res, pathArg, res))
        return
    end
    if sub == 'stats' then
        local today, week = call('Stats', 'overview', 'today'), call('Stats', 'overview', '7d')
        if not (today and week and today.kpi and week.kpi) then return print('[tw-lib] no economy data yet') end
        print(('[tw-lib] money paid  today %s | 7 days %s'):format(today.kpi.money.value, week.kpi.money.value))
        print(('[tw-lib] jobs done   today %s | 7 days %s'):format(today.kpi.sessions.value, week.kpi.sessions.value))
        return
    end
    statusLine()
    for name, list in pairs(Store.rows) do
        print(('  %s: %d saved settings'):format(name, #list))
    end
end, true)
