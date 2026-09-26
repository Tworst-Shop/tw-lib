fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tw-lib'
author 'tworst-script'
description 'Tworst shared library: framework bridges and customer settings that survive updates'
version '1.0.0'

tw_lib_config 'config.lua'

dependency 'oxmysql'

shared_scripts {
    'locales/*.lua',
    'shared/merge.lua',
    'shared/version.lua',
    'shared/detect.lua',
}

server_scripts {
    'config.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/store.lua',
    'server/schema.lua',
    'server/ledger.lua',
    'server/stats.lua',
    'server/admin.lua',
    'server/bridge.lua',
    'server/configfile.lua',
    'server/import.lua',
    'server/boot.lua',
    'server/update.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/interaction.lua',
    'client/admin.lua',
}

ui_page 'html/index.html'

files {
    'init.lua',
    'shared/merge.lua',
    'job/client/*.lua',
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/js/pages/*.js',
    'html/vendor/*.js',
    'html/fonts/*.woff2',
    'html/job/*.js',
    'html/job/*.css',
    'html/job/font/*',
    'html/job/img/*.svg',
    'html/job/img/Icon/*.svg',
    'html/job/sounds/*',
}

escrow_ignore {
	'client/*.lua',
	'config.lua',
	'init.lua',
	'job/client/*.lua',
	'job/server/*.lua',
	'locales/*.lua',
	'server/*.lua',
	'shared/*.lua',
}
