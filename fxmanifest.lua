fx_version 'cerulean'
game 'gta5'

author 'amirragzon3'
description 'A lightweight, database-driven whitelist system for FiveM servers running the ESX Framework'
version '1.0.0'

repository 'https://github.com/amirragzon3/esx-whitelist'

-- ESX Framework dependency
dependencies {
  'es_extended',
  'oxmysql'
}

shared_script 'config.lua'

server_scripts {
  'server.lua'
}

client_scripts {
  'client.lua'
}

-- Lua 5.4 support
lua54 'yes'

-- Server exports for integration
server_exports {
  'IsPlayerWhitelisted',
  'AddToWhitelist',
  'RemoveFromWhitelist'
}
