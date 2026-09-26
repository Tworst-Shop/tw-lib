TwLib = TwLib or {}
local C = {}
TwLib.ConfigFile = C

local BS = string.char(92)

local function lex(text)
    local toks, n, i, lineStart = {}, #text, 1, true
    local function push(t, s, e)
        toks[#toks + 1] = { t = t, v = text:sub(s, e), s = s, e = e, first = lineStart }
        lineStart = false
    end
    while i <= n do
        local c = text:sub(i, i)
        if c == '\n' then
            lineStart, i = true, i + 1
        elseif c:match('%s') then
            i = i + 1
        elseif text:sub(i, i + 1) == '--' then
            local eq = text:match('^%[(=*)%[', i + 2)
            if eq then
                local _, stop = text:find(']' .. eq .. ']', i + 4 + #eq, true)
                stop = stop or n
                if text:sub(i, stop):find('\n', 1, true) then lineStart = true end
                i = stop + 1
            else
                i = text:find('\n', i, true) or (n + 1)
            end
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = text:sub(j, j)
                if d == BS then j = j + 2
                elseif d == c or d == '\n' then break
                else j = j + 1 end
            end
            push('string', i, math.min(j, n))
            i = j + 1
        elseif c == '[' and text:match('^%[=*%[', i) then
            local eq = text:match('^%[(=*)%[', i)
            local _, stop = text:find(']' .. eq .. ']', i + 2 + #eq, true)
            stop = stop or n
            push('string', i, stop)
            i = stop + 1
        elseif c == '`' then
            local stop = text:find('`', i + 1, true) or n
            push('hash', i, stop)
            i = stop + 1
        elseif c:match('%d') or (c == '.' and text:sub(i + 1, i + 1):match('%d')) then
            local _, e = text:find('^0[xX]%x+', i)
            if not e then _, e = text:find('^%d*%.?%d*[eE][%+%-]?%d+', i) end
            if not e then _, e = text:find('^%d*%.?%d*', i) end
            push('number', i, e)
            i = e + 1
        elseif c:match('[%a_]') then
            local _, e = text:find('^[%w_]+', i)
            push('name', i, e)
            i = e + 1
        else
            local two = text:sub(i, i + 1)
            local len = 1
            if text:sub(i, i + 2) == '...' then len = 3
            elseif two == '..' or two == '==' or two == '~=' or two == '<=' or two == '>=' or two == '//' or two == '::' then len = 2 end
            push('op', i, i + len - 1)
            i = i + len
        end
    end
    toks[#toks + 1] = { t = 'eof', v = '', s = n + 1, e = n, first = true }
    return toks
end

local OPENS = { ['function'] = true, ['if'] = true, ['do'] = true, ['repeat'] = true }
local CLOSES = { ['end'] = true, ['until'] = true }

local function pathKey(path)
    local parts = {}
    for i, p in ipairs(path) do parts[i] = type(p) == 'number' and string.format('%d', p) or tostring(p) end
    return table.concat(parts, '.')
end

local function child(path, key)
    local out = { table.unpack(path) }
    out[#out + 1] = key
    return out
end

local function literalKey(tok)
    if tok.t == 'number' then return tonumber(tok.v) end
    if tok.t == 'string' then
        local ok, v = pcall(load('return ' .. tok.v, 'key', 't', {}))
        if ok then return v end
    end
end

local function isOp(tok, v) return tok.t == 'op' and tok.v == v end

local function skip(toks, i, inTable)
    local depth, start = 0, i
    while toks[i].t ~= 'eof' do
        local tok = toks[i]
        if depth == 0 and i > start then
            if inTable and (isOp(tok, ',') or isOp(tok, ';') or isOp(tok, '}')) then return i end
            if not inTable and tok.first then return i end
        end
        if tok.t == 'op' and (tok.v == '(' or tok.v == '{' or tok.v == '[') then
            depth = depth + 1
        elseif tok.t == 'op' and (tok.v == ')' or tok.v == '}' or tok.v == ']') then
            if depth == 0 then return i end
            depth = depth - 1
        elseif tok.t == 'name' and OPENS[tok.v] then
            depth = depth + 1
        elseif tok.t == 'name' and CLOSES[tok.v] then
            depth = depth - 1
        end
        i = i + 1
    end
    return i
end

local parseTable

local function ends(tok, inTable)
    if inTable then return isOp(tok, ',') or isOp(tok, ';') or isOp(tok, '}') end
    return tok.t == 'eof' or tok.first or isOp(tok, ';')
end

local function parseValue(toks, i, path, found, inTable)
    local tok = toks[i]
    if isOp(tok, '{') then
        found[pathKey(path)] = { lit = false }
        return parseTable(toks, i, path, found)
    end
    local j = i
    if isOp(tok, '-') and toks[i + 1].t == 'number' then j = i + 1 end
    local last = toks[j]
    local literal = last.t == 'number' or (j == i and (last.t == 'string' or (last.t == 'name' and (last.v == 'true' or last.v == 'false'))))
    if literal and ends(toks[j + 1], inTable) then
        found[pathKey(path)] = { lit = true, s = tok.s, e = last.e }
        return j + 1
    end
    found[pathKey(path)] = { lit = false }
    return skip(toks, i, inTable)
end

parseTable = function(toks, i, path, found)
    i = i + 1
    local index = 0
    while toks[i].t ~= 'eof' do
        local tok = toks[i]
        if isOp(tok, '}') then return i + 1 end
        if isOp(tok, ',') or isOp(tok, ';') then
            i = i + 1
        elseif isOp(tok, '[') and isOp(toks[i + 2], ']') and isOp(toks[i + 3], '=') then
            i = parseValue(toks, i + 4, child(path, literalKey(toks[i + 1]) or '?'), found, true)
        elseif isOp(tok, '[') then
            local close = skip(toks, i + 1, true)
            i = isOp(toks[close + 1], '=') and skip(toks, close + 2, true) or close + 1
        elseif tok.t == 'name' and isOp(toks[i + 1], '=') then
            i = parseValue(toks, i + 2, child(path, tok.v), found, true)
        else
            index = index + 1
            i = parseValue(toks, i, child(path, index), found, true)
        end
    end
    return i
end

local function scan(text)
    local toks, found, i = lex(text), {}, 1
    while toks[i].t ~= 'eof' do
        local tok = toks[i]
        if tok.t == 'name' and tok.first and not OPENS[tok.v] and tok.v ~= 'local' and tok.v ~= 'return' then
            local path, j = { tok.v }, i + 1
            while true do
                if isOp(toks[j], '.') and toks[j + 1].t == 'name' then
                    path[#path + 1], j = toks[j + 1].v, j + 2
                elseif isOp(toks[j], '[') and isOp(toks[j + 2], ']') and literalKey(toks[j + 1]) ~= nil then
                    path[#path + 1], j = literalKey(toks[j + 1]), j + 3
                else
                    break
                end
            end
            if isOp(toks[j], '=') then
                i = parseValue(toks, j + 1, path, found, false)
            else
                i = skip(toks, i, false)
            end
        else
            i = skip(toks, i, false)
        end
    end
    return found
end

local MARKER = '^()[ \t]*%-%-%[%[twlib:(.-)%]%]()'

local function kindOf(literal)
    if literal == 'true' or literal == 'false' then return 'boolean' end
    local q = literal:sub(1, 1)
    if q == '"' or q == "'" or q == '[' then return 'string' end
    return 'number'
end

local function render(value, original)
    local t = type(value)
    if t == 'boolean' then return tostring(value) end
    if t == 'number' then
        if value == math.floor(value) and math.abs(value) < 2 ^ 53 then return string.format('%d', value) end
        return tostring(value)
    end
    if t == 'string' then
        local q = original:sub(1, 1)
        if q ~= '"' and q ~= "'" then q = '"' end
        local body = value:gsub(BS, BS .. BS):gsub(q, BS .. q):gsub('\n', BS .. 'n'):gsub('\r', BS .. 'r')
        return q .. body .. q
    end
end

local function spot(text, path)
    local found = scan(text)[pathKey(path)]
    if not found then return nil, 'missing' end
    if not found.lit then return nil, 'not-literal' end
    return found
end

function C.read(text, path)
    local s, reason = spot(text, path)
    if not s then return nil, reason end
    return text:sub(s.s, s.e)
end

local function replaced(default, value)
    local vt = type(value)
    if (vt ~= 'number' and vt ~= 'boolean' and vt ~= 'string') or vt ~= kindOf(default) then return nil, 'type' end
    local new = render(value, default)
    if new == default then return default end
    if default:sub(1, 1) == '[' or default:find(']]', 1, true) then return nil, 'marker' end
    return new .. ' --[[twlib:' .. default .. ']]'
end

function C.set(text, path, value)
    local s, reason = spot(text, path)
    if not s then return nil, reason end
    local _, original, after = text:match(MARKER, s.e + 1)
    local out, why = replaced(original or text:sub(s.s, s.e), value)
    if not out then return nil, why end
    return text:sub(1, s.s - 1) .. out .. text:sub(after or (s.e + 1))
end

function C.pristine(text)
    if type(text) ~= 'string' or not text:find('--[[twlib:', 1, true) then return text end
    local spots = {}
    for _, s in pairs(scan(text)) do
        if s.lit then spots[#spots + 1] = s end
    end
    table.sort(spots, function(a, b) return a.s > b.s end)
    for _, s in ipairs(spots) do
        local _, original, after = text:match(MARKER, s.e + 1)
        if original then text = text:sub(1, s.s - 1) .. original .. text:sub(after) end
    end
    return text
end

function C.marked(text)
    local out = {}
    if type(text) ~= 'string' or not text:find('--[[twlib:', 1, true) then return out end
    for key, s in pairs(scan(text)) do
        if s.lit and text:match(MARKER, s.e + 1) then out[key] = true end
    end
    return out
end

local function plain(value)
    local t = type(value)
    return t == 'number' or t == 'boolean' or t == 'string'
end

function C.sync(res, rows)
    local count = 0
    for i = 0, (GetNumResourceMetadata(res, 'tw_lib_config') or 0) - 1 do
        local file = GetResourceMetadata(res, 'tw_lib_config', i)
        local current = file and LoadResourceFile(res, file)
        if current then
            local text = C.pristine(current)
            local shipped = LoadResourceFile(res, file .. '.shipped')
            local spots, base, edits = scan(text), shipped and scan(shipped) or {}, {}
            for _, row in ipairs(rows or {}) do
                local key = type(row.path) == 'table' and plain(row.value) and pathKey(row.path)
                local s, b = key and spots[key], key and base[key]
                local out
                if key and row.path[1] == 'Server' then
                    local now = s and s.lit and text:sub(s.s, s.e)
                    local blank = now and kindOf(now) == 'string' and (b and b.lit and shipped:sub(b.s, b.e) or render('', now))
                    if blank and blank ~= now then
                        out = blank
                        print(('^3[tw-lib]^7 %s: %s moved out of %s (clients download that file), kept in the database'):format(res, key, file))
                    end
                else
                    local default = s and s.lit and (b and b.lit and shipped:sub(b.s, b.e) or text:sub(s.s, s.e))
                    out = default and replaced(default, row.value)
                end
                if out then edits[#edits + 1], count = { s = s.s, e = s.e, out = out }, count + 1 end
            end
            table.sort(edits, function(x, y) return x.s > y.s end)
            for _, edit in ipairs(edits) do text = text:sub(1, edit.s - 1) .. edit.out .. text:sub(edit.e + 1) end
            if text ~= current then SaveResourceFile(res, file, text, -1) end
        end
    end
    return count
end
