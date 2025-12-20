local lfs = require('lfs')

local function showModManager()
    local html = [[
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8">
                <style>
                    body {
                        margin: 0;
                        padding: 0.5em;
                        padding-top: calc(10vh + 0.25em);
                        user-select: none;
                        -ms-user-select: none;
                        cursor: default;
                        background-color: #222222;
                    }
                    * {
                        font-family: 'Segoe UI', Arial, sans-serif;
                    }
                    .hidden-link {
                        color: inherit;
                        text-decoration: none;
                    }
                    .window-title {
                        position: absolute;
                        left: 0;
                        top: 0;
                        width: 100vw;
                        height: 10vh;
                        background-color: #410bb5;
                        color: white;
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        gap: 0.5em;
                    }
                    .window-title > div {
                        padding: 0 0.5em;
                    }
                    .close-button {
                        cursor: pointer;
                    }
                    .mod-list {
                        height: 70vh;
                        max-height: 70vh;
                        overflow: auto;
                    }
                    .mod {
                        display: flex;
                        justify-content: space-between;
                        margin: 0.5em 0;
                        padding: 0.5em;
                        background-color: #6126de;
                        border-radius: 5px;
                        color: white;
                    }
                    .disabled-mod {
                        background-color: #8f8f8f;
                    }
                    .mod .action-button {
                        display: none;
                        margin-left: 0.25em;
                    }
                    .mod:hover .action-button {
                        display: inline;
                        cursor: pointer;
                    }
                    .action-button:hover {
                        font-weight: bold;
                    }
                    .button-list {
                        position: fixed;
                        bottom: 0;
                    }
                    .button-list button {
                        width: 15em;
                        margin-right: 0.5em;
                        margin-bottom: 0.5em;
                        padding: 0.5em;
                        background-color: #410bb5;
                        border: 0;
                        border-radius: 5px;
                        color: white;
                        cursor: pointer;
                    }
                </style>
            </head>
            <body>
                <div class="window-title">
                    <div class="caption">PBML Mod Manager</div>
                    <div class="close-button"><a href="pbml:close" class="hidden-link">&#9587;</a></div>
                </div>
                <div class="mod-list">
    ]]

    for _, mod in ipairs(pbml.modList) do
        if mod.enabled then
            html = html .. '<div class="mod">' .. mod.name .. '<div><a class="action-button hidden-link" href="pbml:disable/' .. mod.folderName .. '">Disable</a> <a class="action-button hidden-link" href="pbml:remove/' .. mod.folderName .. '">Remove</a></div></div>'
        else
            html = html .. '<div class="mod disabled-mod">' .. mod.name .. '<div><a class="action-button hidden-link" href="pbml:enable/' .. mod.folderName .. '">Enable</a><a class="action-button hidden-link" href="pbml:remove/' .. mod.folderName .. '">Remove</a></div></div>'
        end
    end

    html = html .. [[
                </div>
                <div class="button-list">
                    <button id="button-install">Install mod</button><a class="hidden-link" href="pbml:restart"><button id="button-restart">Restart game</button></a><a class="hidden-link" href="pbml:quit"><button id="button-quit">Quit game</button></a>
                </div>
                <script>
                    document.getElementById('button-install').onclick = function(){
                        var file = document.createElement('input');
                        file.type = 'file';
                        file.oninput = function(){
                            location.assign('pbml:install/' + file.value);
                        };

                        file.click();
                    };
                </script>
            </body>
        </html>
    ]]

    local mmFile, err = io.open(pbml.dataDirectory .. '/pbml/modmananger.html', 'w')
    if mmFile == nil then
        native.showAlert('PBML', err)
        return
    end
    mmFile:write(html)
    mmFile:close()

    local webView = native.newWebView(display.contentCenterX, display.contentCenterY, display.actualContentWidth / 2, display.actualContentHeight / 2)

    webView:addEventListener('urlRequest', function(event)
        if not event.type then return end

        local act, arg1 = string.match(event.url, 'pbml:(%w+)/?(.*)')

        if act == 'close' then
            webView:removeSelf()
            os.remove(pbml.dataDirectory .. '/pbml/modmananger.html')
        elseif act == 'disable' then
            native.showAlert('PBML', 'Are you sure you want to disable "' .. arg1 .. '" mod?', { 'Yes', 'No' }, function(event)
                if event.action == 'clicked' and event.index == 1 then
                    local file = io.open(pbml.dataDirectory .. '/mods/' .. arg1 .. '/.disabled', 'w')
                    if file == nil then return end
                    file:write('')
                    file:close()

                    os.execute('cmd.exe /q /c start "" "' .. pbml.gameDirectory .. '/Progressbar95.exe' .. '"')
                    os.exit()
                end
            end)
        elseif act == 'enable' then
            native.showAlert('PBML', 'Are you sure you want to enable "' .. arg1 .. '" mod?', { 'Yes', 'No' }, function(event)
                if event.action == 'clicked' and event.index == 1 then
                    os.remove(pbml.dataDirectory .. '/mods/' .. arg1 .. '/.disabled')
                    os.execute('cmd.exe /q /c start "" "' .. pbml.gameDirectory .. '/Progressbar95.exe' .. '"')
                    os.exit()
                end
            end)
        elseif act == 'restart' then
            os.execute('cmd.exe /q /c start "" "' .. pbml.gameDirectory .. '/Progressbar95.exe' .. '"')
            os.exit()
        elseif act == 'quit' then
            os.exit()
        elseif act == 'install' then
            if not string.match(arg1, '%.zip$') then
                native.showAlert('PBML', 'Error: ZIP archive required')
                return
            end

            local modName = string.match(arg1, '.*[\\/](.*)%.zip$')

            os.execute('powershell.exe -exec bypass -c "Expand-Archive \'' .. arg1 .. '\' \'' .. pbml.dataDirectory .. '/mods/' .. modName .. '\' -Force ; Start-Process \'' .. pbml.gameDirectory .. '/Progressbar95.exe' .. '\'"')
            os.exit()
        elseif act == 'remove' then
            native.showAlert('PBML', 'Are you sure you want to remove "' .. arg1 .. '" mod?', { 'Yes', 'No' }, function(event)
                if event.action == 'clicked' and event.index == 1 then
                    os.execute('cmd.exe /q /c rmdir /s /q "' .. pbml.dataDirectory .. '/mods/' .. arg1 .. '" & start "" "' .. pbml.gameDirectory .. '/Progressbar95.exe' .. '"')
                    os.exit()
                end
            end)
        end

        native.setKeyboardFocus(nil)
    end)

    webView:request(pbml.dataDirectory .. '/pbml/' .. 'modmananger.html')
end

return showModManager