local util = dofile(pbml.resourcesDirectory .. '/pbml/util.lua')

function pbml.setValue(value, callback, mode)
    table.insert(pbml.pendingSetValue, { value = value, callback = callback, mode = mode })
end

function pbml.addEveryFrameHandler(callback)
    table.insert(pbml.everyFrameHandlers, callback)
end

function pbml.waitFor(value, callback)
    table.insert(pbml.pendingWaitFor, { value = value, callback = callback })
end

function pbml.addOS(osTableEntry, index)
    local strNumber = tostring(#pbml.customOS)
    local osId

    if string.len(strNumber) == 1 then
        osId = 'W0' .. strNumber
    else
        osId = 'W' .. strNumber
    end

    pbml.setValue('Game.OS_Table', function(osTable)
        osTable[osId] = osTableEntry
        return osTable
    end, pbml.SET_VALUE_MODE_ONCE)

    pbml.setValue('Game.OS_Installed_List', function(list)
        return list .. ' ' .. osId
    end, pbml.SET_VALUE_MODE_ONCE)

    pbml.setValue('Game.OS_Number_of_installed', function(number)
        return number + 1
    end, pbml.SET_VALUE_MODE_ONCE)

    table.insert(pbml.customOS, { id = osId, index = index })
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
    for i, v in ipairs(pbml.pendingWaitFor) do
        local value = util.getPSValue(v.value)

        if value ~= nil then
            v.callback(value)
            table.remove(pbml.pendingWaitFor, i)
        end
    end

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

local function onKeyPress(event)
    if event.keyName == 'm' and event.phase == 'up' and event.isCtrlDown then
        local managerUi = dofile(pbml.resourcesDirectory .. '/pbml/manager.lua')
        managerUi()
    end
end

Runtime:addEventListener('enterFrame', onEveryFrame)
Runtime:addEventListener('key', onKeyPress)

local logFile = io.open(pbml.dataDirectory .. '/pbml/log.txt', 'a')
if logFile == nil then return end

logFile:write('Modloader started\n')

for _, mod in ipairs(pbml.modList) do
    if mod.enabled then
        local modFolder = mod.folderName

        logFile:write('Loading mod: ' .. modFolder .. '\n')

        local function modWrapper(modFolder)
            local modCode = util.readFile(pbml.dataDirectory .. '/mods/' .. modFolder .. '/main.lua')
            local modApi = util.readFile(pbml.resourcesDirectory .. '/pbml/modapi.lua')
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