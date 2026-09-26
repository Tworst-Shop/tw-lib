nuiLoaded = nuiLoaded or false

function checkNUI()
    while not nuiLoaded do
        Wait(0)
    end
end

local localeKeys
function LocaleText(text)
    if type(text) ~= 'string' or type(Locales) ~= 'table' then return text end
    if not localeKeys then
        localeKeys = {}
        local function index(texts)
            for key, value in pairs(texts) do
                if type(value) == 'string' and localeKeys[value] == nil then localeKeys[value] = key end
            end
        end
        if type(Locales.en) == 'table' then index(Locales.en) end
        for lang, texts in pairs(Locales) do
            if lang ~= 'en' and type(texts) == 'table' then index(texts) end
        end
    end
    local key = localeKeys[text]
    local here = key and type(Locales[Config.Locale]) == 'table' and Locales[Config.Locale][key]
    return type(here) == 'string' and here or text
end

local configLocale = type(Config) == 'table' and Config.Locale
local function relocalize(t, seen)
    seen[t] = true
    for k, v in pairs(t) do
        if type(v) == 'string' then
            if k ~= 'Locale' then t[k] = LocaleText(v) end
        elseif type(v) == 'table' and not seen[v] then
            relocalize(v, seen)
        end
    end
end
function ApplyPlayerLocale()
    if type(Config) ~= 'table' or Config.Locale == configLocale then return end
    configLocale = Config.Locale
    local seen = {}
    for _, texts in pairs(type(Locales) == 'table' and Locales or {}) do seen[texts] = true end
    relocalize(Config, seen)
end

local function localizedTasks(jobTask)
    if type(jobTask) ~= 'table' then return jobTask end
    local out = {}
    for k, v in pairs(jobTask) do out[k] = v end
    for _, list in ipairs({ 'regionJobTask', 'bonusJobTask' }) do
        if type(jobTask[list]) == 'table' then
            out[list] = {}
            for i, task in ipairs(jobTask[list]) do
                local copy = {}
                for k, v in pairs(task) do copy[k] = v end
                copy.jobLabel = LocaleText(task.jobLabel)
                out[list][i] = copy
            end
        end
    end
    return out
end
local LOCALIZE = {
    START_JOB = localizedTasks,
    REFRESH_JOBTASK = localizedTasks,
    NOTIFICATION = function(p)
        return type(p) == 'table' and { message = LocaleText(p.message), type = p.type } or p
    end,
    UPDATE_PROGRESS = function(p)
        if type(p) ~= 'table' then return p end
        local out = {}
        for k, v in pairs(p) do out[k] = v end
        out.label = LocaleText(p.label)
        return out
    end,
}

function NuiMessage(action, payload)
    checkNUI()
    ApplyPlayerLocale()
    if LOCALIZE[action] then payload = LOCALIZE[action](payload) end
    SendNUIMessage({
        action = action,
        payload = payload
    })
    if action == 'LOAD_LOBBY' then
        local room = CoopDataClient and CoopDataClient.roomSetting
        SendNUIMessage({ action = 'REWARD_SPLIT_ENABLED', payload = Config and Config.LetOwnerSplitRewards == true or false })
        SendNUIMessage({ action = 'LOBBY_REWARDS', payload = room and room.rewardSplit or {} })
    end
end

CreateThread(function()
    while not nuiLoaded do
        if NetworkIsSessionStarted() then
            SendNUIMessage({ action = "CHECK_NUI" })
        end
        Wait(2000)
    end
end)

RegisterNUICallback("checkNUI", function(data, cb)
    nuiLoaded = true
    cb("ok")
    SendNUIMessage({ action = 'LEADERBOARD_ENABLED', payload = not (Config and Config.Leaderboard and Config.Leaderboard.enabled == false) })
end)

RegisterNUICallback("getLeaderboard", function(data, cb)
    cb("ok")
    NuiMessage('LOAD_LEADERBOARD', TriggerServerCallback(_event('server:getLeaderboard')) or {})
end)

local HINT_MS, VK_ENTER, VK_DELETE = 15000, 13, 46
local hintQueue, hintActive, hintAsked = {}, nil, {}

local function keyDown(code)
    local down = IsRawKeyPressed(code)
    return down == true or down == 1
end

local function showNextHint()
    if hintActive or #hintQueue == 0 then return end
    local card = table.remove(hintQueue, 1)
    hintActive = card
    local L = Locales and Config and Locales[Config.Locale] or {}
    NuiMessage('HINT_CARD_SHOW', { title = card.title, body = card.body,
        closeLabel = L['hint_close'] or 'Close', neverLabel = L['hint_never'] or "Don't show again" })
    CreateThread(function()
        local untilAt = GetGameTimer() + HINT_MS
        while hintActive == card do
            if GetGameTimer() >= untilAt or keyDown(VK_ENTER) then break end
            if keyDown(VK_DELETE) then
                TriggerServerEvent(_event('server:setHintSeen'), card.key)
                break
            end
            Wait(0)
        end
        NuiMessage('HINT_CARD_HIDE')
        hintActive = nil
        Wait(400)
        showNextHint()
    end)
end

function HintCard(key, title, body)
    if type(key) ~= 'string' or hintAsked[key] then return end
    hintAsked[key] = true
    CreateThread(function()
        if TriggerServerCallback(_event('server:getHintSeen'), key) == true then return end
        hintQueue[#hintQueue + 1] = { key = key, title = title, body = body }
        showNextHint()
    end)
end

function TutorialTip(prefix, step)
    local here, en = Locales and Locales[Config.Locale] or {}, Locales and Locales['en'] or {}
    local body = here['tutorialDescription' .. step] or en['tutorialDescription' .. step]
    if body then HintCard(prefix .. step, here['tutorialTitle' .. step] or en['tutorialTitle' .. step] or '', body) end
end

function TutorialTipForPrompt(text, prefix, labelSteps)
    local here, en = Locales and Locales[Config.Locale] or {}, Locales and Locales['en'] or {}
    local best, bestLen = nil, 0
    for key, step in pairs(labelSteps) do
        local label = here[key] or en[key]
        if type(label) == 'string' and #label > bestLen and text:find(label, 1, true) then best, bestLen = step, #label end
    end
    if best then TutorialTip(prefix, best) end
end

local promptsSeen = {}
function JobPromptShown(text)
    if type(text) ~= 'string' or promptsSeen[text] then return end
    promptsSeen[text] = true
    if JobPromptTip then pcall(JobPromptTip, text) end
end

CreateThread(function()
    Wait(500)
    local notify = type(Config) == 'table' and Config.sendNotification
    if type(notify) == 'function' then
        Config.sendNotification = function(message, ...)
            ApplyPlayerLocale()
            return notify(LocaleText(message), ...)
        end
    end
    local draw3d = DrawText3D
    if type(draw3d) ~= 'function' then return end
    DrawText3D = function(x, y, z, text, ...)
        if type(text) == 'string' and text:find('%[%w+%]') then JobPromptShown(text) end
        return draw3d(x, y, z, text, ...)
    end
end)
