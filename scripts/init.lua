function inject(path)
    if system.getInfo("platform") == "android" then
        local file = io.open(system.pathForFile(path))
        local script = file:read("*a")
        file:close()

        return loadstring(script)()
    else
        return dofile(pbml.resourcesDirectory .. '/' .. path)
    end    
end

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

local util = inject('pbml/util.lua')

if not util.isFileExists(pbml.dataDirectory) then
    local success, err = lfs.mkdir(pbml.dataDirectory)

    if not success then
        native.showAlert('PBML', err, { 'OK' }, function() os.exit(1) end)
        return
    end
end

if not util.isFileExists(pbml.dataDirectory .. '/pbml') then
    local success, err = lfs.mkdir(pbml.dataDirectory .. '/pbml')

    if not success then 
        native.showAlert('PBML', err, { 'OK' }, function() os.exit(1) end)
        return
    end
end

if not util.isFileExists(pbml.dataDirectory .. '/mods') then
    local success, err = lfs.mkdir(pbml.dataDirectory .. '/mods')

    if not success then 
        native.showAlert('PBML', err, { 'OK' }, function() os.exit(1) end)
        return
    end
end

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