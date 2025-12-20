# PBML Patcher Command-line Syntax

> [!NOTE]
> In this article, `python` is used as Python executable name. It can be different (for example, `py` on Windows or `python3` on Linux)


## Usage

If PBML is launched without any arguments, interactive mode is enabled.

```
python pbml.py [--help|-h|-?|/?]
               [--no-logo|-N]
               [--silent|-s]
               [--debug|-D]
               [--android|-A]
               [--patch|-p <patches>]
               [--game-dir|-d <path to game directory>]
               [--resources-dir|-R <path to resources directory>]
```

### `--help | -h | -? | /?`
Display short help about command-line syntax and exit.

### `--no-logo | -N.`
Don't print "PBML *version*" string to console.

### `--silent | -s`
Don't print anything to console.

### `--debug | -D`
Enable debug mode. In this mode, some temporary files don't get deleted.

### `--android | -a`
Changes resources directory to `assets`.

### `--patch | -p`
Applies all patches from comma-separated list of patch file paths instead of injecting PBML.

Example: `--patch D:\patches\1.json,D:\patches\2.json,C:\Users\user\myPatch.json`

### `--game-dir | -d`
Specifies path to the game root directory. The game root directory is the directory where `Progressbar95.exe` is located.

### `--resources-dir | -r`
Specifies path to the resources directory. This path is relative to the game root directory. Default value is `Resources`.
