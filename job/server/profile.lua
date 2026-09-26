playerJobData = playerJobData or {}

local RETIRED_POSITIONS = { inviteSide = { top = '90.07vh', left = '50.07vw' } }
local function currentPositions(settings)
    local saved = type(settings) == 'table' and settings.uiPositions
    local defaults = Config.DefaultUIPositions
    if type(saved) ~= 'table' or type(defaults) ~= 'table' then return settings end
    for part, old in pairs(RETIRED_POSITIONS) do
        local at = saved[part]
        if type(at) == 'table' and at.top == old.top and at.left == old.left and defaults[part] then
            saved[part] = defaults[part]
        end
    end
    return settings
end

local function readProfile(identifier)
    local row = (ExecuteSql("SELECT * FROM `" .. base.SQLName .. "` WHERE identifier = @identifier",
        { identifier = identifier }) or {})[1]
    if not row then return nil end
    local data = {
        profiledata = json.decode(row.profiledata or 'null'),
        dailymission = json.decode(row.dailymission or 'null'),
        tutorial = json.decode(row.tutorial or 'null'),
        history = json.decode(row.history or '[]'),
        uisettings = currentPositions(json.decode(row.uisettings or 'null')),
    }
    for _, column in ipairs(base.profileColumns or {}) do
        data[column] = json.decode(row[column] or 'null')
    end
    return data
end

RegisterServerEvent(_event(base.loadDataEvent or 'server:loadData'), function()
    local src = source
    while not SQLChecker do Wait(100) end
    local tries = 0
    while tries < 150 and not GetIdentifier(src) do
        Wait(100)
        tries = tries + 1
    end
    loadJobData(src)
end)

if GetResourceState('vrp') == 'started' then
    local loaded = {}

    local function vrpLoad(src)
        src = tonumber(src)
        if not src or src == 0 or loaded[src] then return end
        loaded[src] = true
        while not SQLChecker do Wait(100) end
        loadJobData(src)
    end

    AddEventHandler('vRP:playerSpawn', function(user_id, src) vrpLoad(src) end)
    AddEventHandler('vRP:playerJoin', function(user_id, src) vrpLoad(src) end)
    AddEventHandler('vRP:playerRejoin', function(user_id, src) vrpLoad(src) end)
    AddEventHandler('vRP:Active', function(user_id, src) vrpLoad(src or source) end)
    AddEventHandler('vRP:playerLeave', function(user_id, src) if src then loaded[tonumber(src)] = nil end end)
    AddEventHandler('playerDropped', function() loaded[source] = nil end)

    CreateThread(function()
        while not SQLChecker do Wait(100) end
        Wait(1500)
        for _, id in ipairs(GetPlayers()) do
            if GetIdentifier(tonumber(id)) then vrpLoad(id) end
        end
    end)
end

local DAILY_TASKS = { 'jobtask_one', 'jobtask_two', 'jobtask_three', 'jobtask_four', 'jobtask_five' }

function newDailyMission()
    local daily = { timestamp = os.time(), remainingtime = 24 }
    for _, name in ipairs(DAILY_TASKS) do daily[name] = { complete = false, count = 0 } end
    return daily
end

local function newTutorial()
    return {
        ['tutorial_one'] = false,
        ['tutorial_two'] = false,
        ['tutorial_three'] = false,
        ['tutorial_four'] = false,
        ['tutorial_five'] = false,
        ['tutorial_six'] = false,
    }
end

function newUISettings()
    return { uiPositions = Config.DefaultUIPositions, locale = Config.Locale, soundEffect = true }
end

function checkAndResetTimestamp(timestamp)
    local resetTime = timestamp + (24 * 60 * 60)
    local currentTime = os.time()
    return currentTime > resetTime, (resetTime - currentTime) / (60 * 60)
end

function checkTime(source)
    local src = source
    local data = playerJobData[GetIdentifier(src)]
    if not data then return end
    local dailymission = data.dailymission or newDailyMission()
    local resetRequired, remaining = checkAndResetTimestamp(dailymission.timestamp or 0)
    if resetRequired then
        Citizen.Wait(500)
        dailymission.timestamp = os.time()
        for _, name in ipairs(DAILY_TASKS) do
            dailymission[name] = { complete = false, count = 0 }
        end
        dailymission.remainingtime = 24
        data.dailymission = dailymission
        savePlayerData(src)
    else
        dailymission.remainingtime = remaining
    end
    return dailymission
end

function loadJobData(src)
    local identifier = GetIdentifier(src)
    if not identifier then
        print("^1[ERROR]^0 GetIdentifier returned nil for source: " .. tostring(src))
        return
    end

    local data = playerJobData[identifier] or readProfile(identifier)
    if not data or not data.profiledata then
        playerJobData[identifier] = nil
        firstData(src, function()
            data = playerJobData[identifier]
        end)
    end

    if not data then
        print("^1[ERROR]^0 Failed to load or create data for identifier: " .. tostring(identifier))
        return
    end

    data.source = src
    data.profiledata.avatar = GetDiscordAvatar(src) or Config.ExampleProfilePicture
    data.profiledata.name = GetName(src)
    data.profiledata.identifier = identifier
    data.profiledata.lasttime = data.profiledata.lasttime or 0
    data.dailymission = data.dailymission or newDailyMission()
    data.tutorial = data.tutorial or newTutorial()
    data.history = data.history or {}
    data.uisettings = data.uisettings or newUISettings()
    for _, column in ipairs(base.profileColumns or {}) do
        data[column] = data[column] or {}
    end
    playerJobData[identifier] = data
    if restoreLobbySeat then restoreLobbySeat(src, identifier) end
    Citizen.Wait(100)
    savePlayerData(src)
end

function firstData(src, callback)
    local identifier = GetIdentifier(src)
    if not identifier then
        print("^1[ERROR]^0 GetIdentifier returned nil for source: " .. tostring(src))
        return
    end
    if playerJobData[identifier] then
        return
    end

    playerJobData[identifier] = {}

    local dataInfo = {
        identifier = identifier,
        profiledata = {
            ["xp"] = 0,
            ["level"] = 1,
            ['avatar'] = GetDiscordAvatar(src) or Config.ExampleProfilePicture,
            ['name'] = GetName(src),
            ['identifier'] = identifier,
            ['lasttime'] = 0,
        },
        dailymission = newDailyMission(),
        tutorial = newTutorial(),
        history = {},
        uisettings = newUISettings(),
    }
    for _, column in ipairs(base.profileColumns or {}) do
        dataInfo[column] = {}
    end
    Citizen.Wait(100)
    playerJobData[identifier] = dataInfo

    ExecuteSql(
        'INSERT INTO ' .. base.SQLName .. ' (identifier, profiledata, dailymission, tutorial, history, uisettings) ' ..
        'VALUES (:identifier, :profiledata, :dailymission, :tutorial, :history, :uisettings) ' ..
        'ON DUPLICATE KEY UPDATE ' ..
        'profiledata = VALUES(profiledata), ' ..
        'dailymission = VALUES(dailymission), ' ..
        'tutorial = VALUES(tutorial), ' ..
        'history = VALUES(history), ' ..
        'uisettings = VALUES(uisettings)',
        {
            identifier = identifier,
            profiledata = json.encode(dataInfo.profiledata),
            dailymission = json.encode(dataInfo.dailymission),
            tutorial = json.encode(dataInfo.tutorial),
            history = json.encode(dataInfo.history),
            uisettings = json.encode(dataInfo.uisettings),
        }
    )

    callback()
end

function savePlayerData(src)
    local identifier = GetIdentifier(src)
    local data = playerJobData[identifier]
    if not data or not data.profiledata then
        return
    end
    if type(data.history) == 'table' then
        while #data.history > 10 do table.remove(data.history, 1) end
    end
    local extra, params = '', {
        identifier = identifier,
        profiledata = json.encode(data.profiledata),
        dailymission = json.encode(data.dailymission),
        tutorial = json.encode(data.tutorial),
        history = json.encode(data.history or {}),
        uisettings = json.encode(data.uisettings),
    }
    for _, column in ipairs(base.profileColumns or {}) do
        extra = extra .. (', %s = @%s'):format(column, column)
        params[column] = json.encode(data[column] or {})
    end
    ExecuteSql(
        'UPDATE ' .. base.SQLName ..
        ' SET profiledata = @profiledata, dailymission = @dailymission, tutorial = @tutorial, history = @history, uisettings = @uisettings' ..
        extra .. ' WHERE identifier = @identifier', params)
end

RegisterServerCallback(_event('server:getUISettings'), function(source, cb)
    local data = playerJobData[GetIdentifier(source)]
    if not (data and data.profiledata) then return cb(newUISettings()) end
    data.uisettings = data.uisettings or newUISettings()
    cb(data.uisettings)
end)

RegisterServerCallback(_event('server:getPlayerData'), function(source, cb)
    local src = source
    local identifier = GetIdentifier(src)
    local data = playerJobData[identifier]
    local tries = 0
    while not (data and data.profiledata and data.uisettings) and tries < 30 do
        Wait(500)
        tries = tries + 1
        data = playerJobData[identifier]
    end
    if not (data and data.profiledata) then return cb(false) end

    local time = checkTime(src)
    if time then data.dailymission = time end

    cb({
        playerMoney = GetPlayerMoney(src, Config.MoneyType2),
        playerName = data.profiledata.name,
        playerIdentifier = data.profiledata.identifier,
        playerImage = data.profiledata.avatar or Config.ExampleProfilePicture,
        playerLevel = data.profiledata.level or 0,
        playerXp = data.profiledata.xp,
        playerNextXp = Config.RequiredXP[data.profiledata.level or 1] or 0,
        source = src,
        dailymission = data.dailymission,
        locale = data.uisettings.locale or Config.Locale,
        otherJob = OtherJobPrompt and OtherJobPrompt(src, data.uisettings.locale or Config.Locale) or nil,
        soundEffect = data.uisettings.soundEffect ~= false,
    })
end)

RegisterServerCallback(_event('server:getHistoryData'), function(source, cb)
    local data = playerJobData[GetIdentifier(source)]
    cb(data and data.history or {})
end)

RegisterServerCallback(_event('server:getTutorial'), function(source, cb, name)
    local identifier = GetIdentifier(source)
    local data = playerJobData[identifier]
    if not (data and data.tutorial and type(name) == 'string' and data.tutorial[name] ~= nil) then return cb(false) end
    local seen = data.tutorial[name]
    if not seen then
        SetTimeout(1500, function()
            data.tutorial[name] = true
            ExecuteSql('UPDATE ' .. base.SQLName .. ' SET tutorial = @tutorial WHERE identifier = @identifier',
                { identifier = identifier, tutorial = json.encode(data.tutorial) })
        end)
    end
    cb(seen)
end)

RegisterServerEvent(_event('server:saveUISettings'), function(settings)
    local src = source
    local identifier = GetIdentifier(src)
    local data = identifier and playerJobData[identifier]
    if not (data and data.profiledata) then return end
    settings = type(settings) == 'table' and settings or {}
    local current = data.uisettings or newUISettings()
    data.uisettings = {
        uiPositions = type(settings.uiPositions) == 'table' and settings.uiPositions or current.uiPositions,
        locale = type(settings.locale) == 'string' and Locales[settings.locale] and settings.locale or current.locale,
        soundEffect = settings.soundEffect ~= false,
    }
    savePlayerData(src)
    TriggerClientEvent(_event('client:saveUISettings'), src)
    local saved = Config.NotificationText and Config.NotificationText['settingssaved']
    if saved then
        TriggerClientEvent(_event('client:sendNotification'), src, saved.text, saved.type)
    end
end)

local LEADERBOARD_TOP = 'SELECT h.`identifier`, COALESCE(SUM(h.`earned_money`), 0) AS money, COUNT(*) AS jobs, ' ..
    'MAX(p.`name`) AS name FROM `tw_lib_job_history` h LEFT JOIN `tw_lib_players` p ON p.`identifier` = h.`identifier` ' ..
    'WHERE h.`job_id` = ? GROUP BY h.`identifier` HAVING money >= ? ORDER BY %s DESC LIMIT %d'
local leaderboardCache = { at = 0, rows = nil }

function getLeaderboard()
    local cfg = Config.Leaderboard or {}
    if cfg.enabled == false then return {} end
    local ttl = math.max(0, tonumber(cfg.cacheSeconds) or 60) * 1000
    if leaderboardCache.rows and GetGameTimer() - leaderboardCache.at < ttl then return leaderboardCache.rows end

    local limit = math.floor(math.max(1, math.min(50, tonumber(cfg.limit) or 10)))
    local minMoney = math.max(0, tonumber(cfg.minMoney) or 1)
    local job, rows, seen = GetCurrentResourceName(), {}, {}
    for _, order in ipairs({ 'money', 'jobs' }) do
        for _, r in ipairs(ExecuteSql(LEADERBOARD_TOP:format(order, limit), { job, minMoney }) or {}) do
            if r.identifier and not seen[r.identifier] then
                seen[r.identifier] = true
                rows[#rows + 1] = { playerIdentifier = r.identifier, playerName = r.name or 'Unknown', playerLevel = 1,
                    playerImage = Config.ExampleProfilePicture, moneyEarned = tonumber(r.money) or 0,
                    tasksDone = tonumber(r.jobs) or 0 }
            end
        end
    end

    if #rows > 0 then
        local ids = {}
        for i, row in ipairs(rows) do ids[i] = row.playerIdentifier end
        local byId = {}
        for _, row in ipairs(rows) do byId[row.playerIdentifier] = row end
        local found = ExecuteSql('SELECT `identifier`, `profiledata` FROM `' .. base.SQLName .. '` WHERE `identifier` IN (' ..
            ('?,'):rep(#ids):sub(1, -2) .. ')', ids) or {}
        for _, p in ipairs(found) do
            local ok, pd = pcall(json.decode, p.profiledata or 'null')
            local row = byId[p.identifier]
            if row and ok and type(pd) == 'table' then
                row.playerName = pd.name or row.playerName
                row.playerLevel = tonumber(pd.level) or row.playerLevel
                row.playerImage = pd.avatar or row.playerImage
            end
        end
    end

    leaderboardCache.rows, leaderboardCache.at = rows, GetGameTimer()
    return rows
end

RegisterServerCallback(_event('server:getLeaderboard'), function(source, cb)
    cb(getLeaderboard())
end)

local function hintKey(key)
    return type(key) == 'string' and #key <= 48 and key:match('^[%w_]+$') ~= nil
end

RegisterServerCallback(_event('server:getHintSeen'), function(source, cb, key)
    local data = playerJobData[GetIdentifier(source)]
    local hints = data and type(data.tutorial) == 'table' and data.tutorial.hints
    cb(hintKey(key) and type(hints) == 'table' and hints[key] == true or false)
end)

RegisterServerEvent(_event('server:setHintSeen'), function(key)
    local identifier = GetIdentifier(source)
    local data = identifier and playerJobData[identifier]
    if not (data and hintKey(key)) then return end
    data.tutorial = type(data.tutorial) == 'table' and data.tutorial or newTutorial()
    data.tutorial.hints = type(data.tutorial.hints) == 'table' and data.tutorial.hints or {}
    if data.tutorial.hints[key] then return end
    local kept = 0
    for _ in pairs(data.tutorial.hints) do kept = kept + 1 end
    if kept >= 64 then return end
    data.tutorial.hints[key] = true
    ExecuteSql('UPDATE ' .. base.SQLName .. ' SET tutorial = @tutorial WHERE identifier = @identifier',
        { identifier = identifier, tutorial = json.encode(data.tutorial) })
end)
