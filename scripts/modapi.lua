local util = dofile('Resources/pbml/util.lua')
local _realRequire = require
local modName = '__MOD_NAME__'

local function require(modname)
    if util.isFileExists('Resources/mods/' .. modName .. '/' .. modname .. '.lua') then
        return dofile('Resources/mods/' .. modName .. '/' .. modname .. '.lua')
    end

    if util.isFileExists('Resources/pbml/lib/' .. modname .. '.lua') then
        return dofile('Resources/pbml/lib/' .. modname .. '.lua')
    end

    return _realRequire(modname)
end