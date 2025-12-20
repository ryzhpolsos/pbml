# Mod creation guide

In this guide I'll teach you how to create mods for PBML. Note: basic knowledge of Lua is required. If you don't have it, you can visit [this page](https://learnxinyminutes.com/lua/) for a quick overview of Lua basics.
You'll also need a code editor for comfortable work, I prefer [VS Code](https://code.visualstudio.com/).

## Step 1. Preparation

Mods in PBML are just folders with special structure. They are located inside `[game folder]/Resources/mods` folder, so navigate to it and create a new folder. Give it any name you want, this will be your mod ID.

Then, open your newly created folder in code editor (I'll use VS Code).

## Step 2. Config

The first required file for every PBML mod is `mod.json`. It stores important metadata about the mod. The format of this file is pretty simple:
```json
{
	"name": "Full name of your mod. Fell free to use any characters!",
	"version": "Version string",
	"author": "Name of author of the mod",
	"description": "Long description of your mod. <b>HTML</b> is supported"
}
```

So, for your first mod, create a `mod.json` file with following content:
```json
{
	"name": "My First Mod",
	"version": "1.0",
	"author": "You",
	"description": "My first PBML mod!"
}
```

## Step 3. Code

Configuration is good, but main part of every mod is its code. PBML mods are written in Lua, so make sure you know it. Entry point of each mod is `main.lua` file, so create one inside your mod folder.

Put the following code inside:
```lua
native.showAlert("Message from PBML", "Hello World!")
```

When you've finished, start the game. You should see a popup with "Hello World!" text inside when game loading process begins.

Congratulations, you've just created your first PBML mod!

## Step 4. What's next?

When you've learned basics of PBML mod creation, refer to [PBML documentation](..) and [Solar2D API Reference](https://docs.coronalabs.com/api/index.html).

And the most important thing: have fun modding the game! :)