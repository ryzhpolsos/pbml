# OS creation guide

In this guide I'll teach you how to add a new OS to Progressbar95.

Required knowledge:
1. [Basics of Lua](https://learnxinyminutes.com/lua/)
2. [PBML mod creation](createMod)

## Step 1. Preparation

Create new mod, as described [here](createMod), and open `main.lua` file in the code editor.

## Step 2. Define \_OSTableEntry table

Create a table with [`_OSTableEntry`](../types/OSTableEntry) type and fill information about new OS. Here's an example:

```lua
local myOS = {
    AllowDownloadMusic = true,
    AllowInstallPinball = true,
    AllowInstallXL = true,
    BSOD = 1,
    Background = {
        Tiles = {},
        Wallpaper = { 0, 0, 0, 0, 1, 1, 1, 0, 1, 1 }
    },
    BackgroundColor = true,
    BackgroundColorTable = { { 1, 132, 133 }, { 255, 253, 0 }, { 0, 255, 63 }, { 0, 124, 255 }, { 255, 61, 0 }, { 255, 109, 61 }, { 0, 255, 255 }, { 129, 114, 193 }, { 130, 0, 0 }, { 0, 130, 0 }, { 129, 62, 0 }, { 228, 0, 255 }, { 250, 250, 250 }, { 186, 186, 186 }, { 51, 51, 51 }, { 21, 21, 21 } },
    Browser = true,
    BrowserAutostartBlocked = true,
    BrowserName = "Progressnet",
    Clock95 = true,
    DefragmentationIncluded = true,
    Diagram = {
        BlueDark = { 0, 0, 0.48235294117647 },
        BlueLight = { 0, 0, 1 },
        OrangeDark = { 0.8, 0.4, 0 },
        OrangeLight = { 0.96862745098039, 0.57647058823529, 0.11764705882353 }
    },
    Difficultylevel = 1,
    DitherAlpha = true,
    DownloadAppType = 1,
    DownloadMusicLevel = 1,
    FirewallIncluded = false,
    FontStyle = {},
    GameModes = { { "Normal" }, { "Relax", "pro" },
        [4] = { "minesweeper", "lvl", 15 },
        [5] = { "progresscommander", "lvl", 20 },
        [6] = { "progresstein", "lvl", 25 }
    },
    IconUniqueSet = true,
    MediaPlayer = "MIDI",
    Name = "Progressbar CUSTOM",
    PinballAssetIndex = 3,
    PointBonus = 0,
    Pro = " PRO",
    ProgressdosName = "Scary black window",
    Req = { 1, 1, 1 },
    ReqNames = { "486DK-20", "8 MB", "80 MB" },
    ScanProgressName = "ScanProgress",
    SetupDesign = 1,
    ShortName = "CUST",
    Skin = "95",
    SoundIntro = "intro_P95.mp3",
    SoundOutro = "outro_p95.mp3",
    StageLimit = 10,
    UpgradeStage = 0,
    Ver = "4.0",
    WHolidayWallp = 1,
    WallpaperPrizeStep = 1,
    Welcome = true,
    Y2KNotProtected = true,
    Year = 1995,
    YellowBackInHelp = true,
    achdesign = 1,
    bonusdesign = 1,
    gamequality3d = 4
}
```

## Step 3. Register new OS

Use `pbml.addOS` function to add your new OS to the list

```lua
pbml.addOS(myOS)
```
