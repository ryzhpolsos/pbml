# Progressbar95 ModLoader project
A tiny, modular modloader for Progressbar95 intended to easily create mods without messing up with game files

## Installation
0. Download the archive from [releases page](https://github.com/ryzhpolsos/pbml/releases)

### Windows
1. Make sure you have Java installed
2. If you use steam version, maybe you should delete `steam_api.dll` from the game directory
3. Extract the archive
4. Launch `install.bat` as administrator
5. When loader asks for game directory path, enter it
6. Wait for patch process to complete
7. Launch game and enjoy

### Linux
1. Make sure you have Java, Python3 and curl installed
2. If you use steam version, maybe you should delete `steam_api.dll` from the game directory
3. Extract the archive
4. Navigate to the extracted files location in terminal and type `bash install.sh`
5. When loader asks for game directory path, enter it
6. Wait for patch process to complete
7. Launch game and enjoy

## Mod installation
1. Download mod
2. Extract it to `[game dir]/Resources/mods` directory

## Mod creation
1. Create a subdirectory inside of `[game dir]/Resources/mods`
2. Put a file called `main.lua` inside of it
3. Refer to [engine api](https://docs.coronalabs.com/api/index.html) and [pb95 game object documentation](https://ryzhpolsos.github.io/pbml/docs)

## License
[The MIT License](https://github.com/ryzhpolsos/pbml/blob/main/LICENSE)
