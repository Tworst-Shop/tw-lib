local callbacks = {}

function RegisterServerCallback(eventName, callback)
    callbacks[eventName] = callback
end

RegisterNetEvent(_event('triggerServerCallback'), function(eventName, requestId, invoker, ...)
    local callback = callbacks[eventName]
    if not callback then
        return print(("[^1ERROR^7][%s] Server Callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(
            GetCurrentResourceName(), tostring(eventName), tostring(invoker)))
    end

    local src = source
    callback(src, function(...)
        TriggerClientEvent(_event('serverCallback'), src, requestId, invoker, ...)
    end, ...)
end)
