local txd = CreateRuntimeTxd('twlib_interact')
for _, name in ipairs({ 'point', 'key', 'cap', 'px', 'crosshair', 'font' }) do
    CreateRuntimeTextureFromImage(txd, name, ('interact/assets/prompt/%s.png'):format(name))
end
