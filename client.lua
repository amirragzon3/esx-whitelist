Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(200)
    end

    TriggerServerEvent('esx-whitelist:syncSession')
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)

    if Config.WhitelistEnabled then
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 255},
            multiline = true,
            args = {'SYSTEM', Config.ChatMessages.welcome}
        })
    end
end)
