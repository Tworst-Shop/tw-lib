local Version = TwLib.Version
local LIB = GetCurrentResourceName()
local ENDPOINT = 'https://tworst.com/scripts/%s/version.json'
local GOLD, GREEN, RESET = '^3', '^2', '^7'
local Update = {}
TwLib.Update = Update

function Update.installed()
    local out = { [LIB] = GetResourceMetadata(LIB, 'version', 0) or '0.0.0' }
    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and res ~= LIB and GetResourceMetadata(res, 'tw_lib', 0) ~= nil then
            out[res] = GetResourceMetadata(res, 'version', 0) or '0.0.0'
        end
    end
    return out
end

local function ordered(installed)
    local names = {}
    for res in pairs(installed) do names[#names + 1] = res end
    table.sort(names, function(a, b) return a == LIB or (b ~= LIB and a < b) end)
    return names
end

local function width(s) return utf8.len(s) or #s end

local function promoBox(promo, lang)
    local loc = type(promo.locales) == 'table' and type(promo.locales[lang]) == 'table' and promo.locales[lang] or {}
    local title = tostring(loc.title or promo.title or 'TWORST')
    local lines = type(loc.lines or promo.lines) == 'table' and (loc.lines or promo.lines) or {}
    local url = tostring(loc.url or promo.url or '')
    if url == '' then url = 'tworst.com' end
    local w = math.max(width(title), width(url) + 3)
    for _, line in ipairs(lines) do w = math.max(w, width(tostring(line))) end
    w = math.min(60, math.max(w, 34))
    local function row(text)
        text = tostring(text)
        local cut = width(text) > w and utf8.offset(text, w + 1)
        if cut then text = text:sub(1, cut - 1) end
        return GOLD .. '|' .. RESET .. ' ' .. text .. (' '):rep(w - width(text)) .. ' ' .. GOLD .. '|' .. RESET
    end
    local out = { '', GOLD .. '+' .. ('='):rep(w + 2) .. '+' .. RESET, row(title), GOLD .. '+' .. ('-'):rep(w + 2) .. '+' .. RESET }
    for _, line in ipairs(lines) do out[#out + 1] = row(line) end
    out[#out + 1] = row('')
    out[#out + 1] = row('-> ' .. url)
    out[#out + 1] = GOLD .. '+' .. ('='):rep(w + 2) .. '+' .. RESET
    out[#out + 1] = ''
    return out
end

function Update.lines(latest, installed, lang)
    local out, current, promos, seen = {}, {}, {}, {}
    for _, res in ipairs(ordered(installed)) do
        local data = latest[res]
        local want = type(data) == 'table' and data.version
        if type(want) == 'string' then
            if Version.atLeast(installed[res], want) then
                current[#current + 1] = res .. ' ' .. installed[res]
            else
                local url = type(data.url) == 'string' and data.url ~= '' and data.url or 'https://tworst.com'
                out[#out + 1] = ('%s[tw-lib]%s update available: %s %s -> %s%s%s  %s'):format(GOLD, RESET, res, installed[res], GREEN, want, RESET, url)
            end
            local promo = data.promo
            local key = type(promo) == 'table' and promo.enabled and (tostring(promo.title) .. '|' .. tostring(promo.url))
            if key and not seen[key] then
                seen[key] = true
                promos[#promos + 1] = promo
            end
        end
    end
    if #current > 0 then
        table.insert(out, 1, ('%s[tw-lib]%s up to date: %s'):format(GREEN, RESET, table.concat(current, ', ')))
    end
    for _, promo in ipairs(promos) do
        for _, line in ipairs(promoBox(promo, lang)) do out[#out + 1] = line end
    end
    return out
end

function Update.check()
    local installed, latest, waiting = Update.installed(), {}, 0
    for res in pairs(installed) do
        waiting = waiting + 1
        PerformHttpRequest(ENDPOINT:format(res), function(status, body)
            if status == 200 and type(body) == 'string' then
                local ok, data = pcall(json.decode, body)
                if ok and type(data) == 'table' then latest[res] = data end
            end
            waiting = waiting - 1
            if waiting > 0 then return end
            local lang = TwLib.Store and TwLib.Store.get and TwLib.Store.get(LIB, { 'locale' }) or 'en'
            for _, line in ipairs(Update.lines(latest, installed, lang)) do print(line) end
        end, 'GET')
    end
end

SetTimeout(5000, Update.check)
