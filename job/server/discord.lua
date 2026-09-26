local avatars = {}

function discordloghistoryData(source, data)
    return {
        identifier = GetIdentifier(source),
        avatar = GetDiscordAvatar(source) or Config.ExampleProfilePicture,
        name = GetName(source),
        id = source,
        money = data.money,
        owneridentifier = data.owneridentifier,
    }
end

function DiscordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest(
        "https://discordapp.com/api/" .. endpoint,
        function(errorCode, resultData, resultHeaders)
            data = { data = resultData, code = errorCode, headers = resultHeaders }
        end,
        method,
        #jsondata > 0 and json.encode(jsondata) or "",
        { ["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. (Server.botToken or "") }
    )
    while data == nil do
        Citizen.Wait(0)
    end
    return data
end

function GetDiscordAvatar(user)
    local discordId
    for _, id in ipairs(GetPlayerIdentifiers(user)) do
        if string.match(id, "discord:") then
            discordId = string.gsub(id, "discord:", "")
            break
        end
    end
    if not discordId then return nil end

    local cached = avatars[discordId]
    if cached ~= nil then return cached or nil end

    if (Server.botToken or "") == "" then
        avatars[discordId] = false
        return nil
    end

    local imgURL
    local member = DiscordRequest("GET", ("users/%s"):format(discordId), {})
    if member.code == 200 then
        local data = json.decode(member.data)
        if data ~= nil and data.avatar ~= nil then
            local ext = data.avatar:sub(2, 2) == "_" and ".gif" or ".png"
            imgURL = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. data.avatar .. ext
        end
    end
    avatars[discordId] = imgURL or false
    return imgURL
end

function sendDiscordLogHistory(data)
    if (Server.discordWebhook or "") == "" then return end
    local message = {
        username = Server.botName,
        embeds = {
            {
                title = Server.botName,
                color = 0xFFA500,
                author = { name = ('Tworst  %s - JOB FINISH'):format(base.label or GetCurrentResourceName()) },
                thumbnail = { url = data.avatar },
                fields = {
                    { name = "Player Name", value = tostring(data.name or '-'),            inline = true },
                    { name = "Player ID",   value = tostring(data.id or '-'),              inline = true },
                    { name = "Owner ID",    value = tostring(data.owneridentifier or '-'), inline = true },
                    { name = "──────────Job Information──────────", value = "\u{200B}", inline = false },
                    { name = "Job Price", value = string.format("%s%d", Config.MoneyType, math.floor(tonumber(data.money) or 0)), inline = true },
                },
                footer = {
                    text = "Tworst Store - https://discord.gg/tworst",
                    icon_url = "https://r2.fivemanage.com/biv23I9cFWICSObhZsr4C/LogoNEW.png"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        },
        avatar_url = Server.botLogo
    }
    PerformHttpRequest(Server.discordWebhook, function() end, "POST", json.encode(message),
        { ["Content-Type"] = "application/json" })
end
