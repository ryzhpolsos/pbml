local lfs = require('lfs')
local json = require('json')

pbml = {
    modList = {},
    SET_VALUE_MODE_NORMAL = 0,
    SET_VALUE_MODE_ONCE = 1,
    SET_VALUE_MODE_CACHE = 1,
    customOS = {},
    pendingSetValue = {},
    pendingWaitFor = {},
    everyFrameHandlers = {},
    gameDirectory = '__PBML_GAME_DIRECTORY__',
    resourcesDirectory = '__PBML_RESOURCES_DIRECTORY__',
    dataDirectory = '__PBML_DATA_DIRECTORY__',
    pythonPath = '__PBML_PYTHON_PATH__',
    patcherPath = '__PBML_PATCHER_PATH__'
}

local util = dofile(pbml.resourcesDirectory .. '/pbml/util.lua')

for modFolder in lfs.dir(pbml.dataDirectory .. '/mods') do
    if modFolder ~= '.' and modFolder ~= '..' and util.isFileExists(pbml.dataDirectory .. '/mods/' .. modFolder .. '/mod.json') then
        local conf, _, msg = json.decodeFile(pbml.dataDirectory .. '/mods/' .. modFolder .. '/mod.json')

        if not conf then
            native.showAlert('PBML', msg, { 'OK' }, function() os.exit(1) end)
            return
        end

        conf.enabled = not util.isFileExists(pbml.dataDirectory .. '/mods/' .. modFolder .. '/.disabled')
        conf.folderName = modFolder
        table.insert(pbml.modList, conf)
    end
end