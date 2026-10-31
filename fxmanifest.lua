fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bdev-christmas'
description 'BDevelopment - Christmas advent calendar, daily wheel and unwrappable presents'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/art.js',
    'html/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'qbx_core',
}
