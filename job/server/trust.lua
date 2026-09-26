function ConfigRegion(regions, field, value)
    if value == nil then return nil end
    for _, region in pairs(regions or {}) do
        if region[field] ~= nil and tostring(region[field]) == tostring(value) then
            return TwLib.Merge.copy(region)
        end
    end
    return nil
end

function ConfigSpawnPoint(points, picked, radius)
    local ok, x, y, z = pcall(function() return tonumber(picked.x), tonumber(picked.y), tonumber(picked.z) end)
    if not (ok and x and y and z) then return nil end
    local max = (radius or 2.0) ^ 2
    for _, p in pairs(points or {}) do
        if (p.x - x) ^ 2 + (p.y - y) ^ 2 + (p.z - z) ^ 2 <= max then return p end
    end
    return nil
end
