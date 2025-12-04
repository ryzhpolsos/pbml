local util = dofile('Resources/pbml/util.lua')

pbml = {
    SET_VALUE_MODE_NORMAL = 0,
    SET_VALUE_MODE_ONCE = 1,
    SET_VALUE_MODE_CACHE = 1,
    customOS = {},
    pendingSetValue = {},
    everyFrameHandlers = {}
}

function pbml:setValue(value, callback, mode)
    table.insert(self.pendingSetValue, { value = value, callback = callback, mode = mode })
end

function pbml:addEveryFrameHandler(callback)
    table.insert(self.everyFrameHandlers, callback)
end

function pbml:addOS(osTableEntry, index)
    local strNumber = tostring(#self.customOS)
    local osId

    if string.len(strNumber) == 1 then
        osId = 'W0' .. strNumber
    else
        osId = 'W' .. strNumber
    end

    self:setValue('Game.OS_Table', function(osTable)
        osTable[osId] = osTableEntry
        return osTable
    end, self.SET_VALUE_MODE_ONCE)

    self:setValue('Game.OS_Installed_List', function(list)
        return list .. ' ' .. osId
    end, self.SET_VALUE_MODE_ONCE)

    self:setValue('Game.OS_Number_of_installed', function(number)
        return number + 1
    end, self.SET_VALUE_MODE_ONCE)

    table.insert(self.customOS, { id = osId, index = index })
end

function _w_pbml_ProcessPBOSList(osList)
    for _, v in ipairs(pbml.customOS) do
        if v.index == nil then
            table.insert(osList, v.id)
        else
            table.insert(osList, v.index, v.id)
        end
    end
end

local function onEveryFrame(_)
    for i, v in ipairs(pbml.pendingSetValue) do
        local value = util.getPSValue(v.value)

        if value ~= nil then
            local val
            if type(v.callback) == 'function' then
                val = v.callback(value)

                if v.mode == pbml.SET_VALUE_MODE_CACHE then
                    v.callback = val
                end
            else
                val = v.callback
            end

            util.setPSValue(v.value, val)

            if v.mode == pbml.SET_VALUE_MODE_ONCE then
                table.remove(pbml.pendingSetValue, i)
            end
        end
    end

    for _, v in ipairs(pbml.everyFrameHandlers) do
        v()
    end
end

Runtime:addEventListener('enterFrame', onEveryFrame)

local lfs = require('lfs')

local logFile = io.open('Resources/pbml/log.txt', 'a')
if logFile == nil then return end

logFile:write('Modloader started\n')

for modFolder in lfs.dir('Resources/mods') do
    if modFolder == '.' or modFolder == '..' then
    else
        logFile:write('Loading mod: ' .. modFolder .. '\n')

        local function modWrapper(modFolder)
            local modCode = util.readFile('Resources/mods/' .. modFolder .. '/main.lua')
            local modApi = util.readFile('Resources/pbml/modapi.lua')
            modApi = string.gsub(modApi, '__MOD_NAME__', modFolder)

            modCode = modApi .. '\n\n' .. modCode

            local modFunc, err = loadstring(modCode)

            if modFunc ~= nil then
                modFunc()
                return true, nil
            else
                return false, err
            end
        end

        local status, err = modWrapper(modFolder)

        if not status then
            local msg = 'Failed to load mod "' .. modFolder .. '": ' .. tostring(err)

            logFile:write(msg)
            logFile:flush()
            logFile:close()

            native.showAlert('PBML', msg, { 'OK' }, function() os.exit(1) end)
            return
        end

        logFile:write('Loaded mod: ' .. modFolder .. '\n')
    end
end

logFile:close()
