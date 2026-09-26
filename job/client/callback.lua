local requestId = 0
local pending = {}

function TriggerServerCallback(eventName, ...)
    local prom = promise.new()
    local id = requestId
    requestId = requestId + 1
    pending[id] = function(...) prom:resolve(...) end
    TriggerServerEvent(_event('triggerServerCallback'), eventName, id, GetInvokingResource() or "unknown", ...)
    return Citizen.Await(prom)
end

function TriggerCallback(name, data)
    return TriggerServerCallback(name, data)
end

RegisterNetEvent(_event('serverCallback'), function(id, invoker, ...)
    if not pending[id] then
        return print(("[^1ERROR^7] Server Callback with requestId ^5%s^7 Was Called by ^5%s^7 but does not exist.")
            :format(tostring(id), tostring(invoker)))
    end
    pending[id](...)
    pending[id] = nil
end)
