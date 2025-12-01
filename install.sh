#!/usr/bin/env bash

dependencies=(curl python3 java)

for i in ${dependencies[*]}; do
    if command -v $i > /dev/null; then
        no_deps=0
    else
        echo "Fatal error: $i not found"
        no_deps=1
    fi
done

if [ $no_deps -eq 1 ]; then
    exit 1
fi

curl -sLo unluac.jar "https://deac-fra.dl.sourceforge.net/project/unluac/Unstable/unluac_2025_10_19.jar"
curl -sLo corona-archiver.py "https://raw.githubusercontent.com/0BuRner/corona-archiver/refs/heads/master/corona-archiver.py"

if [ ! -f unluac.jar ]; then
    echo "Failed to download unluac"
    exit 1
fi

if [ ! -f corona-archiver.py ]; then
    echo "Failed to download corona-archiver.py"
    exit 1
fi

if [ -z "$1" ]; then
    read -p "Path to game directory: " gameDir
else
    gameDir="$1"
fi

if [ ! -f "$gameDir/Resources/resource.car" ]; then
    echo "Failed to find game files"
    exit 1
fi

echo "Extracting game files..."
mkdir -p res
python3 corona-archiver.py -u "$gameDir/Resources/resource.car" res
echo "Extraction done"

echo "Disassembling main.lu..."
java -jar unluac.jar --disassemble 'res/main.lu' --output 'main_src.txt'
echo "Disassembly done"

echo "Patching main.lu..."
python3 patch.py
echo "Patching done"

echo "Assembling main.lu..."
java -jar unluac.jar --assemble 'main_dst.txt' --output 'res/main.lu'
echo "Assembly done"

echo "Packing game files..."
mv "$gameDir/Resources/resource.car" "$gameDir/Resources/resource.car.bak"
python3 corona-archiver.py -p res "$gameDir/Resources/resource.car"
echo "Packing done"

echo "Creating modloader files..."

mkdir -p "$gameDir/Resources/pbml"
mkdir -p "$gameDir/Resources/mods"

cat << EOF > "$gameDir/Resources/pbml/pbml.lua"
local lfs = require('lfs')

local logFile = io.open('Resources/pbml/log.txt', 'a')
if(logFile == nil) then return end

logFile:write('Modloader started\n')

for modFolder in lfs.dir('Resources/mods') do
    if(modFolder == '.' or modFolder == '..') then
    else
        logFile:write('Loading mod: ' .. modFolder .. '\n')
        dofile('Resources/mods/' .. modFolder .. '/main.lua')
        logFile:write('Loaded mod: ' ..modFolder .. '\n')
    end
end

logFile:close()
EOF

echo "Creating done"

echo "Cleaning up..."
rm -f main_src.txt
rm -f main_dst.txt
rm -rf res
echo "Cleanup completed"

echo "Modloader installed"