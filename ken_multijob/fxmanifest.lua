fx_version 'cerulean'
game 'gta5'

author 'Ken Mondragon | https://discord.gg/saNy47Db2y '
description 'ESX Multi-Job System'
version '1.0.0'

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib'
}
