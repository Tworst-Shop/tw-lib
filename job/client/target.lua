TargetSystem = {}

local _type        = 'none'
local _enabled     = false
local _disabled    = false
local _initialized = false
local _registered  = { entities = {}, zones = {}, models = {}, bones = {} }

local _drawText = { items = {} }

local _DRAWTEXT_KEYS = {
    { key = 'E', code = 38 },
    { key = 'G', code = 47 },
    { key = 'H', code = 74 },
    { key = 'V', code = 0 },
    { key = 'U', code = 303 },
}

local function _generateDtId()
    return ('dt_%d_%d'):format(GetGameTimer(), math.random(100000, 999999))
end

local function _preference()
    local cfg = Config.TargetSystem
    if cfg then
        if cfg.enabled == false then return nil end
        return cfg.resource or 'auto', cfg.fallback or 'drawtext'
    end
    local handler = Config.InteractionHandler
    if handler == 'ox_target' or handler == 'ox-target' then return 'ox_target', 'drawtext' end
    if handler == 'qb-target' then return 'qb-target', 'drawtext' end
    return 'drawtext', 'drawtext'
end

local function _resolveType()
    local preference, fallback = _preference()
    if not preference then return 'none' end
    if preference == 'drawtext' then return 'drawtext' end

    if preference == 'ox_target' or preference == 'qb-target' then
        if GetResourceState(preference) == 'started' then return preference end
        print(('[%s] ^3WARN^7 %s requested but not running - falling back to %s'):format(GetCurrentResourceName(),
            preference, fallback))
        return fallback
    end

    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end
    return fallback
end

local PROMPT_HOLD_MS = 200
local _jobPromptAt = -PROMPT_HOLD_MS
local _drawingCards = false

local function _showCards(cards)
    if JobPromptShown then for _, card in ipairs(cards) do JobPromptShown(card.text) end end
    _drawingCards = true
    if Config.DrawText then Config.DrawText(cards) else exports['tw-lib']:ShowDrawText(cards, nil, Config.UI and Config.UI.primary) end
    _drawingCards = false
end

local function _watchJobPrompts(env)
    local draw3d = env.DrawText3D
    if type(draw3d) == 'function' then
        env.DrawText3D = function(x, y, z, text, ...)
            if type(text) == 'string' and text:find('%[%w+%]') then _jobPromptAt = GetGameTimer() end
            return draw3d(x, y, z, text, ...)
        end
    end
    local drawText = type(env.Config) == 'table' and env.Config.DrawText
    if type(drawText) == 'function' then
        env.Config.DrawText = function(...)
            if not _drawingCards then _jobPromptAt = GetGameTimer() end
            return drawText(...)
        end
    end
end

local function _hideCards()
    if Config.HideText then Config.HideText() else exports['tw-lib']:HideDrawText() end
end

local function _normalizeDrawTextOptions(options)
    if not options then return {} end
    if options[1] and type(options[1]) == 'table' then return options end
    return { options }
end

local function _maxDistance(options)
    local maxD = 2.0
    for _, opt in ipairs(_normalizeDrawTextOptions(options)) do
        local d = opt.distance or 2.0
        if d > maxD then maxD = d end
    end
    return maxD
end

local function _cleanLabel(label)
    if not label then return 'Interact' end
    return (label:gsub('^%[%w%]%s*', ''))
end

local function _icon(opt)
    return opt.icon or (Config.TargetSystem and Config.TargetSystem.icon) or 'fas fa-briefcase'
end

local function _buildOxOption(opt)
    local wrappedOnSelect = opt.onSelect and function(data)
        opt.onSelect(type(data) == 'table' and data.entity or data)
    end or nil
    return {
        name        = opt.name or ('tw_target_' .. tostring(math.random(100000))),
        label       = _cleanLabel(opt.label),
        icon        = _icon(opt),
        distance    = opt.distance or 2.0,
        onSelect    = wrappedOnSelect,
        canInteract = opt.canInteract,
        bones       = opt.bones or nil,
    }
end

local function _buildOxOptions(options)
    local built = {}
    for i, opt in ipairs(_normalizeDrawTextOptions(options)) do built[i] = _buildOxOption(opt) end
    return built
end

local _qbLabels = {}

local function _qbRemember(key, options)
    local map = _qbLabels[key] or {}
    for _, opt in ipairs(_normalizeDrawTextOptions(options)) do
        if opt.name then map[opt.name] = _cleanLabel(opt.label) end
    end
    _qbLabels[key] = map
end

local function _qbLabelsFor(key, optionNames)
    if not optionNames then
        _qbLabels[key] = nil
        return nil
    end
    local map, out = _qbLabels[key] or {}, {}
    for _, name in ipairs(type(optionNames) == 'table' and optionNames or { optionNames }) do
        out[#out + 1] = map[name] or name
        map[name] = nil
    end
    return out
end

local function _buildQbOptions(options)
    local built = {}
    for i, opt in ipairs(_normalizeDrawTextOptions(options)) do
        built[i] = {
            type        = 'client',
            label       = _cleanLabel(opt.label),
            icon        = _icon(opt),
            distance    = opt.distance or 2.0,
            action      = opt.onSelect,
            canInteract = opt.canInteract,
        }
    end
    return { options = built, distance = options.distance or (options[1] and options[1].distance) or 2.0 }
end

function TargetSystem.Init()
    _type = _resolveType()
    _enabled = _type ~= 'none'
    _initialized = true
    if Config.Debug then
        print(('[%s] TargetSystem: %s'):format(GetCurrentResourceName(), _type))
    end
end

function TargetSystem.IsInitialized() return _initialized end
function TargetSystem.IsEnabled() return _enabled end
function TargetSystem.GetType() return _type end

function TargetSystem.RemoveByRegId(regId)
    if _type == 'drawtext' and regId then
        _drawText.items[regId] = nil
    end
end

function TargetSystem.Disable()
    if not _enabled then return end
    _disabled = true
    if _type == 'ox_target' then
        exports.ox_target:disableTargeting(true)
    elseif _type == 'qb-target' then
        exports['qb-target']:AllowTargeting(false)
    end
end

function TargetSystem.Enable()
    if not _enabled then return end
    _disabled = false
    if _type == 'ox_target' then
        exports.ox_target:disableTargeting(false)
    elseif _type == 'qb-target' then
        exports['qb-target']:AllowTargeting(true)
    end
end

function TargetSystem.AddEntityTarget(entity, options, offset, regId)
    if not _enabled or not DoesEntityExist(entity) then return end

    if _type == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, _buildOxOptions(options))
    elseif _type == 'qb-target' then
        _qbRemember(entity, options)
        exports['qb-target']:AddTargetEntity(entity, _buildQbOptions(options))
    elseif _type == 'drawtext' then
        _drawText.items[regId or _generateDtId()] = {
            kind = 'entity', ref = entity, options = _normalizeDrawTextOptions(options), offset = offset,
        }
    end
    _registered.entities[entity] = true
end

function TargetSystem.RemoveEntityTarget(entity, optionNames)
    if not _enabled or not _registered.entities[entity] then return end

    if _type == 'ox_target' then
        if DoesEntityExist(entity) then
            exports.ox_target:removeLocalEntity(entity, optionNames)
        end
    elseif _type == 'qb-target' then
        local labels = _qbLabelsFor(entity, optionNames)
        if DoesEntityExist(entity) then
            exports['qb-target']:RemoveTargetEntity(entity, labels)
        end
    elseif _type == 'drawtext' then
        for id, item in pairs(_drawText.items) do
            if item.kind == 'entity' and item.ref == entity then
                _drawText.items[id] = nil
            end
        end
    end

    if not optionNames then
        _registered.entities[entity] = nil
    end
end

local function _qbKey(netId)
    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    return entity and entity ~= 0 and DoesEntityExist(entity) and entity or netId
end

function TargetSystem.AddNetworkedEntityTarget(netId, options, offset, regId)
    if not _enabled or not netId then return end

    if _type == 'ox_target' then
        exports.ox_target:addEntity(netId, _buildOxOptions(options))
        _registered.entities['net:' .. netId] = true
    elseif _type == 'qb-target' then
        _qbRemember('net:' .. netId, options)
        exports['qb-target']:AddTargetEntity(_qbKey(netId), _buildQbOptions(options))
        _registered.entities['net:' .. netId] = true
    elseif _type == 'drawtext' then
        _drawText.items[regId or _generateDtId()] = {
            kind = 'netEntity', ref = netId, options = _normalizeDrawTextOptions(options), offset = offset,
        }
        _registered.entities['net:' .. netId] = true
    end
end

function TargetSystem.RemoveNetworkedEntityTarget(netId, optionNames)
    if not _enabled or not netId then return end

    if _type == 'ox_target' then
        exports.ox_target:removeEntity(netId, optionNames)
        _registered.entities['net:' .. netId] = nil
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(_qbKey(netId), _qbLabelsFor('net:' .. netId, optionNames))
        if not optionNames then _registered.entities['net:' .. netId] = nil end
    elseif _type == 'drawtext' then
        for id, item in pairs(_drawText.items) do
            if item.kind == 'netEntity' and item.ref == netId then
                _drawText.items[id] = nil
            end
        end
        _registered.entities['net:' .. netId] = nil
    end
end

function TargetSystem.AddBoxZone(id, coords, size, options)
    if not _enabled then return end

    if _type == 'ox_target' then
        exports.ox_target:addBoxZone({
            coords = coords, size = size, rotation = options.rotation or 0.0, debug = Config.Debug or false,
            options = _buildOxOptions(options), name = id,
        })
    elseif _type == 'qb-target' then
        exports['qb-target']:AddBoxZone(id, coords, size.x or 1.0, size.y or 1.0, {
            name = id, heading = options.rotation or 0.0, debugPoly = Config.Debug or false,
            minZ = coords.z - (size.z or 1.0), maxZ = coords.z + (size.z or 1.0),
        }, _buildQbOptions(options))
    elseif _type == 'drawtext' then
        _drawText.items[id] = { kind = 'box', ref = { coords = coords, size = size }, options = _normalizeDrawTextOptions(options) }
    end
    _registered.zones[id] = true
end

function TargetSystem.RemoveBoxZone(id)
    if not _enabled or not _registered.zones[id] then return end

    if _type == 'ox_target' then
        exports.ox_target:removeZone(id)
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveZone(id)
    elseif _type == 'drawtext' then
        _drawText.items[id] = nil
    end
    _registered.zones[id] = nil
end

function TargetSystem.AddSphereZone(id, coords, radius, options)
    if not _enabled then return end

    if _type == 'ox_target' then
        exports.ox_target:addSphereZone({
            coords = coords, radius = radius, debug = Config.Debug or false, options = _buildOxOptions(options), name = id,
        })
    elseif _type == 'qb-target' then
        exports['qb-target']:AddCircleZone(id, coords, radius, {
            name = id, useZ = options.useZ ~= false, debugPoly = Config.Debug or false,
        }, _buildQbOptions(options))
    elseif _type == 'drawtext' then
        _drawText.items[id] = { kind = 'sphere', ref = { coords = coords, radius = radius }, options = _normalizeDrawTextOptions(options) }
    end
    _registered.zones[id] = true
end

function TargetSystem.RemoveSphereZone(id)
    TargetSystem.RemoveBoxZone(id)
end

local function _skipped(what, id)
    if Config.Debug then
        print(('[%s] ^3WARN^7 TargetSystem.%s(%s) is not available in drawtext mode'):format(GetCurrentResourceName(), what, id))
    end
end

function TargetSystem.AddModelTarget(id, models, options)
    if not _enabled then return end
    if type(models) == 'string' or type(models) == 'number' then models = { models } end
    local optionName = options.name or options.label or 'Interact'

    if _type == 'ox_target' then
        exports.ox_target:addModel(models, _buildOxOptions(options))
    elseif _type == 'qb-target' then
        exports['qb-target']:AddTargetModel(models, _buildQbOptions(options))
    else
        _skipped('AddModelTarget', id)
    end
    _registered.models[id] = { models = models, optionName = optionName }
end

function TargetSystem.RemoveModelTarget(id)
    local entry = _enabled and _registered.models[id]
    if not entry then return end

    if _type == 'ox_target' then
        exports.ox_target:removeModel(entry.models, entry.optionName)
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveTargetModel(entry.models, entry.optionName)
    end
    _registered.models[id] = nil
end

function TargetSystem.AddBoneTarget(id, bones, options)
    if not _enabled then return end
    if type(bones) == 'string' then bones = { bones } end
    local optionName = options.name or options.label or 'Interact'

    if _type == 'ox_target' then
        local oxOpts = _buildOxOptions(options)
        for _, opt in ipairs(oxOpts) do opt.bones = bones end
        exports.ox_target:addGlobalVehicle(oxOpts)
    elseif _type == 'qb-target' then
        exports['qb-target']:AddTargetBone(bones, _buildQbOptions(options))
    else
        _skipped('AddBoneTarget', id)
    end
    _registered.bones[id] = { bones = bones, optionName = optionName, kind = 'bone' }
end

function TargetSystem.RemoveBoneTarget(id)
    local entry = _enabled and _registered.bones[id]
    if not entry then return end

    if _type == 'ox_target' then
        exports.ox_target:removeGlobalVehicle(entry.optionName)
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveTargetBone(entry.bones)
    end
    _registered.bones[id] = nil
end

function TargetSystem.AddGlobalVehicle(id, options)
    if not _enabled then return end
    local optionName = options.name or options.label or ('tw_gv_' .. id)

    if _type == 'ox_target' then
        exports.ox_target:addGlobalVehicle(_buildOxOptions(options))
    elseif _type == 'qb-target' then
        exports['qb-target']:AddGlobalVehicle(_buildQbOptions(options))
    else
        _skipped('AddGlobalVehicle', id)
    end
    _registered.bones[id] = { optionName = optionName, kind = 'globalVehicle' }
end

function TargetSystem.RemoveGlobalVehicle(id)
    local entry = _enabled and _registered.bones[id]
    if not entry or entry.kind ~= 'globalVehicle' then return end

    if _type == 'ox_target' then
        exports.ox_target:removeGlobalVehicle(entry.optionName)
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveGlobalVehicle(entry.optionName)
    end
    _registered.bones[id] = nil
end

function TargetSystem.AddGlobalPlayer(id, options)
    if not _enabled then return end
    local optionName = options.name or options.label or ('tw_gp_' .. id)

    if _type == 'ox_target' then
        exports.ox_target:addGlobalPlayer(_buildOxOptions(options))
    elseif _type == 'qb-target' then
        exports['qb-target']:AddGlobalPlayer(_buildQbOptions(options))
    else
        _skipped('AddGlobalPlayer', id)
    end
    _registered.bones[id] = { optionName = optionName, kind = 'globalPlayer' }
end

function TargetSystem.RemoveGlobalPlayer(id)
    local entry = _enabled and _registered.bones[id]
    if not entry or entry.kind ~= 'globalPlayer' then return end

    if _type == 'ox_target' then
        exports.ox_target:removeGlobalPlayer(entry.optionName)
    elseif _type == 'qb-target' then
        exports['qb-target']:RemoveGlobalPlayer(entry.optionName)
    end
    _registered.bones[id] = nil
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or not _enabled then return end
    for entity in pairs(_registered.entities) do
        if type(entity) == 'string' then
            TargetSystem.RemoveNetworkedEntityTarget(tonumber(entity:sub(5)))
        else
            TargetSystem.RemoveEntityTarget(entity)
        end
    end
    for id in pairs(_registered.zones) do TargetSystem.RemoveBoxZone(id) end
    for id in pairs(_registered.models) do TargetSystem.RemoveModelTarget(id) end
    for id, entry in pairs(_registered.bones) do
        if entry.kind == 'globalVehicle' then
            TargetSystem.RemoveGlobalVehicle(id)
        elseif entry.kind == 'globalPlayer' then
            TargetSystem.RemoveGlobalPlayer(id)
        else
            TargetSystem.RemoveBoneTarget(id)
        end
    end
end)

CreateThread(function()
    Wait(500)
    TargetSystem.Init()
end)

local function _entityPoint(entity, offset)
    if offset then
        return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    end
    return GetEntityCoords(entity)
end

local function _matches(playerCoords)
    local matches = {}
    for _, item in pairs(_drawText.items) do
        local coords, entity, rangeLimit
        if item.kind == 'entity' then
            if DoesEntityExist(item.ref) then
                entity = item.ref
                coords = _entityPoint(entity, item.offset)
            end
        elseif item.kind == 'netEntity' then
            if NetworkDoesNetworkIdExist(item.ref) then
                local e = NetworkGetEntityFromNetworkId(item.ref)
                if e and e ~= 0 and DoesEntityExist(e) then
                    entity = e
                    coords = _entityPoint(entity, item.offset)
                end
            end
        else
            coords = item.ref.coords
        end

        if coords then
            if item.kind == 'sphere' then
                rangeLimit = item.ref.radius
            elseif item.kind == 'box' then
                rangeLimit = math.max(item.ref.size.x or 1.0, item.ref.size.y or 1.0, item.ref.size.z or 1.0)
            else
                rangeLimit = _maxDistance(item.options)
            end
            local d = #(playerCoords - coords)
            if d < rangeLimit then
                for _, opt in ipairs(item.options) do
                    if d < (opt.distance or rangeLimit) then
                        local ok, can = true, true
                        if opt.canInteract then ok, can = pcall(opt.canInteract, entity) end
                        if ok and can then
                            matches[#matches + 1] = { distance = d, label = opt.label or 'Interact', onSelect = opt.onSelect, entity = entity }
                        end
                    end
                end
            end
        end
    end

    table.sort(matches, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.label < b.label
    end)
    local unique, seen = {}, {}
    for _, m in ipairs(matches) do
        if not seen[m.label] and #unique < #_DRAWTEXT_KEYS then
            seen[m.label] = true
            unique[#unique + 1] = m
        end
    end
    return unique
end

CreateThread(function()
    while not _initialized do Wait(100) end
    _watchJobPrompts(_ENV)
    local isShowing = false
    local function hide()
        if isShowing then
            _hideCards()
            isShowing = false
        end
    end

    while true do
        local ped = PlayerPedId()
        if _type ~= 'drawtext' then
            hide()
            Wait(2000)
        elseif _disabled then
            hide()
            Wait(500)
        elseif IsPedDeadOrDying(ped, 1) then
            hide()
            Wait(1000)
        elseif GetGameTimer() - _jobPromptAt < PROMPT_HOLD_MS then
            hide()
            Wait(50)
        else
            local matches = _matches(GetEntityCoords(ped))
            if #matches > 0 then
                local cards = {}
                for i, m in ipairs(matches) do
                    cards[i] = { key = _DRAWTEXT_KEYS[i].key, text = m.label }
                end
                _showCards(cards)
                isShowing = true
                for i, m in ipairs(matches) do
                    if IsControlJustReleased(0, _DRAWTEXT_KEYS[i].code) and m.onSelect then
                        pcall(m.onSelect, m.entity)
                    end
                end
                Wait(0)
            else
                hide()
                Wait(250)
            end
        end
    end
end)
