coopData = coopData or {}
JoobTask = JoobTask or {}
cooldowns = cooldowns or {}

local KIT_NOTICES = {
    playeralreadyinvited = { type = 'error', en = 'This player already has an open invite.',
        tr = 'Bu oyuncunun zaten bekleyen bir daveti var.', de = 'Dieser Spieler hat bereits eine offene Einladung.',
        fr = 'Ce joueur a déjà une invitation en attente.', pt = 'Este jogador já tem um convite pendente.',
        ru = 'У этого игрока уже есть активное приглашение.', ar = 'لدى هذا اللاعب دعوة معلقة بالفعل.',
        es = 'Este jugador ya tiene una invitación pendiente.', hu = 'Ennek a játékosnak már van függőben lévő meghívása.', ja = 'このプレイヤーには保留中の招待がすでにあります。', nl = 'Deze speler heeft al een openstaande uitnodiging.', ro = 'Acest jucător are deja o invitație în așteptare.', sv = 'Den här spelaren har redan en öppen inbjudan.' },
    isownernotleave = { type = 'error', en = 'The lobby owner cannot leave the job.',
        tr = 'Lobi sahibi işten ayrılamaz.', de = 'Der Lobby-Besitzer kann den Job nicht verlassen.',
        fr = 'Le propriétaire du lobby ne peut pas quitter le travail.', pt = 'O dono do lobby não pode sair do trabalho.',
        ru = 'Владелец лобби не может покинуть работу.', ar = 'لا يمكن لمالك الردهة مغادرة العمل.',
        es = 'El dueño del lobby no puede abandonar el trabajo.', hu = 'A lobby tulajdonosa nem hagyhatja el a munkát.', ja = 'ロビーのオーナーは仕事から抜けられません。', nl = 'De eigenaar van de lobby kan de job niet verlaten.', ro = 'Proprietarul lobby-ului nu poate părăsi munca.', sv = 'Lobbyns ägare kan inte lämna jobbet.' },
    ownerchanged = { type = 'info', en = 'The lobby owner left. The crew goes on with a new owner.',
        tr = 'Lobi sahibi ayrıldı. Ekip yeni sahiple devam ediyor.', de = 'Der Lobby-Besitzer ist gegangen. Die Crew macht mit einem neuen Besitzer weiter.',
        fr = "Le propriétaire du lobby est parti. L'équipe continue avec un nouveau propriétaire.",
        pt = 'O dono do lobby saiu. A equipe continua com um novo dono.',
        ru = 'Владелец лобби вышел. Команда продолжает с новым владельцем.', ar = 'غادر مالك الردهة. يواصل الفريق مع مالك جديد.',
        es = 'El dueño del lobby se fue. El equipo sigue con un nuevo dueño.', hu = 'A lobby tulajdonosa kilépett. A csapat új tulajdonossal folytatja.', ja = 'ロビーのオーナーが退出しました。クルーは新しいオーナーで続行します。', nl = 'De eigenaar van de lobby is vertrokken. De crew gaat verder met een nieuwe eigenaar.', ro = 'Proprietarul lobby-ului a plecat. Echipa continuă cu un nou proprietar.', sv = 'Lobbyns ägare lämnade. Crewen fortsätter med en ny ägare.' },
    previouscrew = { type = 'error', en = 'Your previous crew is still working. You can open a lobby of your own when it is done.',
        tr = 'Önceki ekibin hâlâ çalışıyor. O bitince kendi lobini açabilirsin.',
        de = 'Deine vorherige Crew arbeitet noch. Du kannst eine eigene Lobby öffnen, wenn sie fertig ist.',
        fr = "Ton ancienne équipe travaille encore. Tu pourras ouvrir ton propre lobby quand elle aura fini.",
        pt = 'Sua equipe anterior ainda está trabalhando. Você pode abrir seu próprio lobby quando ela terminar.',
        ru = 'Твоя прежняя команда ещё работает. Ты сможешь открыть своё лобби, когда она закончит.',
        ar = 'فريقك السابق لا يزال يعمل. يمكنك فتح ردهتك الخاصة عندما ينتهي.',
        es = 'Tu equipo anterior sigue trabajando. Podrás abrir tu propio lobby cuando termine.', hu = 'Az előző csapatod még dolgozik. Ha végeztek, nyithatsz saját lobbyt.', ja = '前のクルーがまだ作業中です。終わったら自分のロビーを開けます。', nl = 'Je vorige crew is nog aan het werk. Je kunt je eigen lobby openen als die klaar is.', ro = 'Echipa ta anterioară încă lucrează. Îți poți deschide propriul lobby când termină.', sv = 'Din tidigare crew jobbar fortfarande. Du kan öppna en egen lobby när den är klar.' },
    inviteexpired = { type = 'error', en = 'This invite is no longer valid.',
        tr = 'Bu davet artık geçerli değil.', de = 'Diese Einladung ist nicht mehr gültig.',
        fr = "Cette invitation n'est plus valide.", pt = 'Este convite não é mais válido.',
        ru = 'Это приглашение больше недействительно.', ar = 'هذه الدعوة لم تعد صالحة.',
        es = 'Esta invitación ya no es válida.', hu = 'Ez a meghívás már nem érvényes.', ja = 'この招待はもう無効です。', nl = 'Deze uitnodiging is niet meer geldig.', ro = 'Această invitație nu mai este valabilă.', sv = 'Den här inbjudan gäller inte längre.' },
    otherjob = { type = 'error', en = 'You are already working in another job. Leave it first.',
        tr = 'Zaten başka bir işte çalışıyorsun. Önce ondan ayrıl.', de = 'Du arbeitest bereits in einem anderen Job. Verlasse ihn zuerst.',
        fr = "Tu travailles déjà dans un autre job. Quitte-le d'abord.", pt = 'Você já está trabalhando em outro emprego. Saia dele primeiro.',
        ru = 'Ты уже работаешь на другой работе. Сначала покинь её.', ar = 'أنت تعمل بالفعل في وظيفة أخرى. غادرها أولاً.',
        es = 'Ya estás trabajando en otro trabajo. Déjalo primero.', hu = 'Már egy másik munkán dolgozol. Előbb lépj ki belőle.', ja = 'すでに別の仕事をしています。先にそちらを抜けてください。', nl = 'Je werkt al in een andere job. Verlaat die eerst.', ro = 'Lucrezi deja la o altă muncă. Părăsește-o mai întâi.', sv = 'Du jobbar redan på ett annat jobb. Lämna det först.' },
    otherjobmenu = { en = 'You are working in %s. Leave that job to start one here.',
        tr = 'Şu an %s işindesin. Burada iş başlatmak için o işten ayrıl.', de = 'Du arbeitest gerade bei %s. Verlasse diesen Job, um hier einen zu starten.',
        fr = 'Tu travailles actuellement dans %s. Quitte ce job pour en commencer un ici.', pt = 'Você está trabalhando em %s. Saia desse emprego para começar um aqui.',
        ru = 'Сейчас ты работаешь в %s. Покинь эту работу, чтобы начать здесь.', ar = 'أنت تعمل حالياً في %s. غادر تلك الوظيفة لتبدأ هنا.',
        es = 'Estás trabajando en %s. Deja ese trabajo para empezar uno aquí.', hu = 'Jelenleg itt dolgozol: %s. Lépj ki abból a munkából, hogy itt kezdhess egyet.', ja = '現在 %s で作業中です。ここで始めるにはその仕事を抜けてください。', nl = 'Je werkt nu bij %s. Verlaat die job om hier een te starten.', ro = 'Lucrezi acum la %s. Părăsește acea muncă pentru a începe una aici.', sv = 'Du jobbar just nu på %s. Lämna det jobbet för att starta ett här.' },
    otherjobleave = { en = 'Leave %s', tr = '%s işinden ayrıl', de = '%s verlassen', fr = 'Quitter %s', pt = 'Sair de %s',
        ru = 'Покинуть %s', ar = 'مغادرة %s',
        es = 'Dejar %s', hu = '%s elhagyása', ja = '%s を抜ける', nl = '%s verlaten', ro = 'Părăsește %s', sv = 'Lämna %s' },
    otherjobclose = { en = 'Close', tr = 'Kapat', de = 'Schließen', fr = 'Fermer', pt = 'Fechar', ru = 'Закрыть', ar = 'إغلاق',
        es = 'Cerrar', hu = 'Bezárás', ja = '閉じる', nl = 'Sluiten', ro = 'Închide', sv = 'Stäng' },
    inventoryfull = { type = 'error', en = 'There is no room for that in your inventory. Nothing was taken.',
        tr = 'Envanterinde buna yer yok. Hiçbir şey alınmadı.', de = 'In deinem Inventar ist dafür kein Platz. Es wurde nichts abgezogen.',
        fr = "Pas de place dans ton inventaire. Rien n'a été retiré.", pt = 'Não há espaço no seu inventário. Nada foi cobrado.',
        ru = 'В инвентаре нет места. Ничего не списано.', ar = 'لا توجد مساحة في مخزونك. لم يُخصم شيء.',
        es = 'No hay espacio para eso en tu inventario. No se cobró nada.', hu = 'Nincs ehhez hely a leltáradban. Semmit sem vontunk le.', ja = 'インベントリに空きがありません。何も差し引かれていません。', nl = 'Er is geen ruimte voor in je inventaris. Er is niets afgeschreven.', ro = 'Nu ai loc pentru asta în inventar. Nu s-a luat nimic.', sv = 'Det finns ingen plats för det i ditt förråd. Inget drogs av.' },
    toofar = { type = 'error', en = 'You are too far away for that.', tr = 'Bunun için çok uzaktasın.',
        de = 'Dafür bist du zu weit weg.', fr = 'Tu es trop loin pour ça.', pt = 'Você está longe demais para isso.',
        ru = 'Ты слишком далеко для этого.', ar = 'أنت بعيد جداً للقيام بذلك.',
        es = 'Estás demasiado lejos para eso.', hu = 'Ehhez túl messze vagy.', ja = 'それには遠すぎます。', nl = 'Je bent daarvoor te ver weg.', ro = 'Ești prea departe pentru asta.', sv = 'Du är för långt bort för det.' },
}

function KitText(key)
    local n = KIT_NOTICES[key]
    return n and (n[Config.Locale] or n.en) or key
end

local function otherJob(src)
    local ok, name = pcall(function() return exports['tw-lib']:OtherJob(src) end)
    return ok and type(name) == 'string' and name or nil
end

function OtherJobPrompt(src, locale)
    local name = otherJob(src)
    if not name then return nil end
    local function text(key)
        local n = KIT_NOTICES[key]
        return (n[locale] or n.en):format(name)
    end
    return { name = name, text = text('otherjobmenu'), leave = text('otherjobleave'), close = text('otherjobclose') }
end

function notify(src, key)
    local n = Config.NotificationText and Config.NotificationText[key]
    local kit = not n and KIT_NOTICES[key]
    if kit then n = { text = kit[Config.Locale] or kit.en, type = kit.type } end
    if n then TriggerClientEvent(_event('client:sendNotification'), src, n.text, n.type) end
end

function memberLobby(src, owneridentifier)
    local lobby = owneridentifier and coopData[owneridentifier]
    if not lobby then return nil end
    for _, player in ipairs(lobby.players) do
        if player.source == src and not player.offline then return lobby end
    end
    return nil
end

function isLobbyOwner(src, lobby)
    for _, player in ipairs(lobby and lobby.players or {}) do
        if player.playerOwner then return player.source == src and not player.offline end
    end
    return false
end

function playerLobbyOwner(src)
    for owner, lobby in pairs(coopData) do
        for _, player in ipairs(lobby.players or {}) do
            if player.source == src and not player.offline then return owner end
        end
    end
    return nil
end

function jobLobby(src, owneridentifier)
    local lobby = memberLobby(src, owneridentifier)
    return lobby and JoobTask[owneridentifier] and not lobby.roomSetting.paying and lobby or nil
end

function LobbyRewardSplit(lobby)
    local stored = lobby and lobby.roomSetting and lobby.roomSetting.rewardSplit
    if Config.LetOwnerSplitRewards ~= true or type(stored) ~= 'table' then return nil end
    local sum = 0
    for _, player in ipairs(lobby.players or {}) do
        local pct = tonumber(stored[tostring(player.playerIdentifier)])
        if not pct then return nil end
        sum = sum + pct
    end
    return sum > 0 and sum <= 100 and stored or nil
end

function LobbyRewardFor(lobby, identifier, perPlayer)
    perPlayer = tonumber(perPlayer) or 0
    local split = LobbyRewardSplit(lobby)
    if not split or perPlayer <= 0 then return perPlayer end
    local paid, sum = 0, 0
    for _, player in ipairs(lobby.players) do
        if not player.offline and GetIdentifier(player.source) == player.playerIdentifier then
            paid, sum = paid + 1, sum + split[tostring(player.playerIdentifier)]
        end
    end
    if sum <= 0 then return perPlayer end
    return math.floor(perPlayer * paid * (split[tostring(identifier)] or 0) / sum)
end

function LobbyRewardResult(lobby, identifier, result)
    local reward = tonumber(result.historyRewardMoney) or 0
    local money = LobbyRewardFor(lobby, identifier, reward)
    if money == reward then return result, money end
    local own = TwLib.Merge.copy(result)
    local bonus = reward > 0 and math.floor((tonumber(result.historyBonusMoney) or 0) * money / reward) or 0
    own.historyRewardMoney, own.historyBonusMoney, own.historyTotalMoney = money, bonus, money - bonus
    return own, money
end

RegisterServerEvent(_event('server:updateRewardSplit'), function(split)
    local src = source
    local owner = playerLobbyOwner(src)
    local lobby = owner and coopData[owner]
    if Config.LetOwnerSplitRewards ~= true or not lobby or not isLobbyOwner(src, lobby)
        or lobby.roomSetting.startJob or lobby.roomSetting.finishJob then return end
    local clean, sum = {}, 0
    for _, player in ipairs(lobby.players) do
        local pct = type(split) == 'table' and tonumber(split[tostring(player.playerIdentifier)])
        if not pct or pct < 0 or pct > 100 or pct % 1 ~= 0 then
            return TriggerClientEvent(_event('client:RefreshPlayers'), src, lobby)
        end
        clean[tostring(player.playerIdentifier)], sum = pct, sum + pct
    end
    if sum ~= 100 then return TriggerClientEvent(_event('client:RefreshPlayers'), src, lobby) end
    lobby.roomSetting.rewardSplit = clean
    for _, player in ipairs(lobby.players) do
        if not player.offline then TriggerClientEvent(_event('client:RefreshPlayers'), player.source, lobby) end
    end
end)

function inAnyLobby(identifier, except)
    for owner, lobby in pairs(coopData) do
        if owner ~= except then
            for _, player in ipairs(lobby.players or {}) do
                if player.playerIdentifier == identifier then return true end
            end
        end
    end
    return false
end

function removeMember(lobby, owneridentifier, identifier, src)
    local removed = false
    for i, player in ipairs(lobby.players) do
        if player.playerIdentifier == identifier then
            table.remove(lobby.players, i)
            removed = true
            break
        end
    end
    local jobTask = JoobTask[owneridentifier]
    if jobTask then
        for i, player in ipairs(jobTask.Players) do
            if player.playerIdentifier == identifier then
                table.remove(jobTask.Players, i)
                break
            end
        end
    end
    if OnLobbyMemberRemoved then OnLobbyMemberRemoved(lobby, owneridentifier, identifier, src) end
    return removed
end

function CalculateTeamMoney(baseMoney, playerCount, multiplier)
    if playerCount <= 1 then
        return baseMoney
    end
    if multiplier > 0 then
        return math.ceil(baseMoney * multiplier)
    elseif multiplier < 0 then
        return math.ceil(baseMoney / (math.abs(multiplier) * playerCount))
    else
        return math.ceil(baseMoney / playerCount)
    end
end

function RecalculateAwards(lobby)
    local mission = lobby and lobby.roomSetting and lobby.roomSetting.Mission
    if not (mission and mission.regionAwards) then return end
    local awards = mission.regionAwards
    awards.newMoney = CalculateTeamMoney(awards.money, #lobby.players, awards.onlineJobExtraAwards)
end

function LobbyRegion(data)
    return ConfigRegion(Config.Job and Config.Job['regionData'], 'regionID', type(data) == 'table' and data.regionID)
end

function refreshLobby(lobby)
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent(_event('client:RefreshLobby'), player.source, lobby)
    end
end

RegisterServerCallback(_event('server:getNearbyPlayers'), function(source, cb, playerId)
    local data = playerJobData[GetIdentifier(tonumber(playerId))]
    local profile = data and data.profiledata
    if not profile then return cb(false) end
    cb({ profiledata = { name = profile.name, level = profile.level, avatar = profile.avatar } })
end)

function LobbyOnCooldown(lobby)
    local seconds = (tonumber(Config.jobCoolDownHours) or 0) * 3600
    if seconds <= 0 then return false end
    for _, player in ipairs(lobby.players or {}) do
        local data = playerJobData[player.playerIdentifier]
        local last = data and data.profiledata and data.profiledata.lasttime
        if type(last) == 'string' and #last >= 19 and os.difftime(os.time(), os.time({
                year = tonumber(last:sub(1, 4)), month = tonumber(last:sub(6, 7)), day = tonumber(last:sub(9, 10)),
                hour = tonumber(last:sub(12, 13)), min = tonumber(last:sub(15, 16)), sec = tonumber(last:sub(18, 19)),
            })) < seconds then
            return true
        end
    end
    return false
end

function JobAllowed(src)
    local rule
    for _, root in ipairs({ Config.Job, Config.Diving, Config.Fashion, Config.Gardenerv2 }) do
        if type(root) == 'table' and root.job ~= nil then rule = root.job break end
    end
    if rule == nil or rule == false or rule == 'all' then return true end
    local ok, job = pcall(function() return exports['tw-lib']:GetPlayerJob(src) end)
    if not ok or type(job) ~= 'table' then return true end
    if type(rule) == 'table' then
        for _, name in ipairs(rule) do
            if name == 'all' or name == job.name then return true end
        end
        return false
    end
    return rule == job.name
end

RegisterServerCallback(_event('server:CreatePlayerLobby'), function(source, cb)
    local src = source
    local identifier = GetIdentifier(src)
    local data = playerJobData[identifier]
    if not (data and data.profiledata) then
        return cb(false)
    end
    if not JobAllowed(src) then
        notify(src, 'wrongjob')
        return cb(false)
    end
    if not playerLobbyOwner(src) and otherJob(src) then return cb(false) end

    if not simulatedAway[identifier] then restoreLobbySeat(src, identifier) end
    local owner = playerLobbyOwner(src)
    if owner and owner ~= identifier then
        return cb(coopData[owner].players)
    end
    if coopData[identifier] and not owner then
        notify(src, 'previouscrew')
        return cb(false)
    end

    if not coopData[identifier] then
        local roomSetting = {
            owneridentifier = identifier,
            ownersrc        = src,
            startJob        = false,
            finishJob       = false,
            Mission         = false,
            Vehicle         = {},
            VehicleNetId    = {},
        }
        for key, value in pairs(LobbyRoomSetting and LobbyRoomSetting(identifier, src) or {}) do
            roomSetting[key] = value
        end
        coopData[identifier] = {
            roomSetting = roomSetting,
            players = {
                {
                    playerName = GetName(src),
                    playerIdentifier = identifier,
                    playerImage = data.profiledata.avatar or Config.ExampleProfilePicture,
                    playerLevel = data.profiledata.level or 0,
                    playerOwner = true,
                    source = src,
                }
            }
        }
    end
    cb(coopData[identifier].players)
end)

RegisterServerCallback(_event('server:getJobIsActive'), function(source, cb)
    local owner = playerLobbyOwner(source)
    local lobby = owner and coopData[owner]
    if not lobby then return cb(false) end
    cb(lobby.roomSetting.Mission and (lobby.roomSetting.startJob or lobby.roomSetting.finishJob) and true or false)
end)

local function closeOwnLobby(src, identifier)
    local lobby = coopData[identifier]
    if not lobby or lobby.roomSetting.startJob or lobby.roomSetting.finishJob then return end
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent(_event('client:ClearCoopData'), player.source)
    end
    coopData[identifier], JoobTask[identifier] = nil, nil
end

RegisterServerEvent(_event('server:forceCloseNUI'), function()
    local src = source
    closeOwnLobby(src, GetIdentifier(src))
end)

RegisterServerEvent(_event('server:closeNUI'), function(owneridentifier)
    local src = source
    local identifier = GetIdentifier(src)
    local lobby = owneridentifier and coopData[owneridentifier]
    if not lobby then return end
    if owneridentifier == identifier then return closeOwnLobby(src, identifier) end
    if lobby.roomSetting.startJob or lobby.roomSetting.finishJob then return end
    if not removeMember(lobby, owneridentifier, identifier, src) then return end
    RecalculateAwards(lobby)

    TriggerClientEvent(_event('client:TakeLooby'), src)
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent(_event('client:RefreshPlayers'), player.source, lobby)
    end
end)

pendingInvites = pendingInvites or {}
local INVITE_TTL = 60

RegisterServerEvent(_event('server:invitePlayer'), function(data)
    local src = source
    local identifier = GetIdentifier(src)
    local playerData = playerJobData[identifier]
    local targetID = tonumber(type(data) == 'table' and data.targetID or data)
    if not (targetID and playerData and playerData.profiledata) or src == targetID then return end

    local targetIdentifier = GetIdentifier(targetID)
    local targetPlayer = playerJobData[targetIdentifier]
    local lobby = coopData[identifier]
    if not (lobby and targetPlayer and targetPlayer.profiledata) then return end
    if lobby.roomSetting.startJob or lobby.roomSetting.finishJob then return notify(src, 'jobalreadystarted') end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetID))) > 8.0 then
        return notify(src, 'playerfaraway')
    end
    if inAnyLobby(targetIdentifier, targetIdentifier) then
        return notify(src, 'playeralreadyinlobby')
    end
    local pending = pendingInvites[targetIdentifier]
    if pending and pending.expires > os.time() then
        return notify(src, 'playeralreadyinvited')
    end
    if #lobby.players >= Config.MaxPlayersInLobby then
        return notify(src, 'lobbyfull')
    end

    pendingInvites[targetIdentifier] = { host = identifier, expires = os.time() + INVITE_TTL }
    TriggerClientEvent(_event('client:invitePlayer'), targetID, playerData.profiledata.name, identifier,
        playerData.source or src)
end)

RegisterServerEvent(_event('server:acceptInvite'), function(data)
    local src = source
    local identifier = GetIdentifier(src)
    local playerData = playerJobData[identifier]
    if not (playerData and playerData.profiledata) then return end
    local hostIdentifier = type(data) == 'table' and data.hostIdentifier or data

    local pending = pendingInvites[identifier]
    if not (pending and pending.host == hostIdentifier and pending.expires > os.time()) then
        return notify(src, 'inviteexpired')
    end
    pendingInvites[identifier] = nil
    if not JobAllowed(src) then return notify(src, 'wrongjob') end
    if otherJob(src) then return notify(src, 'otherjob') end

    local lobby = coopData[hostIdentifier]
    if not (lobby and not (lobby.roomSetting.startJob or lobby.roomSetting.finishJob)) then
        return notify(src, 'jobalreadystarted')
    end
    if inAnyLobby(identifier, identifier) then
        return notify(src, 'playeralreadyinlobby')
    end
    local own = coopData[identifier]
    if own and (#own.players > 1 or own.roomSetting.startJob or own.roomSetting.finishJob) then
        return notify(src, 'playeralreadyinlobby')
    end
    if #lobby.players >= Config.MaxPlayersInLobby then
        return notify(src, 'lobbyfull')
    end

    coopData[identifier] = nil
    table.insert(lobby.players, {
        playerName = playerData.profiledata.name,
        playerIdentifier = playerData.profiledata.identifier,
        playerImage = playerData.profiledata.avatar or Config.ExampleProfilePicture,
        playerLevel = playerData.profiledata.level or 0,
        playerOwner = false,
        source = src,
    })
    RecalculateAwards(lobby)
    refreshLobby(lobby)
end)

RegisterServerEvent(_event('server:declineInvite'), function()
    local identifier = GetIdentifier(source)
    if identifier then pendingInvites[identifier] = nil end
end)

local function leaveRunningJob(src, owneridentifier, identifier)
    local lobby = coopData[owneridentifier]
    if lobby.roomSetting.paying then return end
    if not removeMember(lobby, owneridentifier, identifier, src) then return end
    TriggerClientEvent(_event('client:resetjob'), src, nil, true)
    RecalculateAwards(lobby)
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent(_event('client:RefreshJob'), player.source, JoobTask[owneridentifier])
        TriggerClientEvent(_event('client:UpdateLobby'), player.source, lobby)
    end
end

RegisterServerEvent(_event('server:leavePlayer'), function(ownerIdentifier)
    local src = source
    local identifier = GetIdentifier(src)
    local lobby = ownerIdentifier and coopData[ownerIdentifier]
    if not (lobby and identifier and playerJobData[identifier]) or isLobbyOwner(src, lobby) then return end
    if lobby.roomSetting.startJob or lobby.roomSetting.finishJob then
        return leaveRunningJob(src, ownerIdentifier, identifier)
    end
    if not removeMember(lobby, ownerIdentifier, identifier, src) then return end
    RecalculateAwards(lobby)
    refreshLobby(lobby)
    TriggerClientEvent(_event('client:TakeLooby'), src)
end)

RegisterServerEvent(_event('server:LeaveLobby'), function(owneridentifier)
    local src = source
    local identifier = GetIdentifier(src)
    local lobby = owneridentifier and coopData[owneridentifier]
    if not (lobby and (lobby.roomSetting.startJob or lobby.roomSetting.finishJob)) then
        return notify(src, 'jobnotstarted')
    end
    if isLobbyOwner(src, lobby) then
        return notify(src, 'isownernotleave')
    end
    leaveRunningJob(src, owneridentifier, identifier)
end)

RegisterServerEvent(_event('server:kickPlayer'), function(data)
    local src = source
    local identifier = GetIdentifier(src)
    if type(data) ~= 'table' or not playerJobData[identifier] then return end
    local targetID = tonumber(data.targetID)
    if not targetID or targetID == src then return end

    local targetIdentifier = GetIdentifier(targetID)
    if not targetIdentifier or targetIdentifier ~= data.identifier then return end

    local lobby = coopData[identifier]
    if not lobby or lobby.roomSetting.startJob or lobby.roomSetting.finishJob then return end
    if not removeMember(lobby, identifier, targetIdentifier, targetID) then return end
    RecalculateAwards(lobby)
    refreshLobby(lobby)
    TriggerClientEvent(_event('client:TakeLooby'), targetID)
end)

local regionPickAt = {}
RegisterServerEvent(_event('server:selectRegion'), function(data)
    local src = source
    local lobby = coopData[GetIdentifier(src)]
    if not lobby then return end
    local now = GetGameTimer()
    if regionPickAt[src] and now - regionPickAt[src] < 250 then
        return TriggerClientEvent(_event('client:RefreshPlayers'), src, lobby)
    end
    regionPickAt[src] = now
    if lobby.roomSetting.startJob or lobby.roomSetting.finishJob then
        return notify(src, 'jobalreadystarted')
    end

    local region = data and LobbyRegion(data) or false
    local need = region and tonumber(region.regionInfo and region.regionInfo.regionMinimumLevel or region.minLevel) or 0
    local me = playerJobData[GetIdentifier(src)]
    if region and me and me.profiledata and (tonumber(me.profiledata.level) or 0) < need then
        return notify(src, 'joblevelnotenough')
    end
    lobby.roomSetting.Mission = region
    RecalculateAwards(lobby)
    refreshLobby(lobby)
end)

RegisterServerEvent(_event('server:resetJobButton'), function(owneridentifier)
    local src = source
    if not isLobbyOwner(src, owneridentifier and coopData[owneridentifier]) then
        return notify(src, 'notowner')
    end
    resetLobby(owneridentifier)
end)

local function leaveCrew(lobby, owner, player)
    removeMember(lobby, owner, player.playerIdentifier, player.source)
    RecalculateAwards(lobby)
    for _, other in ipairs(lobby.players) do
        notify(other.source, 'playerleftlobby')
        TriggerClientEvent(_event('client:UpdateLobby'), other.source, lobby)
        if JoobTask[owner] then
            TriggerClientEvent(_event('client:RefreshJob'), other.source, JoobTask[owner])
        end
    end
end

local function reconnectSeconds()
    local ok, rows = pcall(function() return exports['tw-lib']:GetOverrides('tw-lib') end)
    for _, row in ipairs(ok and rows or {}) do
        if row.path[1] == 'reconnect' and #row.path == 1 then return tonumber(row.value) or 0 end
    end
    return 180
end

local function dropOwner(lobby, owner, player)
    local heir
    for _, other in ipairs(lobby.players) do
        if other ~= player and not other.offline then heir = other break end
    end
    local running = (lobby.roomSetting.startJob or lobby.roomSetting.finishJob) and JoobTask[owner]
    if not (heir and LobbyOwnerChanged and running) then
        return resetLobby(owner, 'playerleftlobby')
    end
    player.playerOwner, heir.playerOwner = false, true
    lobby.roomSetting.ownersrc = heir.source
    local keep = LobbyRestoreMember and reconnectSeconds() or 0
    if keep > 0 then
        player.offline = GetGameTimer() + keep * 1000
        if OnLobbyMemberRemoved then OnLobbyMemberRemoved(lobby, owner, player.playerIdentifier, player.source) end
    else
        removeMember(lobby, owner, player.playerIdentifier, player.source)
        RecalculateAwards(lobby)
    end
    for _, other in ipairs(lobby.players) do
        if not other.offline then
            notify(other.source, 'ownerchanged')
            TriggerClientEvent(_event('client:UpdateLobby'), other.source, lobby)
            if JoobTask[owner] then TriggerClientEvent(_event('client:RefreshJob'), other.source, JoobTask[owner]) end
        end
    end
    LobbyOwnerChanged(lobby, owner, heir.source)
    return true
end

function dropLobbyPlayer(src, identifier)
    pendingInvites[identifier] = nil
    for owner, lobby in pairs(coopData) do
        for _, player in ipairs(lobby.players) do
            if not player.offline and (player.source == src or player.playerIdentifier == identifier) then
                if lobby.roomSetting.paying then return true end
                if player.playerOwner then return dropOwner(lobby, owner, player) end
                local running = lobby.roomSetting.startJob or lobby.roomSetting.finishJob
                local keep = LobbyRestoreMember and running and JoobTask[owner] and reconnectSeconds() or 0
                if keep <= 0 then
                    leaveCrew(lobby, owner, player)
                    return true
                end
                player.offline = GetGameTimer() + keep * 1000
                if OnLobbyMemberRemoved then OnLobbyMemberRemoved(lobby, owner, player.playerIdentifier, player.source) end
                for _, other in ipairs(lobby.players) do
                    if not other.offline then
                        notify(other.source, 'playerleftlobby')
                        TriggerClientEvent(_event('client:UpdateLobby'), other.source, lobby)
                    end
                end
                return true
            end
        end
    end
    return false
end

function restoreLobbySeat(src, identifier)
    for owner, lobby in pairs(coopData) do
        for _, player in ipairs(lobby.players) do
            if player.playerIdentifier == identifier and player.offline then
                player.source, player.offline = src, nil
                for _, row in ipairs(JoobTask[owner] and JoobTask[owner].Players or {}) do
                    if row.playerIdentifier == identifier then row.source = src end
                end
                for _, other in ipairs(lobby.players) do
                    TriggerClientEvent(_event('client:UpdateLobby'), other.source, lobby)
                end
                if LobbyRestoreMember then LobbyRestoreMember(lobby, owner, src) end
                return true
            end
        end
    end
    return false
end

simulatedAway = simulatedAway or {}
AddEventHandler('twlib:simulateDrop', function(target, back)
    target = tonumber(target)
    local identifier = target and GetIdentifier(target)
    if not identifier then return end
    local function say(text)
        print(('[%s] %s: %s'):format(GetCurrentResourceName(), GetName(target), text))
        TriggerClientEvent('chat:addMessage', target, { args = { GetCurrentResourceName(), text } })
    end
    if back then
        simulatedAway[identifier] = nil
        if restoreLobbySeat(target, identifier) then say('back in the job (simulated return)') end
        return
    end
    if not playerLobbyOwner(target) then return end
    local wasOwner = isLobbyOwner(target, coopData[playerLobbyOwner(target)])
    simulatedAway[identifier] = true
    dropLobbyPlayer(target, identifier)
    TriggerClientEvent(_event('client:resetjob'), target, nil, true)
    say(wasOwner and 'dropped as the owner (simulated); twback to return' or 'dropped (simulated); twback to return')
end)

exports('TwLibOwnsVehicle', function(src, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local owner = playerLobbyOwner(src)
    local room = owner and coopData[owner].roomSetting
    local plate = JobVehiclePlate and JobVehiclePlate(netId) or nil
    for _, v in ipairs(room and room.regionJobVehiclePlate or {}) do
        if type(v) == 'table' and v.netID == netId and type(v.plate) == 'string' then plate = v.plate end
    end
    if room then
        for _, v in pairs(room.Vehicle or {}) do if v == vehicle then return true, plate end end
        for _, id in pairs(room.VehicleNetId or {}) do if id == netId then return true, plate end end
    end
    local owns = JobOwnsVehicle ~= nil and JobOwnsVehicle(src, vehicle, netId) == true
    return owns, owns and plate or nil
end)

local payingSince = setmetatable({}, { __mode = 'k' })

CreateThread(function()
    while true do
        Wait(1000)
        local now = GetGameTimer()
        for owner, lobby in pairs(coopData) do
            if lobby.roomSetting.paying then
                payingSince[lobby] = payingSince[lobby] or now
                if now - payingSince[lobby] > 60000 then
                    print(('^1[%s]^7 payout of lobby %s did not finish in 60 s, the lobby is closed'):format(GetCurrentResourceName(), tostring(owner)))
                    lobby.roomSetting.paying = nil
                    if not resetLobby(owner) then coopData[owner], JoobTask[owner] = nil, nil end
                end
            else
                payingSince[lobby] = nil
                for i = #lobby.players, 1, -1 do
                    local player = lobby.players[i]
                    if player and player.offline and (now >= player.offline or not (lobby.roomSetting.startJob or lobby.roomSetting.finishJob)) then
                        leaveCrew(lobby, owner, player)
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then
        for id, data in pairs(playerJobData) do
            if data and data.source == src then identifier = id break end
        end
    end
    if not identifier then return end
    dropLobbyPlayer(src, identifier)
    playerJobData[identifier] = nil
end)

RegisterServerCallback(_event('server:leaveOtherJob'), function(source, cb)
    local ok, done = pcall(function() return exports['tw-lib']:LeaveOtherJob(source) end)
    cb(ok and done == true)
end)

exports('TwLibInLobby', function(src)
    if not playerLobbyOwner(src) then return nil end
    return Config.UI and Config.UI.scriptName or GetCurrentResourceName()
end)

exports('TwLibLeaveLobby', function(src)
    local identifier = GetIdentifier(src)
    local owner = playerLobbyOwner(src)
    local lobby = owner and coopData[owner]
    if not lobby then return true end
    if lobby.roomSetting.paying then return false end
    local running = lobby.roomSetting.startJob or lobby.roomSetting.finishJob
    if not isLobbyOwner(src, lobby) then
        if running then
            leaveRunningJob(src, owner, identifier)
        elseif removeMember(lobby, owner, identifier, src) then
            RecalculateAwards(lobby)
            refreshLobby(lobby)
            TriggerClientEvent(_event('client:TakeLooby'), src)
        end
        return playerLobbyOwner(src) == nil
    end
    if not running then
        closeOwnLobby(src, identifier)
        return playerLobbyOwner(src) == nil
    end
    for _, player in ipairs(lobby.players) do
        if player.source == src and not player.offline then dropOwner(lobby, owner, player) break end
    end
    if coopData[owner] and removeMember(coopData[owner], owner, identifier, src) then
        RecalculateAwards(coopData[owner])
        TriggerClientEvent(_event('client:resetjob'), src, nil, true)
    end
    return playerLobbyOwner(src) == nil
end)
