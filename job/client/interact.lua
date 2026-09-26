local api = {}

local _registry = {}

local function _key(id, ref)
    return ref and ('%s@%s'):format(id, ref) or id
end

local function _generateId()
    return ('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return ('%x'):format(v)
    end)
end

local function _convertOption(opt, baseId, idx, defaultDist)
    local name = opt.name or ('%s_%d'):format(baseId, idx or 1)
    local action, args, event, serverEvent = opt.action, opt.args, opt.event, opt.serverEvent

    local onSelect = function(entity)
        if action then
            local coords = (entity and DoesEntityExist(entity)) and GetEntityCoords(entity) or nil
            action(entity, coords, args)
        elseif serverEvent then
            TriggerServerEvent(serverEvent, args)
        elseif event then
            TriggerEvent(event, opt)
        end
    end

    local canInteract = opt.canInteract and function(entity)
        local ok, res = pcall(opt.canInteract, entity, nil, args)
        return ok and res
    end or nil

    return {
        name        = name,
        label       = opt.label,
        icon        = opt.icon,
        distance    = opt.interactDst or opt.distance or defaultDist or 2.0,
        onSelect    = onSelect,
        canInteract = canInteract,
        bones       = opt.bones,
    }, name
end

local function _convertOptions(options, baseId, defaultDist)
    if not options then return {}, {} end
    local list = (options[1] and type(options[1]) == 'table') and options or { options }
    local converted, names = {}, {}
    for i, opt in ipairs(list) do
        converted[i], names[i] = _convertOption(opt, baseId, i, defaultDist)
    end
    return converted, names
end

function api.addInteraction(data)
    if not data or not data.coords or not data.options then return end
    local id = data.id or _generateId()
    local radius = data.interactDst or data.distance or 2.0
    local options, names = _convertOptions(data.options, id, radius)
    TargetSystem.AddSphereZone(id, data.coords, radius, options)
    _registry[id] = { kind = 'coords', key = id, optionNames = names }
    return id
end
exports('AddInteraction', api.addInteraction)

function api.addLocalEntityInteraction(data)
    if not data or not data.entity or not DoesEntityExist(data.entity) then return end
    local id = data.id or _generateId()
    local options, names = _convertOptions(data.options, id, data.interactDst or data.distance)
    local key = _key(id, data.entity)
    TargetSystem.AddEntityTarget(data.entity, options, data.offset, key)
    _registry[key] = { id = id, kind = 'localEntity', key = data.entity, optionNames = names }
    return id
end
exports('AddLocalEntityInteraction', api.addLocalEntityInteraction)

function api.addEntityInteraction(data)
    if not data then return end
    local id = data.id or _generateId()
    local options, names = _convertOptions(data.options, id, data.interactDst or data.distance)

    if data.netId then
        local key = _key(id, data.netId)
        TargetSystem.AddNetworkedEntityTarget(data.netId, options, data.offset, key)
        _registry[key] = { id = id, kind = 'netEntity', netId = data.netId, optionNames = names }
        return id
    end
    if data.entity and DoesEntityExist(data.entity) then
        local key = _key(id, data.entity)
        TargetSystem.AddEntityTarget(data.entity, options, data.offset, key)
        _registry[key] = { id = id, kind = 'entity', key = data.entity, optionNames = names }
        return id
    end
end
exports('AddEntityInteraction', api.addEntityInteraction)

function api.addEntityBoneInteraction()
    print('AddEntityBoneInteraction is deprecated, use AddEntityInteraction')
end
exports('AddEntityBoneInteraction', api.addEntityBoneInteraction)

function api.addModelInteraction(data)
    if not data or not data.model then return end
    local id = data.id or _generateId()
    local options, names = _convertOptions(data.options, id)
    TargetSystem.AddModelTarget(id, data.model, options)
    _registry[id] = { kind = 'model', key = data.model, optionNames = names }
    return id
end
exports('AddModelInteraction', api.addModelInteraction)

function api.addGlobalVehicleInteraction(data)
    if not data or not data.options then return end
    local id = data.id or _generateId()
    local options, names = _convertOptions(data.options, id)
    if data.bone then
        TargetSystem.AddBoneTarget(id, data.bone, options)
        _registry[id] = { kind = 'boneVehicle', key = id, optionNames = names }
    else
        TargetSystem.AddGlobalVehicle(id, options)
        _registry[id] = { kind = 'globalVehicle', key = id, optionNames = names }
    end
    return id
end
exports('AddGlobalVehicleInteraction', api.addGlobalVehicleInteraction)

function api.addGlobalPlayerInteraction(data)
    if not data or not data.options then return end
    local id = data.id or _generateId()
    local options, names = _convertOptions(data.options, id)
    TargetSystem.AddGlobalPlayer(id, options)
    _registry[id] = { kind = 'globalPlayer', key = id, optionNames = names }
    return id
end
exports('addGlobalPlayerInteraction', api.addGlobalPlayerInteraction)

local function _removeKey(key)
    local entry = key and _registry[key]
    if not entry then return end
    local id = key

    if TargetSystem.GetType() == 'drawtext' then
        TargetSystem.RemoveByRegId(key)
    elseif entry.kind == 'coords' then
        TargetSystem.RemoveSphereZone(id)
    elseif entry.kind == 'localEntity' or entry.kind == 'entity' then
        TargetSystem.RemoveEntityTarget(entry.key, entry.optionNames)
    elseif entry.kind == 'netEntity' then
        TargetSystem.RemoveNetworkedEntityTarget(entry.netId, entry.optionNames)
    elseif entry.kind == 'model' then
        TargetSystem.RemoveModelTarget(id)
    elseif entry.kind == 'globalVehicle' then
        TargetSystem.RemoveGlobalVehicle(id)
    elseif entry.kind == 'boneVehicle' then
        TargetSystem.RemoveBoneTarget(id)
    elseif entry.kind == 'globalPlayer' then
        TargetSystem.RemoveGlobalPlayer(id)
    end
    _registry[key] = nil
end

local function _removeById(id)
    if not id then return end
    for key, entry in pairs(_registry) do
        if key == id or entry.id == id then _removeKey(key) end
    end
end

local function _removeFrom(ref, id)
    if ref and _registry[_key(id, ref)] then return _removeKey(_key(id, ref)) end
    if not ref then _removeById(id) end
end

function api.removeInteraction(id) _removeById(id) end
exports('RemoveInteraction', api.removeInteraction)

function api.removeInteractionByEntity()
    print('RemoveInteractionByEntity is deprecated, use RemoveLocalEntityInteraction')
end
exports('RemoveInteractionByEntity', api.removeInteractionByEntity)

function api.removeLocalEntityInteraction(entity, id) _removeFrom(entity, id) end
exports('RemoveLocalEntityInteraction', api.removeLocalEntityInteraction)

function api.removeModelInteraction(_, id) _removeById(id) end
exports('RemoveModelInteraction', api.removeModelInteraction)

function api.removeEntityInteraction(netId, id) _removeFrom(netId, id) end
exports('RemoveEntityInteraction', api.removeEntityInteraction)

function api.removeGlobalVehicleInteraction(id) _removeById(id) end
exports('RemoveGlobalVehicleInteraction', api.removeGlobalVehicleInteraction)

function api.removeGlobalPlayerInteraction(id) _removeById(id) end
exports('RemoveGlobalPlayerInteraction', api.removeGlobalPlayerInteraction)

function api.removeInteractionOption(id, name)
    if not id then return end
    if not name then return _removeById(id) end
    for key, entry in pairs(_registry) do
        if key == id or entry.id == id then
            if entry.kind == 'localEntity' or entry.kind == 'entity' then
                TargetSystem.RemoveEntityTarget(entry.key, name)
            elseif entry.kind == 'netEntity' then
                TargetSystem.RemoveNetworkedEntityTarget(entry.netId, name)
            else
                _removeKey(key)
            end
        end
    end
end
exports('RemoveInteractionOption', api.removeInteractionOption)

function api.updateInteraction() end
exports('UpdateInteraction', api.updateInteraction)

function api.disable(state)
    if state then TargetSystem.Disable() else TargetSystem.Enable() end
    LocalPlayer.state:set('interactionsDisabled', state, false)
end
exports('Disable', api.disable)

RegisterNetEvent('interact:removeEntity', function() end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for key in pairs(_registry) do _removeKey(key) end
end)
