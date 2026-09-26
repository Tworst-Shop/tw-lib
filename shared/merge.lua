TwLib = TwLib or {}
local M = {}
TwLib.Merge = M

function M.typeOf(v)
    local t = type(v)
    if t == 'table' then
        local mt = getmetatable(v)
        if mt and mt.__name then return mt.__name end
    end
    return t
end

function M.isList(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n == #t
end

function M.isValueList(t)
    if not M.isList(t) then return false end
    if #t == 0 then return true end
    for i = 1, #t do
        if M.typeOf(t[i]) ~= 'table' then return true end
    end
    return false
end

function M.copy(v)
    if type(v) ~= 'table' then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = M.copy(x) end
    return setmetatable(out, getmetatable(v))
end

function M.equal(a, b)
    local ta = M.typeOf(a)
    if ta ~= M.typeOf(b) then return false end
    if ta == 'vector3' then return a.x == b.x and a.y == b.y and a.z == b.z end
    if ta == 'vector4' then return a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w end
    if ta ~= 'table' then return a == b end
    for k, x in pairs(a) do
        if not M.equal(x, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

function M.encode(v)
    local t = M.typeOf(v)
    if t == 'vector3' then return { __vec = 3, x = v.x, y = v.y, z = v.z } end
    if t == 'vector4' then return { __vec = 4, x = v.x, y = v.y, z = v.z, w = v.w } end
    if t ~= 'table' then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = M.encode(x) end
    return out
end

function M.decode(v)
    if type(v) ~= 'table' then return v end
    if v.__vec == 3 then return vector3(v.x, v.y, v.z) end
    if v.__vec == 4 then return vector4(v.x, v.y, v.z, v.w) end
    local out = {}
    for k, x in pairs(v) do out[k] = M.decode(x) end
    return out
end

function M.pathKey(path)
    local parts = {}
    for i, p in ipairs(path) do
        if type(p) == 'number' and math.floor(p) == p then p = string.format('%d', p) end
        parts[i] = tostring(p)
    end
    return table.concat(parts, '.')
end

function M.set(config, path, value)
    if #path == 0 then return 'empty-path' end
    local node = config
    for i = 1, #path - 1 do
        node = node[path[i]]
        if M.typeOf(node) ~= 'table' or M.isValueList(node) then return 'missing' end
    end
    local current = node[path[#path]]
    if current == nil then return 'missing' end
    if M.typeOf(current) ~= M.typeOf(value) then return 'type' end
    if M.typeOf(current) == 'table' and not M.isValueList(current) then return 'not-leaf' end
    node[path[#path]] = M.copy(value)
    return nil
end

function M.apply(defaults, overrides, renamed)
    local config = M.copy(defaults)
    local report = { applied = 0, dropped = {} }
    for _, row in ipairs(overrides or {}) do
        local path = (renamed and renamed[M.pathKey(row.path)]) or row.path
        local reason = M.set(config, path, row.value)
        if reason then
            report.dropped[#report.dropped + 1] = { path = path, reason = reason }
        else
            report.applied = report.applied + 1
        end
    end
    return config, report
end

local function walk(defaults, custom, prefix, out)
    for key, dv in pairs(defaults) do
        local cv = custom[key]
        local dt = M.typeOf(dv)
        local path = { table.unpack(prefix) }
        path[#path + 1] = key
        if cv ~= nil and dt ~= 'function' and M.typeOf(cv) == dt then
            if dt == 'table' and not M.isValueList(dv) then
                if not M.isValueList(cv) then walk(dv, cv, path, out) end
            elseif dt ~= 'table' or M.isValueList(cv) then
                if not M.equal(dv, cv) then out[#out + 1] = { path = path, value = M.copy(cv) } end
            end
        end
    end
end

function M.diff(defaults, custom)
    local out = {}
    walk(defaults, custom, {}, out)
    table.sort(out, function(a, b) return M.pathKey(a.path) < M.pathKey(b.path) end)
    return out
end
