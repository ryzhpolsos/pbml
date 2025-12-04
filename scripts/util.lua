local _M = {}

function _M.getPSValue(path)
    local parts = {}
    local current = _G

    for prt in string.gmatch(path, '[^%.]+') do
        current = current[prt]

        if(current == nil) then return nil end
    end

    return current
end

function _M.setPSValue(path, value)
    local parts = {}
    local current = _G

    for prt in string.gmatch(path, '[^%.]+') do table.insert(parts, prt) end

    for i, v in ipairs(parts) do
        if(i == #parts) then
            current[v] = value
        else
            current = current[v]
        end
    end
end

function _M.isFileExists(filePath)
    local file = io.open(filePath, 'r')
    if file == nil then return false end
    file:close()
    return true
end

function _M.readFile(filePath)
    local file = io.open(filePath, 'r')
    if file == nil then return end
    local data = file:read('*all')
    file:close()
    return data
end

return _M