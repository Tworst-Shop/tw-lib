TwLib = TwLib or {}
local V = {}
TwLib.Version = V

function V.parts(v)
    local out = {}
    for n in tostring(v or ''):gmatch('%d+') do out[#out + 1] = tonumber(n) end
    return out
end

function V.atLeast(have, need)
    local a, b = V.parts(have), V.parts(need)
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return true
end
