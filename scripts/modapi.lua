local util = inject('pbml/util.lua')
local _realRequire = require
local modName = '__MOD_NAME__'

local mod = {}

mod.name = modName
mod.directory = pbml.dataDirectory .. '/mods/' .. modName

function mod:getPath(path)
    return mod.directory .. '/' .. path
end

local function require(modname)
    if util.isFileExists(pbml.dataDirectory .. '/mods/' .. modName .. '/' .. modname .. '.-lua') then
        return util.doFile(pbml.dataDirectory .. '/mods/' .. modName .. '/' .. modname .. '.-lua')
    end

    if util.isFileExists(pbml.dataDirectory .. '/pbml/lib/' .. modname .. '.-lua') then
        return util.doFile(pbml.dataDirectory .. '/pbml/lib/' .. modname .. '.-lua')
    end

    return _realRequire(modname)
end