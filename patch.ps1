param(
    [string] $gameDir
)

$ErrorActionPreference = 'Stop'

$webClient = [System.Net.WebClient]::new()

if($null -eq (Get-Command java -ErrorAction SilentlyContinue)){
    Write-Host 'Fatal error: Java executable not found. Install Java and re-run the script' -ForegroundColor Red
    exit
}

if(-not (Test-Path 'corona-archiver.exe')){
    try {
        Write-Host 'Downloading requirements: corona-archiver'
        $webClient.DownloadFile('https://github.com/0BuRner/corona-archiver/releases/download/1.1/corona-archiver.exe', 'corona-archiver.exe')
        Write-Host 'Downloaded: corona-archiver'
    }
    catch {
        Write-Host 'Fatal error: failed to download corona-archiver' -ForegroundColor Red
        exit
    }
}

if(-not (Test-Path 'unluac.jar')){
    try {
        Write-Host 'Downloading requirements: unluac'
        $webClient.DownloadFile('https://deac-fra.dl.sourceforge.net/project/unluac/Unstable/unluac_2025_10_19.jar', 'unluac.jar')
        Write-Host 'Downloaded: unluac'
    }
    catch {
        Write-Host 'Fatal error: failed to download unluac' -ForegroundColor Red
        exit
    }
}

$needPause = $false

if($gameDir.Trim().Length -eq 0){
    $gameDir = Read-Host 'Path to game directory'
    $needPause = $true
}

if(-not (Test-Path 'res' -PathType Container)){
    New-Item 'res' -ItemType Directory | Out-Null
}

Write-Host 'Extracting game data...'
.\corona-archiver.exe -u "$gameDir\Resources\resource.car" 'res'
Write-Host 'Extraction done'

Write-Host 'Disassembling main.lu...'
java -jar unluac.jar --disassemble 'res\main.lu' --output 'main_src.txt'
Write-Host 'Disassembly done'

Write-Host 'Patching main.lu...'

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

$reader = [System.IO.StreamReader]::new('main_src.txt', [System.Text.Encoding]::UTF8)
$writer = [System.IO.StreamWriter]::new('main_dst.txt', [System.Text.Encoding]::UTF8)

$state = 0
$prevLine = ''
$stackSize = 0
$lastConst = 0
$beginMenuConst = 0

while($null -ne ($line = $reader.ReadLine())){
    $addLine = $true

    if($state -eq 0 -and $line -match '^\.function\s+main/f0$'){
        $state = 1
    }
    elseif($state -eq 1 -and $line -match '^\.maxstacksize\s+(\d+)$'){
        $state = 2
        $stackSize = [int]::Parse($Matches[1])
        $line = '.maxstacksize ' + ($stackSize + 2)
    }
    elseif($state -eq 2 -and $line -match '^\.constant\s+k(\d+)\s+"BeginMenu"$'){
        $state = 3
        $beginMenuConst = $Matches[1]
    }
    elseif($state -eq 3 -and $line.Trim().Length -eq 0 -and $prevLine -match '^\.constant\s+k(\d+)\s+.*$'){
        $state = 4
        $lastConst = [int]::Parse($Matches[1])

        $addLine = $false
        $writer.WriteLine(".constant k$($lastConst+1) `"dofile`"")
        $writer.WriteLine(".constant k$($lastConst+2) `"Resources/pbml/pbml.lua`"")
        $writer.WriteLine(".constant k$($lastConst+3) `"Game`"")
        $writer.WriteLine('')
    }
    elseif($state -eq 4 -and $line -match "^loadk\s+r\d+\s+k$beginMenuConst"){
        $addLine = $false
        $writer.WriteLine($line)
        $writer.WriteLine("setglobal r1 k$($lastConst+3)")
        $writer.WriteLine("getglobal r$stackSize k$($lastConst+1)")
        $writer.WriteLine("loadk r$($stackSize+1) k$($lastConst+2)")
        $writer.WriteLine("call r$stackSize 2 1")
        $state = 5
    }

    $prevLine = $line
    if($addLine){ $writer.WriteLine($line) }
}

$reader.Close()
$writer.Flush()
$writer.Close()

Write-Host 'Patching done'

Write-Host 'Assembling main.lu...'
java -jar unluac.jar --assemble 'main_dst.txt' --output 'res\main.lu'
Write-Host 'Assembly done'

Write-Host 'Packing game data...'
Move-Item "$gameDir\Resources\resource.car" "$gameDir\Resources\resource.car.bak" | Out-Null
.\corona-archiver.exe -p 'res' "$gameDir\Resources\resource.car"
Write-Host 'Packing done'

Write-Host 'Creating modloader files...'

$pbmlLua = @'
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
'@

New-Item "$gameDir\Resources\mods" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item "$gameDir\Resources\pbml" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
[System.IO.File]::WriteAllText("$gameDir\Resources\pbml\pbml.lua", $pbmlLua, $Utf8NoBomEncoding)

Write-Host 'Creating done'

Write-Host 'Cleaning up...'
Remove-Item -Force -Recurse 'res' | Out-Null
Remove-Item 'main_src.txt' | Out-Null
Remove-Item 'main_dst.txt' | Out-Null
Write-Host 'Cleanup done'

Write-Host 'Modloader installed' -ForegroundColor Green

if($needPause){ Read-Host }