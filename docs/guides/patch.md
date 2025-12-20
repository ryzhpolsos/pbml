# How to create patches

**Patches** are powerful feature in PBML that allows mod developers to change the game code. Patch files are JSON-formatted and can contain multiple patches.

## Patch file structure

A patch file contains two blocks: metadata and patch list. Metadata block is used to provide information about patches included in file, and patch list specifies which changes the file makes in game.

Basic structure of patch file is:
```json
{
	"name": "Name of the patch",
	"version": "Version string",
	"author": "Name of author of the patch",
	"description": "Description of the patch",
	"patches": []
}
```

`patches` array is filled with special objects. Each object represents one patch.

## Patch object

Patch object can contain these properties:

| Name           | Type                   | Required | Description                                                              | Example                                   |
| -------------- | ---------------------- | -------- | ------------------------------------------------------------------------ | ----------------------------------------- |
| `functionName` | `string`               | Yes      | Function name for patch to work in                                       | `main/f0`                                 |
| `addRegisters` | `number`               | No       | Amount of additional registers that patch will use                       | `4`                                       |
| `addConstants` | `Array<string>`        | No       | List of constants that will be added to function                         | `["\"String constant\", "7"]`             |
| `set`          | `Hash<string, string>` | No       | Variables that will be declared at startup. Value expansion is supported | `{ "counter": 0, "anotherVar": "hello" }` |
| `actions`      | `Array<Action>`        | Yes      | List of actions                                                          |                                           |

## Action object

Action object can contain these properties:

| Name           | Type                   | Required | Description                                                                                                                                                                                                                                                                                                                                       | Example                                                    |
| -------------- | ---------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `ifDefined`    | `Array<string>`        | No       | List of variable names. The action will be executed only if all these varaibles are declared                                                                                                                                                                                                                                                      | `["someFlag", "anotherFlag"]`                              |
| `if`           | `string`               | No       | Python logical expression. The action will be executed only if it returns `True`. Available operations are: `+`, `-`, `*`, `/`, `()`, `and`, `or`, `not`, `==`, `>`, `<`, `>=`, `<=`. Single or double quotes are allowed for strings. Boolean constants are `True` and `False` (note that first letter is capital). Value expansion is supported | `"(${counter} > 300) and ${someFlag}"`                     |
| `match`        | `string`               | Yes      | Regular expression. The action will be executed only if matches current line of code. Value expansion is supported                                                                                                                                                                                                                                | `"\\.constant\\s+(k\\d+)\\s+\"print\""`                    |
| `processAll`   | `bool`                 | No       | If presented and set to `true`, this action will be executed every time conditions are met. Otherwise, it will be executed only once                                                                                                                                                                                                              | `true`                                                     |
| `replace`      | `string`               | No       | If presented, the patcher will replace current line of code with this value. Value expansion is supported                                                                                                                                                                                                                                         | `".constant $g1 \"dbgPrint\""`                             |
| `remove`       | `bool`                 | No       | If presented, the patcher will remove current line of code                                                                                                                                                                                                                                                                                        | `true`                                                     |
| `set`          | `Hash<string, string>` | No       | Variables that will be declared when this action executes. Value expansion is supported                                                                                                                                                                                                                                                           | `{ "constantNumber": "$g1" }`                              |
| `code`         | `Array<string>`        | No       | List of code lines that will be added. Value expansion is supported                                                                                                                                                                                                                                                                               | `[ "getglobal $r0 $k-", "loadk $r1 $k1", "call $r0 2 1" ]` |
| `insertBefore` | `bool`                 | No       | If presented and set to `true`, lines from the `code` property will be added before current line, otherwise they will be added after it                                                                                                                                                                                                           | `bool`                                                     |

## Value expansion

Value expansion is a mechanism that replaces special constructions with values.

List of available constructions:

| Name         | Arguments                  | Scope            | Description                                                                                                                                                                                                                         |
| ------------ | -------------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$rN`        | `N` is integer             | Everywhere       | The `N`-st register number added to this function. For example, if function had 143 registers and `addRegisters` is 2, `$r0` will be replaced with `r143`, `$r1` with `r144` and so on                                              |
| `$kN`        | `N` is integer             | Everywhere       | The `N`-st constant number added to this function. For example, if function had 143 constants and `addConstants` is `["\"a\"", 7]`, `$k0` will be replaced with `k143` (which is `"a"`), `$k1` with `k144` (which is `7`) and so on |
| `${varName}` | `varName` is variable name | Everywhere       | The value of specified variable                                                                                                                                                                                                     |
| `$gN`        | `N` is integer             | `code` and `set` | The value of `N`-st group of the regular expression specified by `match` parameter                                                                                                                                                  |
