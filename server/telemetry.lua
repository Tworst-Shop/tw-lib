local LIB = GetCurrentResourceName()
local SEND_EVERY = 6 * 3600
local TICK = 10 * 60
local MAX_ZONES = 30
local Telemetry = { endpoint = 'https://tworst.tr/t', data = {}, tz = {}, live = {}, dirty = false }
TwLib.Telemetry = Telemetry

local function enabled()
    return TwLib.Store.get(LIB, { 'telemetry' }) ~= 'off'
end
Telemetry.enabled = enabled

local function merge(into, from)
    for res, zones in pairs(from) do
        into[res] = into[res] or {}
        for tz, paths in pairs(zones) do
            into[res][tz] = into[res][tz] or {}
            for path, n in pairs(paths) do into[res][tz][path] = (into[res][tz][path] or 0) + n end
        end
    end
end

local ok, saved = pcall(json.decode, GetResourceKvpString('telemetry:data') or '{}')
if ok and type(saved) == 'table' then merge(Telemetry.data, saved) end
local id = GetResourceKvpString('telemetry:id')
if not id then
    id = ('%08x%08x'):format(math.random(0, 0xffffffff), math.random(0, 0xffffffff))
    SetResourceKvp('telemetry:id', id)
end
local zones, zoneCount = { other = true }, 1
for _, byZone in pairs(Telemetry.data) do
    for tz in pairs(byZone) do
        if not zones[tz] then zones[tz], zoneCount = true, zoneCount + 1 end
    end
end

function Telemetry.add(res, path, n, src)
    n = tonumber(n) or 1
    if not enabled() or type(path) ~= 'string' or #path > 64 or not path:match('^[%w_.%-]+$') or n ~= n or n < 0 or n == math.huge then return end
    merge(Telemetry.data, { [res] = { [Telemetry.tz[tonumber(src)] or 'unknown'] = { [path] = n } } })
    Telemetry.dirty = true
end

function Telemetry.save()
    SetResourceKvp('telemetry:data', json.encode(Telemetry.data))
    Telemetry.dirty = false
end

function Telemetry.tick()
    if Telemetry.dirty then Telemetry.save() end
    local last = tonumber(GetResourceKvpString('telemetry:sent')) or 0
    if Telemetry.endpoint == '' or not enabled() or next(Telemetry.data) == nil or os.time() - last < SEND_EVERY then return end
    SetResourceKvp('telemetry:sent', tostring(os.time()))
    local out = Telemetry.data
    Telemetry.data = {}
    PerformHttpRequest(Telemetry.endpoint, function(status)
        if not status or status < 200 or status == 429 or status >= 500 then merge(Telemetry.data, out) end
        Telemetry.save()
    end, 'POST', json.encode({ install = id, lib = GetResourceMetadata(LIB, 'version', 0), resources = TwLib.Update.installed(), data = out }),
        { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('tw-lib:server:tz', function(tz)
    local src = source
    if Telemetry.live[src] then return end
    TriggerClientEvent('tw-lib:client:tz', src)
    if type(tz) ~= 'string' or #tz > 64 or not tz:match('^[%w_/+%-]+$') then return end
    if not zones[tz] then
        if zoneCount >= MAX_ZONES then tz = 'other' else zones[tz], zoneCount = true, zoneCount + 1 end
    end
    Telemetry.live[src], Telemetry.tz[src] = true, tz
    Telemetry.add(LIB, 'sessions', 1, src)
end)

function Telemetry.preview()
    local rows = {}
    for res, byZone in pairs(Telemetry.data) do
        for tz, paths in pairs(byZone) do
            for path, n in pairs(paths) do rows[#rows + 1] = { res = res, tz = tz, path = path, n = n } end
        end
    end
    table.sort(rows, function(a, b) return a.res .. ' ' .. a.tz .. ' ' .. a.path < b.res .. ' ' .. b.tz .. ' ' .. b.path end)
    local sent = tonumber(GetResourceKvpString('telemetry:sent'))
    return { enabled = enabled(), install = id, rows = rows, sent = sent and sent * 1000,
        next = (Telemetry.due + math.max(0, math.ceil(((sent or 0) + SEND_EVERY - Telemetry.due) / TICK)) * TICK) * 1000 }
end

AddEventHandler('playerDropped', function() Telemetry.live[source] = nil end)

exports('Telemetry', function(path, n, src) Telemetry.add(GetInvokingResource() or LIB, path, n, src) end)

local function loop()
    Telemetry.tick()
    Telemetry.due = os.time() + TICK
    SetTimeout(TICK * 1000, loop)
end
Telemetry.due = os.time() + TICK
SetTimeout(TICK * 1000, loop)
