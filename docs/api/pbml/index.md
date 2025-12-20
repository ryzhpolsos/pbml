# `pbml` table
`pbml` table contains different functions for making mod creation more comfortable.

## Methods

### `pbml.waitFor(value, callback)`
Invokes the callback function when the specified value becomes available.

#### Arguments

| Name       | Type       | Description                                                                                          | Example                             |
| ---------- | ---------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `value`    | `string`   | String representation of value path, starting with a global table name                               | `"Game.OS_Table.PXP"`               |
| `callback` | `function` | Functions that is called when the value becomes available. The value is passes as its first argument | `function (value) print(value) end` |
#### Return value
`nil`

### `pbml.setValue(value, callback [, mode])`
Sets the specified value when it becomes available.

#### Arguments

| Name       | Type                | Description                                                                                                                                                                                                                                                                                                                                                                                                | Example                               |
| ---------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `value`    | `string`            | String representation of value path, starting with a global table name                                                                                                                                                                                                                                                                                                                                     | `"Game.OS_Table.PXP.FontStyle.Comic"` |
| `callback` | `function` or `any` | If this parameter is a function, it will be called with original value as first argument, and modified value will be set to its return value. Otherwise, original value will be overwritten with value of this parameter                                                                                                                                                                                   | `function(val) return val + 1 end`    |
| `mode`     | `number`            | If presented, this parameter must be one of the following values: `pbml.SET_VALUE_MODE_NORMAL`, `pbml.SET_VALUE_MODE_ONCE`, `pbml.SET_VALUE_MODE_CACHE`<br><br><ul><li>`pbml.SET_VALUE_MODE_NORMAL` (default): set value every frame</li><li>`pbml.SET_VALUE_MODE_ONCE`: set value once</li><li>`pbml.SET_VALUE_MODE_CACHE`: if `callback` is a function, call it only one time and cache result</li></ul> | `pbml.SET_VALUE_MODE_NORMAL`          |

#### Return value
`nil`

### `pbml.addEveryFrameHandler(callback)`
Executes `callback` every frame.

#### Arguments

|Name|Type|Description|Example|
|---|---|---|---|
|`callback`|`function`|Function that will be called every frame|`function() print("every frame") end`|

#### Return value
`nil`

### `pbml.addOS(osTableEntry [, index])`
Adds a new entry to the Progressbar OS list and allows user to boot it.

#### Arguments

|Name|Type|Description|Example|
|---|---|---|---|
|`osTableEntry`|[`_OSTableEntry`](OSTableEntry.md)|Information about new OS|[`_OSTableEntry`](OSTableEntry.md)|
|`index`|`number`|If presented, new OS will be added into this position in list|`8`|

#### Return value
`nil`
