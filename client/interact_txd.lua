-- 3D ETKILESIM dokulari (tw-lib/interact): runtime sozluk 'twlib_interact' tw-lib kaynaginda bir kez kurulur;
-- etkilesimi kullanan is kaynaklari (client_scripts '@tw-lib/interact/client/interacts.lua') adiyla cizer.
local txd = CreateRuntimeTxd('twlib_interact')
for _, name in ipairs({ 'point', 'key', 'cap', 'px', 'crosshair', 'font' }) do
    CreateRuntimeTextureFromImage(txd, name, ('interact/assets/prompt/%s.png'):format(name))
end
