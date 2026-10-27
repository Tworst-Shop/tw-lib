if lib then return end

local loaded = {}
function require(name)
    if loaded[name] ~= nil then return loaded[name] end
    local res, path = name:match('^@([^%.]+)%.(.+)$')
    if not res then error(('require: %s is not @resource.path'):format(name), 2) end
    path = path:gsub('%.', '/') .. '.lua'
    local code = LoadResourceFile(res, path)
    if not code then error(('require: %s/%s not found'):format(res, path), 2) end
    local fn, err = load(code, ('@@%s/%s'):format(res, path))
    if not fn then error(err, 2) end
    local mod = fn(name)
    loaded[name] = mod == nil and true or mod
    return loaded[name]
end

cache = setmetatable({}, { __index = function(_, k)
    if k == 'ped' then return PlayerPedId() end
    if k == 'vehicle' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        return veh ~= 0 and veh or false
    end
end })

local function nearby(pool, key, coords, maxDist, skip)
    local out = {}
    for _, ent in ipairs(GetGamePool(pool)) do
        if ent ~= skip then
            local pos = GetEntityCoords(ent)
            if #(coords - pos) < maxDist then out[#out + 1] = { [key] = ent, coords = pos } end
        end
    end
    return out
end

local function deepclone(t)
    local out = {}
    for k, v in pairs(t) do out[k] = type(v) == 'table' and deepclone(v) or v end
    return setmetatable(out, getmetatable(t))
end

lib = {
    table = { deepclone = deepclone },
    getNearbyObjects = function(coords, maxDist) return nearby('CObject', 'object', coords, maxDist or 2.0) end,
    getNearbyVehicles = function(coords, maxDist, withMine)
        return nearby('CVehicle', 'vehicle', coords, maxDist or 2.0, not withMine and cache.vehicle or nil)
    end,
    requestStreamedTextureDict = function(dict)
        if HasStreamedTextureDictLoaded(dict) then return dict end
        RequestStreamedTextureDict(dict, false)
        local timeout = GetGameTimer() + 10000
        while not HasStreamedTextureDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
        return dict
    end,
}
