TwLib = TwLib or {}
local Stats = { cache = {} }
TwLib.Stats = Stats

local CACHE_SECONDS = 30
local PAGE = 50
local CHART_DAYS_ALL = 90

Stats.now = os.time
Stats.today = os.time

local RANGES = { today = 0, ['7d'] = 6, ['30d'] = 29, all = 36500 }

function Stats.window(range)
    local back = RANGES[range] or RANGES['7d']
    return { back = back, days = back + 1, compare = range ~= 'all' }
end

local function ready() return TwLib.Schema ~= nil and TwLib.Schema.ready == true end

local function rows(query, params)
    local result = MySQL.query.await(query, params)
    return type(result) == 'table' and result or {}
end

local num = function(v) return tonumber(v) or 0 end
local function perHour(money, seconds)
    money, seconds = num(money), num(seconds)
    return seconds > 0 and math.floor(money * 3600 / seconds + 0.5) or 0
end

local LEDGER_TOTALS = [[SELECT
  COALESCE(SUM(CASE WHEN `created_at` >= CURDATE() - INTERVAL ? DAY THEN `amount` END), 0) AS money_now,
  COALESCE(SUM(CASE WHEN `created_at` < CURDATE() - INTERVAL ? DAY THEN `amount` END), 0) AS money_prev
FROM `tw_lib_ledger`
WHERE `kind` = 'money' AND `direction` = 'in' AND `reason` NOT IN ('deposit', 'rental', 'refund') AND `created_at` >= CURDATE() - INTERVAL ? DAY]]

local HISTORY_TOTALS = [[SELECT
  COUNT(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN 1 END) AS sessions_now,
  COUNT(CASE WHEN `completed_at` < CURDATE() - INTERVAL ? DAY THEN 1 END) AS sessions_prev,
  COALESCE(SUM(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY AND `duration_seconds` > 0 THEN `earned_money` END), 0) AS timed_money_now,
  COALESCE(SUM(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN `duration_seconds` END), 0) AS seconds_now,
  COALESCE(SUM(CASE WHEN `completed_at` < CURDATE() - INTERVAL ? DAY AND `duration_seconds` > 0 THEN `earned_money` END), 0) AS timed_money_prev,
  COALESCE(SUM(CASE WHEN `completed_at` < CURDATE() - INTERVAL ? DAY THEN `duration_seconds` END), 0) AS seconds_prev
FROM `tw_lib_job_history`
WHERE `completed_at` >= CURDATE() - INTERVAL ? DAY]]

local LEDGER_BY_DAY = [[SELECT DATE_FORMAT(`created_at`, '%Y-%m-%d') AS day, `resource`, `kind`, COALESCE(SUM(`amount`), 0) AS total
FROM `tw_lib_ledger`
WHERE `direction` = 'in' AND `kind` IN ('money', 'xp') AND `reason` NOT IN ('deposit', 'rental', 'refund') AND `created_at` >= CURDATE() - INTERVAL ? DAY
GROUP BY day, `resource`, `kind`]]

local LEDGER_BY_HOUR = [[SELECT HOUR(`created_at`) AS hour, `resource`, `kind`, COALESCE(SUM(`amount`), 0) AS total
FROM `tw_lib_ledger`
WHERE `direction` = 'in' AND `kind` IN ('money', 'xp') AND `reason` NOT IN ('deposit', 'rental', 'refund') AND `created_at` >= CURDATE()
GROUP BY hour, `resource`, `kind`]]

local HISTORY_BY_DAY = [[SELECT DATE_FORMAT(`completed_at`, '%Y-%m-%d') AS day, `job_id`, COUNT(*) AS sessions,
  COALESCE(SUM(`earned_money`), 0) AS money, COALESCE(SUM(`duration_seconds`), 0) AS seconds
FROM `tw_lib_job_history`
WHERE `completed_at` >= CURDATE() - INTERVAL ? DAY
GROUP BY day, `job_id`]]

local HISTORY_BY_HOUR = [[SELECT HOUR(`completed_at`) AS hour, `job_id`, COUNT(*) AS sessions,
  COALESCE(SUM(`earned_money`), 0) AS money, COALESCE(SUM(`duration_seconds`), 0) AS seconds
FROM `tw_lib_job_history`
WHERE `completed_at` >= CURDATE()
GROUP BY hour, `job_id`]]

local SHARE = [[SELECT `resource`, COALESCE(SUM(`amount`), 0) AS money
FROM `tw_lib_ledger`
WHERE `kind` = 'money' AND `direction` = 'in' AND `reason` NOT IN ('deposit', 'rental', 'refund') AND `created_at` >= CURDATE() - INTERVAL ? DAY
GROUP BY `resource`
ORDER BY money DESC]]

local PLAYER_JOBS = [[SELECT h.`identifier`, MAX(p.`name`) AS name, h.`job_id`, COUNT(*) AS sessions,
  COALESCE(SUM(h.`earned_money`), 0) AS money, COALESCE(SUM(h.`duration_seconds`), 0) AS seconds,
  MAX(h.`completed_at`) AS last_seen
FROM `tw_lib_job_history` h
LEFT JOIN `tw_lib_players` p ON p.`identifier` = h.`identifier`
WHERE h.`completed_at` >= CURDATE() - INTERVAL ? DAY AND (? = '' OR h.`job_id` = ?)
  AND (h.`identifier` LIKE ? OR COALESCE(p.`name`, '') LIKE ?)
GROUP BY h.`identifier`, h.`job_id`]]

local JOB_TOTALS = [[SELECT `job_id`,
  COUNT(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN 1 END) AS sessions,
  COALESCE(SUM(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN `earned_money` END), 0) AS money,
  COALESCE(SUM(CASE WHEN `completed_at` < CURDATE() - INTERVAL ? DAY THEN `earned_money` END), 0) AS prev,
  COALESCE(SUM(CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN `duration_seconds` END), 0) AS seconds,
  COUNT(DISTINCT CASE WHEN `completed_at` >= CURDATE() - INTERVAL ? DAY THEN `identifier` END) AS players
FROM `tw_lib_job_history`
WHERE `completed_at` >= CURDATE() - INTERVAL ? DAY
GROUP BY `job_id`]]

local REGIONS = [[SELECT `region_name`, COUNT(*) AS sessions, COALESCE(SUM(`earned_money`), 0) AS money,
  COALESCE(SUM(`duration_seconds`), 0) AS seconds
FROM `tw_lib_job_history`
WHERE `job_id` = ? AND `completed_at` >= CURDATE() - INTERVAL ? DAY
GROUP BY `region_name`
ORDER BY money DESC]]

local PLAYER_XP = [[SELECT COALESCE(SUM(`amount`), 0) AS xp
FROM `tw_lib_ledger`
WHERE `identifier` = ? AND `kind` = 'xp' AND `direction` = 'in' AND `created_at` >= CURDATE() - INTERVAL ? DAY]]

local PLAYER_NAME = [[SELECT `name`, `fivem_name` FROM `tw_lib_players` WHERE `identifier` = ?]]

local LEDGER_PAGE = [[SELECT l.`resource`, l.`identifier`, p.`name`, l.`kind`, l.`direction`, l.`account`, l.`item`,
  l.`amount`, l.`reason`, l.`created_at`
FROM `tw_lib_ledger` l
LEFT JOIN `tw_lib_players` p ON p.`identifier` = l.`identifier`
WHERE (? = '' OR l.`resource` = ?) AND (? = '' OR l.`kind` = ?) AND (? = '' OR l.`direction` = ?)
  AND (? = '' OR l.`identifier` = ? OR COALESCE(p.`name`, '') LIKE ?)
  AND l.`created_at` >= CURDATE() - INTERVAL ? DAY AND l.`created_at` < CURDATE() + INTERVAL ? DAY
ORDER BY l.`id` DESC
LIMIT ? OFFSET ?]]

local function labelsFor(range)
    if range == 'today' then
        local labels = {}
        for h = 0, 23 do labels[#labels + 1] = ('%02d:00'):format(h) end
        return 'hour', labels
    end
    local w = Stats.window(range)
    local days = range == 'all' and CHART_DAYS_ALL or w.days
    local labels, base = {}, Stats.today()
    for i = days - 1, 0, -1 do labels[#labels + 1] = os.date('%Y-%m-%d', base - i * 86400) end
    return 'day', labels
end

local function slotOf(unit, labels)
    local index = {}
    for i, label in ipairs(labels) do index[label] = i end
    return function(row)
        if unit == 'hour' then return tonumber(row.hour) and (tonumber(row.hour) + 1) or nil end
        return index[tostring(row.day)]
    end
end

local function emptySeries(n)
    local t = {}
    for i = 1, n do t[i] = 0 end
    return t
end

local function series(range)
    local unit, labels = labelsFor(range)
    local slot = slotOf(unit, labels)
    local back = range == 'all' and (CHART_DAYS_ALL - 1) or Stats.window(range).back
    local byJob, order = {}, {}
    local function job(name)
        if not byJob[name] then
            byJob[name] = { job = name, money = emptySeries(#labels), xp = emptySeries(#labels), sessions = emptySeries(#labels) }
            order[#order + 1] = name
        end
        return byJob[name]
    end

    local ledger = unit == 'hour' and rows(LEDGER_BY_HOUR, {}) or rows(LEDGER_BY_DAY, { back })
    for _, r in ipairs(ledger) do
        local i = slot(r)
        if i and (r.kind == 'money' or r.kind == 'xp') then
            local entry = job(r.resource)
            entry[r.kind][i] = entry[r.kind][i] + num(r.total)
        end
    end
    local history = unit == 'hour' and rows(HISTORY_BY_HOUR, {}) or rows(HISTORY_BY_DAY, { back })
    for _, r in ipairs(history) do
        local i = slot(r)
        if i then
            local entry = job(r.job_id)
            entry.sessions[i] = entry.sessions[i] + num(r.sessions)
        end
    end

    local jobs = {}
    for _, name in ipairs(order) do jobs[#jobs + 1] = byJob[name] end
    return { unit = unit, labels = labels, jobs = jobs }, history, slot, #labels
end

local function collectPlayers(range, search, jobId)
    local like = '%' .. tostring(search or ''):gsub('[%%_]', '') .. '%'
    local jobFilter = jobId or ''
    local players, order = {}, {}
    for _, r in ipairs(rows(PLAYER_JOBS, { Stats.window(range).back, jobFilter, jobFilter, like, like })) do
        local p = players[r.identifier]
        if not p then
            p = { identifier = r.identifier, name = r.name, money = 0, sessions = 0, seconds = 0, lastSeen = 0, topJob = nil, topMoney = -1 }
            players[r.identifier] = p
            order[#order + 1] = p
        end
        local money = num(r.money)
        p.money = p.money + money
        p.sessions = p.sessions + num(r.sessions)
        p.seconds = p.seconds + num(r.seconds)
        p.name = p.name or r.name
        if num(r.last_seen) > num(p.lastSeen) then p.lastSeen = r.last_seen end
        if money > p.topMoney then p.topJob, p.topMoney = r.job_id, money end
    end
    local totalMoney, totalSeconds = 0, 0
    for _, p in ipairs(order) do
        p.perHour = perHour(p.money, p.seconds)
        totalMoney, totalSeconds = totalMoney + p.money, totalSeconds + p.seconds
        p.seconds, p.topMoney = nil, nil
    end
    table.sort(order, function(a, b) return a.money > b.money end)
    return order, perHour(totalMoney, totalSeconds)
end

local function cached(key, fresh, build)
    local hit = Stats.cache[key]
    if not fresh and hit and Stats.now() - hit.at < CACHE_SECONDS then return hit.data end
    local data = build()
    Stats.cache[key] = { at = Stats.now(), data = data }
    return data
end

function Stats.overview(range, fresh)
    if not ready() then return nil end
    local w = Stats.window(range)
    return cached('overview:' .. tostring(range), fresh, function()
        local m = rows(LEDGER_TOTALS, { w.back, w.back, w.compare and (2 * w.back + 1) or w.back })[1] or {}
        local lower = w.compare and (2 * w.back + 1) or w.back
        local h = rows(HISTORY_TOTALS, { w.back, w.back, w.back, w.back, w.back, w.back, lower })[1] or {}
        local prev = function(v) if w.compare then return v end end
        local chart = series(range)
        local share = {}
        for _, r in ipairs(rows(SHARE, { w.back })) do share[#share + 1] = { job = r.resource, money = num(r.money) } end
        local top = collectPlayers(range)
        while #top > 8 do table.remove(top) end
        return {
            kpi = {
                money = { value = num(m.money_now), prev = prev(num(m.money_prev)) },
                sessions = { value = num(h.sessions_now), prev = prev(num(h.sessions_prev)) },
                perHour = { value = perHour(h.timed_money_now, h.seconds_now), prev = prev(perHour(h.timed_money_prev, h.seconds_prev)) },
            },
            series = chart,
            share = share,
            top = top,
        }
    end)
end

function Stats.players(range, search)
    if not ready() then return nil end
    local list, average = collectPlayers(range, search)
    while #list > 100 do table.remove(list) end
    return { list = list, avgPerHour = average }
end

function Stats.jobs(range, running)
    if not ready() then return {} end
    local w = Stats.window(range)
    local lower = w.compare and (2 * w.back + 1) or w.back
    local byJob, out = {}, {}
    for _, r in ipairs(rows(JOB_TOTALS, { w.back, w.back, w.back, w.back, w.back, lower })) do
        local sessions, seconds = num(r.sessions), num(r.seconds)
        local entry = { job = r.job_id, money = num(r.money), prev = w.compare and num(r.prev) or nil, sessions = sessions,
            avgDuration = sessions > 0 and math.floor(seconds / sessions) or 0, perHour = perHour(r.money, seconds),
            players = num(r.players), spark = {} }
        byJob[r.job_id] = entry
        out[#out + 1] = entry
    end
    local _, history, slot, size = series(range)
    for _, r in ipairs(history) do
        local entry, i = byJob[r.job_id], slot(r)
        if entry and i then
            if #entry.spark == 0 then entry.spark = emptySeries(size) end
            entry.spark[i] = entry.spark[i] + num(r.money)
        end
    end
    table.sort(out, function(a, b) return a.money > b.money end)
    for _, res in ipairs(running or {}) do
        if not byJob[res] then
            out[#out + 1] = { job = res, money = 0, prev = 0, sessions = 0, avgDuration = 0, perHour = 0, players = 0, spark = {} }
        end
    end
    return out
end

function Stats.regions(res, range)
    if not ready() then return {} end
    local out = {}
    for _, r in ipairs(rows(REGIONS, { res, Stats.window(range).back })) do
        local sessions, money, seconds = num(r.sessions), num(r.money), num(r.seconds)
        out[#out + 1] = {
            region = r.region_name, sessions = sessions, money = money,
            avgMoney = sessions > 0 and math.floor(money / sessions) or 0,
            avgDuration = sessions > 0 and math.floor(seconds / sessions) or 0,
            perHour = perHour(money, seconds),
        }
    end
    return out
end

function Stats.job(res, range)
    if not ready() then return nil end
    local w = Stats.window(range)
    local summary
    for _, entry in ipairs(Stats.jobs(range)) do
        if entry.job == res then summary = entry end
    end
    summary = summary or { money = 0, prev = 0, sessions = 0, avgDuration = 0, perHour = 0 }

    local chartRange = range == 'today' and '7d' or range
    local _, history, slot, size = series(chartRange)
    local unit, labels = labelsFor(chartRange)
    local money, sessions = emptySeries(size), emptySeries(size)
    for _, r in ipairs(history) do
        local i = slot(r)
        if i and r.job_id == res then
            money[i] = money[i] + num(r.money)
            sessions[i] = sessions[i] + num(r.sessions)
        end
    end

    local top = collectPlayers(range, nil, res)
    while #top > 10 do table.remove(top) end
    return {
        resource = res,
        kpi = {
            money = { value = summary.money, prev = w.compare and summary.prev or nil },
            sessions = { value = summary.sessions },
            avgDuration = { value = summary.avgDuration },
            perHour = { value = summary.perHour },
        },
        series = { unit = unit, labels = labels, money = money, sessions = sessions },
        regions = Stats.regions(res, range),
        top = top,
    }
end

function Stats.player(identifier, range)
    if not ready() or type(identifier) ~= 'string' or identifier == '' then return nil end
    local w = Stats.window(range)
    local perJob, money, sessions, seconds = {}, 0, 0, 0
    for _, r in ipairs(rows(PLAYER_JOBS, { w.back, '', '', identifier, identifier })) do
        perJob[#perJob + 1] = { job = r.job_id, money = num(r.money), sessions = num(r.sessions) }
        money, sessions, seconds = money + num(r.money), sessions + num(r.sessions), seconds + num(r.seconds)
    end
    table.sort(perJob, function(a, b) return a.money > b.money end)
    local names = rows(PLAYER_NAME, { identifier })[1] or {}
    local xp = rows(PLAYER_XP, { identifier, w.back })[1] or {}
    return {
        identifier = identifier,
        name = names.name,
        altName = names.fivem_name,
        kpi = { money = money, xp = num(xp.xp), sessions = sessions, perHour = perHour(money, seconds) },
        perJob = perJob,
        recent = Stats.ledger({ identifier = identifier, period = 'all', limit = 30 }).rows,
    }
end

local PERIODS = { today = { 0, 1 }, yesterday = { 1, 0 }, ['7d'] = { 6, 1 }, ['30d'] = { 29, 1 }, all = { 36500, 1 } }
local KINDS = { money = true, xp = true, item = true }
local DIRECTIONS = { ['in'] = true, out = true }

function Stats.ledger(filter)
    if not ready() then return { rows = {}, hasMore = false } end
    filter = filter or {}
    local resource = type(filter.resource) == 'string' and filter.resource or ''
    local kind = KINDS[filter.kind] and filter.kind or ''
    local direction = DIRECTIONS[filter.direction] and filter.direction or ''
    local who = type(filter.identifier) == 'string' and filter.identifier or ''
    local period = PERIODS[filter.period] or PERIODS['7d']
    local limit = math.max(1, math.min(200, math.floor(tonumber(filter.limit) or PAGE)))
    local offset = math.max(0, math.floor(tonumber(filter.offset) or 0))
    local like = '%' .. who:gsub('[%%_]', '') .. '%'

    local result = rows(LEDGER_PAGE, { resource, resource, kind, kind, direction, direction, who, who, like,
        period[1], period[2], limit + 1, offset })
    local more = #result > limit
    if more then result[#result] = nil end
    return { rows = result, hasMore = more, offset = offset }
end

function Stats.lobbies()
    local out, quiet = {}, {}
    for _, res in ipairs(TwLib.JobResources and TwLib.JobResources() or {}) do
        local ok, lobbies = pcall(function() return exports[res]:TwLibLobbies() end)
        if ok and type(lobbies) == 'table' then
            for _, l in ipairs(lobbies) do
                local members = {}
                for _, m in ipairs(type(l.members) == 'table' and l.members or {}) do
                    members[#members + 1] = { identifier = tostring(m.identifier or ''), name = m.name and tostring(m.name) or nil, source = tonumber(m.source) }
                end
                out[#out + 1] = {
                    job = res, id = l.id, members = members, players = #members, max = tonumber(l.max),
                    owner = type(l.owner) == 'table' and { identifier = tostring(l.owner.identifier or ''), name = l.owner.name } or nil,
                    region = tostring(l.region or ''), seconds = num(l.seconds), started = l.started == true,
                }
            end
        else
            quiet[#quiet + 1] = res
        end
    end
    return { lobbies = out, quiet = quiet }
end
