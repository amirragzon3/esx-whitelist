--[[
  این فایل را داخل essentialmode لود کنید (در fxmanifest essentialmode):

  server_script '@esx-whitelist/integrations/essentialmode_server_addon.lua'

  سپس در essentialmode/server/main.lua این دو بخش را کامنت کنید:
  1) playerConnecting — بلوک kick وقتی steam نیست (حدود خط 136-139)
  2) RegisterNetEvent('fristJoinCheck') — کل AddEventHandler تا DropPlayer/LoadUser (حدود خط 142-164)

  در connectqueue: Config.RequireSteam = false
]]

local function getSteamIdForPlayer(src)
    if GetResourceState('esx-whitelist') ~= 'started' then
        return nil
    end
    return exports['esx-whitelist']:GetPlayerSteamId(src)
end

AddEventHandler('playerConnecting', function(name, setKickReason)
    if GetResourceState('esx-whitelist') ~= 'started' then
        return
    end

    local id = getSteamIdForPlayer(source)
    if id then
        return
    end

    for _, v in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, 6) == 'steam:' then
            return
        end
    end

    -- esx-whitelist بعد از لاگین/ثبت‌نام steam ساختگی می‌دهد؛ اینجا kick نکن
end)

RegisterNetEvent('fristJoinCheck')
AddEventHandler('fristJoinCheck', function()
    local src = source

    Citizen.CreateThread(function()
        local id = getSteamIdForPlayer(src)

        if not id then
            for _, v in ipairs(GetPlayerIdentifiers(src)) do
                if string.sub(v, 1, 6) == 'steam:' then
                    id = v
                    break
                end
            end
        end

        if not id then
            DropPlayer(src, 'Steam ID Peyda Nashod. Lotfan Steam ra baz konid ya ba server owner hamahang shavid.')
            return
        end

        LoadUser(id, src)
        TriggerClientEvent('enablePvp', src)
    end)
end)
