fx_version 'cerulean'
game 'gta5'

author 'Mirza'
description 'Whitelist with Login/Register panel (Adaptive Card deferrals)'
version '3.3.0'

shared_script 'config.lua'

-- Use ONE of these lines to match your server (optional; auto-detect works without it):
-- server_scripts { '@mysql-async/lib/MySQL.lua', 'server.lua' }
-- server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
server_script 'server.lua'
client_script 'client.lua'

dependencies {
    'mysql-async'
}

server_exports {
    'GetPlayerSteamId',
    'GetAccountUsername',
    'GetSyntheticSteam',
    'HasRealSteam',
    'EnsureSyntheticSteam'
}
