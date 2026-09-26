TwLib = TwLib or {}
local Ledger = {}
TwLib.Ledger = Ledger

local LIB = GetCurrentResourceName()
local REASON_MAX = 32
local INSERT = 'INSERT INTO `tw_lib_ledger` (`resource`, `identifier`, `kind`, `direction`, `account`, `item`, `amount`, `reason`) ' ..
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)'

local function ident(v)
    if type(v) == 'number' then v = tostring(v) end
    return type(v) == 'string' and v ~= '' and v or nil
end

function Ledger.isOn()
    if not (TwLib.Schema and TwLib.Schema.ready) then return false end
    return TwLib.Store.get(LIB, { 'ledger', 'enabled' }) ~= false
end

function Ledger.record(row)
    if not Ledger.isOn() then return false end
    local amount = math.floor(tonumber(row.amount) or 0)
    local identifier = ident(row.identifier)
    if amount <= 0 or not identifier then return false end
    local reason = row.reason
    reason = (type(reason) == 'string' and reason ~= '') and reason:sub(1, REASON_MAX) or 'unknown'
    MySQL.query(INSERT, {
        row.resource or LIB, identifier, row.kind, row.direction,
        row.account or '', row.item, amount, reason,
    })
    return true
end

local PLAYER_UPSERT = 'INSERT INTO `tw_lib_players` (`identifier`, `name`, `fivem_name`) VALUES (?, ?, ?) ' ..
    'ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `fivem_name` = VALUES(`fivem_name`)'
local remembered = {}

function Ledger.rememberPlayer(identifier, name, fivemName)
    identifier = ident(identifier)
    if not Ledger.isOn() or not identifier or remembered[identifier] then return end
    remembered[identifier] = true
    MySQL.query(PLAYER_UPSERT, { identifier, name, fivemName })
end

local HISTORY_INSERT = 'INSERT INTO `tw_lib_job_history` (`identifier`, `job_id`, `region_name`, `earned_money`, `earned_xp`, `duration_seconds`, `completed_at`) ' ..
    'VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)'

local function callerResource()
    local fn = GetInvokingResource
    return (fn and fn()) or LIB
end

function Ledger.addJobHistory(identifier, jobId, regionName, earnedMoney, earnedXp, durationSeconds, cb)
    if type(durationSeconds) == 'function' then
        cb, durationSeconds = durationSeconds, 0
    end
    if not Ledger.isOn() then return false end
    identifier = ident(identifier)
    if not identifier then return false end
    if type(jobId) ~= 'string' or jobId == '' then return false end
    MySQL.query(HISTORY_INSERT, {
        identifier,
        jobId,
        regionName,
        math.floor(tonumber(earnedMoney) or 0),
        math.floor(tonumber(earnedXp) or 0),
        math.floor(tonumber(durationSeconds) or 0),
    })
    if cb then pcall(cb) end
    return true
end

function Ledger.RecordXp(identifier, amount, reason)
    return Ledger.record({
        resource = callerResource(),
        identifier = identifier,
        kind = 'xp',
        direction = 'in',
        amount = amount,
        reason = reason,
    })
end

exports('addJobHistory', Ledger.addJobHistory)
exports('RecordXp', Ledger.RecordXp)
