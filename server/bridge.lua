local Detect = TwLib.Detect
local Bridge = { custom = {} }
TwLib.Server = Bridge

local standalone = {}
local function standalonePlayer(src)
    if not src or not GetPlayerName(src) then return nil end
    standalone[src] = standalone[src] or {
        identifier = GetPlayerIdentifierByType(src, 'license'),
        money = { cash = 5000, bank = 10000 },
    }
    return standalone[src]
end

local qb = {
    core = function()
        local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and obj then return obj end
        local legacy
        TriggerEvent('QBCore:GetObject', function(o) legacy = o end)
        return legacy
    end,
    player = function(core, src) return core.Functions.GetPlayer(src) end,
    identifier = function(ctx) return ctx.player.PlayerData.citizenid end,
    name = function(ctx)
        local c = ctx.player.PlayerData.charinfo
        return c.firstname .. ' ' .. c.lastname
    end,
    addMoney = function(ctx, account, n, reason) return ctx.player.Functions.AddMoney(account, n, reason) ~= false end,
    removeMoney = function(ctx, account, n, reason) return ctx.player.Functions.RemoveMoney(account, n, reason) ~= false end,
    money = function(ctx, account) return ctx.player.PlayerData.money[account] or 0 end,
    addItem = function(ctx, item, n, slot, info) return ctx.player.Functions.AddItem(item, n, slot, info) ~= false end,
    removeItem = function(ctx, item, n)
        local slots, total = {}, 0
        for _, it in pairs(ctx.player.PlayerData.items or {}) do
            if it and it.name == item and (tonumber(it.amount) or 0) > 0 then
                slots[#slots + 1], total = it, total + it.amount
            end
        end
        if total < n then return false end
        for _, it in ipairs(slots) do
            local take = math.min(n, it.amount)
            if ctx.player.Functions.RemoveItem(item, take, it.slot) == false then return false end
            n = n - take
            if n <= 0 then return true end
        end
        return false
    end,
    hasItem = function(ctx, item, n)
        local total = 0
        for _, it in pairs(ctx.player.PlayerData.items or {}) do
            if it and it.name == item then total = total + (tonumber(it.amount) or 0) end
        end
        return total >= n
    end,
    inventory = function(ctx) return ctx.player.PlayerData.items end,
    job = function(ctx)
        local j = ctx.player.PlayerData.job
        return j and { name = j.name, label = j.label, grade = j.grade and j.grade.level or 0 } or nil
    end,
}

local esx = {
    core = function()
        local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and obj then return obj end
        local legacy
        TriggerEvent('esx:getSharedObject', function(o) legacy = o end)
        return legacy
    end,
    player = function(core, src) return core.GetPlayerFromId(src) end,
    identifier = function(ctx) return ctx.player.getIdentifier() end,
    name = function(ctx) return ctx.player.getName() end,
    addMoney = function(ctx, account, n)
        if account ~= 'cash' and not ctx.player.getAccount(account) then return false end
        if account == 'cash' then ctx.player.addMoney(n) else ctx.player.addAccountMoney(account, n) end
        return true
    end,
    removeMoney = function(ctx, account, n)
        local a = account ~= 'cash' and ctx.player.getAccount(account)
        if (account == 'cash' and ctx.player.getMoney() or a and a.money or 0) < n then return false end
        if account == 'cash' then ctx.player.removeMoney(n) else ctx.player.removeAccountMoney(account, n) end
        return true
    end,
    money = function(ctx, account)
        if account == 'cash' then return ctx.player.getMoney() end
        local a = ctx.player.getAccount(account)
        return a and a.money or 0
    end,
    addItem = function(ctx, item, n)
        ctx.player.addInventoryItem(item, n)
        return true
    end,
    removeItem = function(ctx, item, n)
        local it = ctx.player.getInventoryItem(item)
        if (tonumber(it and (it.count or it.amount)) or 0) < n then return false end
        ctx.player.removeInventoryItem(item, n)
        return true
    end,
    hasItem = function(ctx, item, n)
        local it = ctx.player.getInventoryItem(item)
        return (tonumber(it and (it.count or it.amount)) or 0) >= n
    end,
    inventory = function(ctx) return ctx.player.getInventory() end,
    job = function(ctx)
        local j = ctx.player.job
        return j and { name = j.name, label = j.label, grade = tonumber(j.grade) or 0 } or nil
    end,
}

local none = {
    identifier = function(ctx) return ctx.player.identifier end,
    name = function(ctx) return GetPlayerName(ctx.src) end,
    addMoney = function(ctx, account, n)
        local m = ctx.player.money
        if m[account] == nil then return false end
        m[account] = m[account] + n
        return true
    end,
    removeMoney = function(ctx, account, n)
        local m = ctx.player.money
        if m[account] == nil then return false end
        m[account] = math.max(0, m[account] - n)
        return true
    end,
    money = function(ctx, account) return ctx.player.money[account] or 0 end,
    addItem = function() return true end,
    removeItem = function() return true end,
    hasItem = function() return true end,
}

local tmc = {
    core = function() return exports.core:getCoreObject() end,
    player = function(core, src) return core.Functions.GetPlayer(src) end,
    identifier = function(ctx) return ctx.player.PlayerData and ctx.player.PlayerData.citizenid end,
    name = function(ctx)
        local full = ctx.player.Functions.GetFullName
        return full and full() or GetPlayerName(ctx.src)
    end,
    addMoney = function(ctx, account, n, reason) return ctx.player.Functions.AddMoney(account, n, reason) ~= false end,
    removeMoney = function(ctx, account, n, reason) return ctx.player.Functions.RemoveMoney(account, n, reason) ~= false end,
    money = function(ctx, account)
        local m = ctx.player.PlayerData and ctx.player.PlayerData.money
        return m and m[account] or 0
    end,
    addItem = function(ctx, item, n, slot, info) return ctx.player.Functions.AddItem(item, n, slot, info) ~= false end,
    removeItem = function(ctx, item, n) return ctx.player.Functions.RemoveItem(item, n) ~= false end,
    hasItem = function(ctx, item) return ctx.player.Functions.HasItem(item) and true or false end,
    inventory = function(ctx) return ctx.player.PlayerData and ctx.player.PlayerData.items end,
}

local vrp = {
    core = function()
        load(LoadResourceFile('vrp', 'lib/utils.lua'))()
        local iface = module('vrp', 'lib/Proxy').getInterface('vRP')
        return type(iface) == 'table' and iface or nil
    end,
    player = function(core, src) return core.getUserId(src) end,
    identifier = function(ctx) return ctx.player end,
    name = function(ctx)
        local id = ctx.core.getUserIdentity(ctx.player)
        if not id then return GetPlayerName(ctx.src) end
        if id.nome then return id.nome .. ' ' .. (id.sobrenome or '') end
        if id.firstname then return id.firstname .. ' ' .. (id.name or id.lastname or '') end
        if id.first_name then return id.first_name .. ' ' .. (id.last_name or id.surname or '') end
        return GetPlayerName(ctx.src)
    end,
    addMoney = function(ctx, account, n)
        if account == 'bank' then ctx.core.giveBankMoney(ctx.player, n) return true end
        if account == 'cash' then ctx.core.giveMoney(ctx.player, n) return true end
        return false
    end,
    removeMoney = function(ctx, account, n)
        if account == 'bank' then return ctx.core.tryWithdraw(ctx.player, n) ~= false end
        if account == 'cash' then return ctx.core.tryPayment(ctx.player, n) ~= false end
        return false
    end,
    money = function(ctx, account)
        if account == 'bank' then return ctx.core.getBankMoney(ctx.player) or 0 end
        if account == 'cash' then return ctx.core.getMoney(ctx.player) or 0 end
        return 0
    end,
    addItem = function(ctx, item, n)
        ctx.core.giveInventoryItem(ctx.player, item, n)
        return true
    end,
    removeItem = function(ctx, item, n) return ctx.core.tryGetInventoryItem(ctx.player, item, n) ~= false end,
    hasItem = function(ctx, item, n) return (tonumber(ctx.core.getInventoryItemAmount(ctx.player, item)) or 0) >= n end,
    inventory = function(ctx) return ctx.core.Inventory(ctx.player) end,
}

local ACCOUNTS = { bank = true, cash = true }
local vrp2 = {
    player = function(core, src) return core.Passport(src) end,
    identifier = function(ctx) return tostring(ctx.player) end,
    name = function(ctx) return ctx.core.FullName(ctx.player) or GetPlayerName(ctx.src) end,
    addMoney = function(ctx, account, n)
        if not ACCOUNTS[account] then return false end
        ctx.core.GenerateItem(ctx.player, 'dollar', n, true)
        return true
    end,
    removeMoney = function(ctx, account, n)
        if not ACCOUNTS[account] then return false end
        return ctx.core.TakeItem(ctx.player, 'dollar', n) ~= false
    end,
    money = function(ctx, account)
        if not ACCOUNTS[account] then return 0 end
        local amount = ctx.core.InventoryItemAmount(ctx.player, 'dollar')
        return amount and tonumber(amount[1]) or 0
    end,
    addItem = function(ctx, item, n)
        ctx.core.GenerateItem(ctx.player, item, n, true)
        return true
    end,
    removeItem = function(ctx, item, n) return ctx.core.TakeItem(ctx.player, item, n) ~= false end,
    hasItem = function(ctx, item, n)
        local amount = ctx.core.InventoryItemAmount(ctx.player, item)
        return (amount and tonumber(amount[1]) or 0) >= n
    end,
    inventory = function() return nil end,
}

local frameworks = { qb = qb, qbx = qb, esx = esx, tmc = tmc, vrp = vrp, standalone = none }

local serverKeys = {
    qbx_vehiclekeys = {
        give = function(src, vehicle) exports.qbx_vehiclekeys:GiveKeys(src, vehicle) end,
        remove = function(src, vehicle) if vehicle then exports.qbx_vehiclekeys:RemoveKeys(src, vehicle) end end,
    },
    ['qb-vehiclekeys'] = {
        give = function(src, _, plate) exports['qb-vehiclekeys']:GiveKeys(src, plate) end,
        remove = function(src, _, plate) exports['qb-vehiclekeys']:RemoveKeys(src, plate) end,
    },
    tmc = {
        give = function(src, vehicle) TriggerClientEvent('vehiclelock:client:addKeys', src, vehicle) end,
    },
}

local function serverKeyAdapter()
    local id, from = Detect.get('keys')
    if from == 'manual' and id == 'none' then return nil end
    if serverKeys[id] then return serverKeys[id], id end
    local fw = Detect.get('framework')
    if fw == 'qb' or fw == 'qbx' then return serverKeys['qb-vehiclekeys'], 'qb-vehiclekeys' end
    if fw == 'tmc' then return serverKeys.tmc, 'tmc' end
end

local function jobOwnsVehicle(src, netId, resource)
    if type(resource) ~= 'string' or GetResourceMetadata(resource, 'tw_lib', 0) == nil then return false end
    local ok, owns, plate = pcall(function() return exports[resource]:TwLibOwnsVehicle(src, netId) end)
    return ok and owns == true, ok and owns == true and type(plate) == 'string' and plate or nil
end

RegisterNetEvent('tw-lib:server:vehicleKey', function(give, netId, plate, resource)
    local src = source
    local adapter, id = serverKeyAdapter()
    local fn = adapter and adapter[give and 'give' or 'remove']
    if not fn then return end
    local vehicle = type(netId) == 'number' and netId ~= 0 and NetworkGetEntityFromNetworkId(netId) or nil
    if vehicle and not DoesEntityExist(vehicle) then vehicle = nil end
    local clientPlate = type(plate) == 'string' and plate ~= '' and plate or nil
    if give then
        local owns, known = jobOwnsVehicle(src, netId, resource)
        if not (vehicle and owns) then return end
        plate = known or GetVehicleNumberPlateText(vehicle)
    else
        plate = clientPlate or (vehicle and GetVehicleNumberPlateText(vehicle))
    end
    plate = plate and plate:match('^%s*(.-)%s*$')
    if not plate or plate == '' then return end
    local ok, err = pcall(fn, src, vehicle, plate)
    if not ok then print(('^1[tw-lib]^7 %s: %s key failed: %s'):format(id, give and 'give' or 'remove', tostring(err))) end
end)

local function counted(count, add, remove, items)
    local function has(src, item, n) return (tonumber(count(src, item)) or 0) >= n end
    return {
        addItem = function(...) return add(...) ~= false end,
        removeItem = function(src, item, n) return has(src, item, n) and remove(src, item, n) ~= false end,
        hasItem = has,
        items = items,
    }
end

local function qs(res)
    return {
        addItem = function(src, item, n) return exports[res]:AddItem(src, item, n) ~= false end,
        removeItem = function(src, item, n) return exports[res]:RemoveItem(src, item, n) ~= false end,
        hasItem = function(src, item, n) return (exports[res]:GetItemTotalAmount(src, item) or 0) >= n end,
    }
end

local inventories = {
    ox_inventory = {
        addItem = function(src, item, n) return exports.ox_inventory:AddItem(src, item, n) and true or false end,
        removeItem = function(src, item, n) return exports.ox_inventory:RemoveItem(src, item, n) and true or false end,
        hasItem = function(src, item, n) return (exports.ox_inventory:GetItemCount(src, item) or 0) >= n end,
        items = function(src) return exports.ox_inventory:GetInventoryItems(src) end,
    },
    qs_inventory = qs('qs-inventory'),
    ['qs-inventory-pro'] = qs('qs-inventory-pro'),
    ['codem-inventoryv2'] = counted(
        function(src, item) return exports['codem-inventoryv2']:Search(src, 'count', item) end,
        function(src, item, n, slot, info) return exports['codem-inventoryv2']:AddItem(src, item, n, info, slot) end,
        function(src, item, n) return exports['codem-inventoryv2']:RemoveItem(src, item, n) end,
        function(src) return exports['codem-inventoryv2']:GetInventoryItems(src) end),
    origen_inventory = counted(
        function(src, item) return exports.origen_inventory:getItemCount(src, item) end,
        function(src, item, n, slot, info) return exports.origen_inventory:addItem(src, item, n, info, slot) end,
        function(src, item, n) return exports.origen_inventory:removeItem(src, item, n) end),
    ak47_inventory = counted(
        function(src, item) return exports['ak47_inventory']:Search(src, 'count', item) end,
        function(src, item, n, slot, info) return exports['ak47_inventory']:AddItem(src, item, n, slot, info) end,
        function(src, item, n) return exports['ak47_inventory']:RemoveItem(src, item, n) end,
        function(src) return exports['ak47_inventory']:GetInventoryItems(src) end),
    core_inventory = counted(
        function(src, item) return exports.core_inventory:getItemCount(src, item) end,
        function(src, item, n, _, info) return exports.core_inventory:addItem(src, item, n, info) end,
        function(src, item, n) return exports.core_inventory:removeItem(src, item, n) end),
    jaksam_inventory = counted(
        function(src, item) return exports.jaksam_inventory:getTotalItemAmount(src, item) end,
        function(src, item, n, slot, info) return (exports.jaksam_inventory:addItem(src, item, n, info, slot)) end,
        function(src, item, n) return (exports.jaksam_inventory:removeItem(src, item, n)) end,
        function(src) return (exports.jaksam_inventory:getInventory(src) or {}).items end),
    one_inventory = counted(
        function(src, item) return exports.one_inventory:GetItemCount(src, item) end,
        function(src, item, n, slot, info) return exports.one_inventory:AddItem(src, item, n, info, slot) end,
        function(src, item, n) return exports.one_inventory:RemoveItem(src, item, n) end,
        function(src) return exports.one_inventory:GetInventoryItems(src) end),
    ['tgiann-inventory'] = {
        addItem = function(src, item, n, slot, info) return exports['tgiann-inventory']:AddItem(src, item, n, slot, info, false) ~= false end,
        removeItem = function(src, item, n)
            if not exports['tgiann-inventory']:HasItem(src, item, n) then return false end
            return exports['tgiann-inventory']:RemoveItem(src, item, n) ~= false
        end,
        hasItem = function(src, item, n) return exports['tgiann-inventory']:HasItem(src, item, n) and true or false end,
    },
    ['codem-inventory'] = {
        addItem = function(src, item, n, slot, info) return exports['codem-inventory']:AddItem(src, item, n, slot, info) ~= false end,
        removeItem = function(src, item, n)
            local codem = exports['codem-inventory']
            if (tonumber(codem:GetItemsTotalAmount(src, item)) or 0) < n then return false end
            local slots = {}
            for _, v in pairs(codem:GetInventory(nil, src) or {}) do
                local amount = tonumber(v.amount or v.count) or 0
                if v.name == item and amount > 0 and v.slot then slots[#slots + 1] = { slot = v.slot, amount = amount } end
            end
            if #slots == 0 then return codem:RemoveItem(src, item, n) ~= false end
            for _, s in ipairs(slots) do
                local take = math.min(n, s.amount)
                if codem:RemoveItem(src, item, take, s.slot) == false then return false end
                n = n - take
                if n <= 0 then return true end
            end
            return false
        end,
        hasItem = function(src, item, n) return (tonumber(exports['codem-inventory']:GetItemsTotalAmount(src, item)) or 0) >= n end,
    },
    ak47_qb_inventory = {
        addItem = function(src, item, n) return exports['ak47_qb_inventory']:AddItem(src, item, n) ~= false end,
        removeItem = function(src, item, n) return exports['ak47_qb_inventory']:RemoveItem(src, item, n) ~= false end,
        hasItem = function(src, item, n) return (exports['ak47_qb_inventory']:GetItemCount(src, item) or 0) >= n end,
    },
}

local cores, vrpFork = {}, nil
local function vrpPlayer(core, src)
    if vrpFork then return vrpFork, vrpFork.player(core, src) end
    local id = core.getUserId(src)
    if id then vrpFork = vrp return vrp, id end
    id = core.Passport(src)
    if id then vrpFork = vrp2 return vrp2, id end
    return vrp, nil
end

local function context(src)
    src = tonumber(src)
    local id = Detect.get('framework')
    local fw = frameworks[id] or none
    if fw == none then return fw, { src = src, player = standalonePlayer(src) } end
    if cores[id] == nil then
        local ok, obj = pcall(fw.core)
        cores[id] = ok and obj or false
        if not cores[id] then print(('^1[tw-lib]^7 %s core object unavailable: %s'):format(id, tostring(obj))) end
    end
    local core = cores[id] or nil
    if fw == vrp and core and src then
        local picked, player = vrpPlayer(core, src)
        return picked, { src = src, core = core, player = player }
    end
    return fw, { src = src, core = core, player = core and src and fw.player(core, src) or nil }
end

local function inventory()
    local id = Detect.get('inventory')
    if id == 'custom' then return Bridge.custom.inventory.impl end
    return inventories[id]
end

local function positive(v)
    local n = tonumber(v)
    if not n or n ~= n or n <= 0 or n == math.huge then return nil end
    return n
end

function Bridge.reset()
    cores, vrpFork = {}, nil
end

local function log(kind, direction, src, account, item, amount, reason)
    if not TwLib.Ledger then return end
    local identifier = tostring(Bridge.GetIdentifier(src) or '')
    if TwLib.Ledger.rememberPlayer then TwLib.Ledger.rememberPlayer(identifier, Bridge.GetName(src), GetPlayerName(src)) end
    TwLib.Ledger.record({
        resource = GetInvokingResource(),
        identifier = identifier,
        kind = kind,
        direction = direction,
        account = account,
        item = item,
        amount = amount,
        reason = reason,
    })
end

function Bridge.GetPlayer(src)
    local _, ctx = context(src)
    return ctx.player
end

function Bridge.GetIdentifier(src)
    local fw, ctx = context(src)
    return ctx.player and fw.identifier(ctx) or nil
end

function Bridge.GetName(src)
    local fw, ctx = context(src)
    return ctx.player and fw.name(ctx) or GetPlayerName(src)
end

function Bridge.AddMoney(src, account, amount, reason)
    local n = positive(amount)
    local fw, ctx = context(src)
    if not n or not ctx.player then return false end
    account = account or 'cash'
    local paid = fw.addMoney(ctx, account, n, reason or GetInvokingResource() or 'tw-lib')
    if paid then log('money', 'in', src, account, nil, n, reason) end
    return paid
end

function Bridge.RemoveMoney(src, account, amount, reason)
    local n = positive(amount)
    local fw, ctx = context(src)
    if not n or not ctx.player then return false end
    account = account or 'cash'
    local taken = fw.removeMoney(ctx, account, n, reason or GetInvokingResource() or 'tw-lib')
    if taken then log('money', 'out', src, account, nil, n, reason) end
    return taken
end

function Bridge.GetPlayerJob(src)
    local fw, ctx = context(src)
    return ctx.player and fw.job and fw.job(ctx) or nil
end

function Bridge.GetPlayerMoney(src, account)
    local fw, ctx = context(src)
    return ctx.player and fw.money(ctx, account or 'cash') or 0
end

function Bridge.addItem(src, item, amount, slot, info)
    local n = positive(amount or 1)
    if not n or type(item) ~= 'string' then return false end
    local inv = inventory()
    local added
    if inv then
        added = inv.addItem(tonumber(src), item, n, slot, info)
    else
        local fw, ctx = context(src)
        added = ctx.player and fw.addItem(ctx, item, n, slot, info) or false
    end
    if added then log('item', 'in', src, '', item, n, nil) end
    return added
end

function Bridge.removeItem(src, item, amount)
    local n = positive(amount or 1)
    if not n or type(item) ~= 'string' then return false end
    local inv = inventory()
    local taken
    if inv then
        taken = inv.removeItem(tonumber(src), item, n)
    else
        local fw, ctx = context(src)
        taken = ctx.player and fw.removeItem(ctx, item, n) or false
    end
    if taken then log('item', 'out', src, '', item, n, nil) end
    return taken
end

function Bridge.HasItem(src, item, amount)
    local name = type(item) == 'table' and item.name or item
    local n = positive(type(item) == 'table' and item.amount or amount) or 1
    if type(name) ~= 'string' then return false end
    local inv = inventory()
    if inv then return inv.hasItem(tonumber(src), name, n) end
    local fw, ctx = context(src)
    return ctx.player and fw.hasItem(ctx, name, n) or false
end

local function normalize(list)
    local out = {}
    for _, v in pairs(type(list) == 'table' and list or {}) do
        local amount = type(v) == 'table' and tonumber(v.count or v.amount) or 0
        if amount > 0 and type(v.name) == 'string' then
            local meta = v.metadata or v.info
            if type(meta) ~= 'table' or next(meta) == nil then meta = false end
            out[#out + 1] = { name = v.name, label = v.label, amount = amount, metadata = meta, slot = v.slot }
        end
    end
    return out
end

function Bridge.GetInventory(src)
    local inv = inventory()
    if inv and inv.items then
        local ok, items = pcall(inv.items, tonumber(src))
        if ok and type(items) == 'table' then return normalize(items) end
        print(('^1[tw-lib]^7 %s items failed for %s: %s'):format(Detect.get('inventory'), tostring(src), tostring(items)))
        return {}
    end
    local fw, ctx = context(src)
    return ctx.player and fw.inventory and normalize(fw.inventory(ctx)) or {}
end

local usableByInventory = {
    qs_inventory = function(item, fn) exports['qs-inventory']:CreateUsableItem(item, fn) end,
    ['qs-inventory-pro'] = function(item, fn) exports['qs-inventory-pro']:CreateUsableItem(item, fn) end,
    ak47_qb_inventory = function(item, fn) exports['ak47_qb_inventory']:CreateUseableItem(item, fn) end,
}
local usableByFramework = {
    qb = function(core, item, fn) core.Functions.CreateUseableItem(item, fn) end,
    qbx = function(core, item, fn) core.Functions.CreateUseableItem(item, fn) end,
    esx = function(core, item, fn) core.RegisterUsableItem(item, fn) end,
    vrp = function(core, item, fn)
        if type(core.defInventoryItem) ~= 'function' then return false end
        core.defInventoryItem(item, '', item .. '.png', fn)
    end,
}

function Bridge.RegisterUsableItem(item, cb)
    if type(item) ~= 'string' or (type(cb) ~= 'function' and type(cb) ~= 'table') then return false end
    local fn = function(source, ...) return cb(source, ...) end
    local byInventory = usableByInventory[Detect.get('inventory')]
    if byInventory then
        byInventory(item, fn)
        return true
    end
    local register = usableByFramework[Detect.get('framework')]
    local _, ctx = context(nil)
    if not (register and ctx.core) then return false end
    return register(ctx.core, item, fn) ~= false
end

function Bridge.RegisterBridge(kind, impl)
    if kind ~= 'inventory' then error('tw-lib: server RegisterBridge supports inventory only') end
    Bridge.custom[kind] = { impl = impl, owner = GetInvokingResource() }
    Detect.custom[kind] = true
    Detect.cache[kind] = nil
end

AddEventHandler('onResourceStop', function(res)
    for kind, c in pairs(Bridge.custom) do
        if c.owner == res then
            Bridge.custom[kind], Detect.custom[kind], Detect.cache[kind] = nil, nil, nil
        end
    end
end)

for _, name in ipairs({ 'GetPlayer', 'GetIdentifier', 'GetName', 'AddMoney', 'RemoveMoney', 'GetPlayerMoney', 'addItem', 'removeItem', 'HasItem', 'GetInventory', 'GetPlayerJob', 'RegisterBridge', 'RegisterUsableItem' }) do
    exports(name, Bridge[name])
end
