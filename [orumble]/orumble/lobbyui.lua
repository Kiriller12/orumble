-- Статус отображения лобби
local isLobbyShown = false

-- Список игроков по командам
local teamsPlayers = {
    blue = {},
    red = {}
}

-- Команда локального игрока
local localPlayerTeam = nil

-- Текущее значение таймера до начала
local timerValue = nil

-- Экран лобби
local lobbyScreen = {
    width = 704,
    height = 448,
    color = tocolor(0, 0, 0, 100)
}

lobbyScreen.x = lobbyScreen.width/2
lobbyScreen.y = lobbyScreen.height/2

-- Разделитель
local splitLine = {
    width = 2,
    height = lobbyScreen.height - 88,
    color = tocolor(255, 255, 255, 125)
}

-- Панель имени команды
local teamNameBox = {
    top = 20,
    width = lobbyScreen.width/2 - 88,
    height = 48,
    color = tocolor(0, 0, 0, 100)
}

teamNameBox.x1 = lobbyScreen.width/4 + teamNameBox.width/2
teamNameBox.x2 = lobbyScreen.width/4 - teamNameBox.width/2
teamNameBox.y = lobbyScreen.y - teamNameBox.top

-- Текст имени команды
local teamText = {
    padding = 4,
    size = 1.5,
    font = "pricedown",
    align = "center",
    color = {
        tocolor(0, 0, 255, 225),
        tocolor(255, 0, 0, 225)
    }
}

teamText.width = teamNameBox.width - teamText.padding*2
teamText.height = teamNameBox.height - teamText.padding*2
teamText.x1 = teamNameBox.x1 - teamText.padding
teamText.x2 = teamNameBox.x2 + teamText.padding
teamText.y = teamNameBox.y - teamText.padding

-- Кнопка присоединения к команде
local joinButtonBox = {
    top = 16,
    width = 128,
    height = 48,
    color = tocolor(0, 0, 0, 150),
    hoverColor = {
        tocolor(0, 0, 175, 100),
        tocolor(175, 0, 0, 100)
    }
}

joinButtonBox.x1 = lobbyScreen.width/4 + joinButtonBox.width/2
joinButtonBox.x2 = lobbyScreen.width/4 - joinButtonBox.width/2
joinButtonBox.y = lobbyScreen.y + joinButtonBox.top

-- Кнопка присоединения к наблюдателям
local spectatorButtonBox = {
    top = 16,
    width = 128,
    height = 48,
    color = tocolor(0, 0, 0, 150),
    hoverColor = tocolor(100, 100, 100, 150),
}

spectatorButtonBox.x = spectatorButtonBox.width/2
spectatorButtonBox.y = lobbyScreen.y + spectatorButtonBox.top

-- Текст кнопки присоединения к команде
local buttonText = {
    padding = 4,
    size = 1.2,
    font = "pricedown",
    align = "center",
    color = tocolor(255, 255, 255, 225)
}

buttonText.width = joinButtonBox.width - buttonText.padding*2
buttonText.height = joinButtonBox.height - buttonText.padding*2
buttonText.x1 = joinButtonBox.x1 - buttonText.padding
buttonText.x2 = joinButtonBox.x2 + buttonText.padding
buttonText.x3 = spectatorButtonBox.x - buttonText.padding
buttonText.y = joinButtonBox.y + buttonText.padding

-- Панель игрока
local playerBox = {
    top = 20,
    margin = 8,
    width = lobbyScreen.width/2 - 88,
    height = 48,
    padding = 4,
    color = tocolor(255, 255, 255, 75),
    readyColor = tocolor(100, 255, 100, 75)
}

playerBox.x1 = lobbyScreen.width/4 + playerBox.width/2
playerBox.x2 = lobbyScreen.width/4 - playerBox.width/2
playerBox.y = teamNameBox.y - teamNameBox.height - playerBox.top

-- Текст ника
local nickText = {
    padding = 4,
    size = 1.5,
    font = "default-bold",
    alignH = "left",
    alignV = "center",
    color = tocolor(0, 0, 0, 225)
}

nickText.x = playerBox.height + nickText.padding
nickText.width = playerBox.width - playerBox.height - playerBox.padding - nickText.padding
nickText.height = playerBox.height - playerBox.padding*2

-- Текст таймера
local timerText = {
    size = 5.0,
    x = lobbyScreen.x,
    y = lobbyScreen.y,
    width = lobbyScreen.width,
    height = lobbyScreen.height,
    font = "pricedown",
    align = "center",
    color = tocolor(225, 225, 225, 225),
    shadowOffset = 6,
    shadowColor = tocolor(0, 0, 0, 225)
}

-- Отрисовка игрока
local function DrawPlayer(player, x, y)
    -- Получаем ник игрока
    local name = getPlayerName(player.element)

    -- Проверяем статус готовности игрока к игре и меняем фон
    local boxColor = playerBox.color
    if player.ready then
        boxColor = playerBox.readyColor
    end

    dxDrawRectangle(x, y, playerBox.width, playerBox.height, boxColor)
    dxDrawImage(x + playerBox.padding, y + playerBox.padding, playerBox.height - playerBox.padding*2, playerBox.height - playerBox.padding*2, "avatars/" .. player.avatar .. ".png")
    dxDrawText(name, x + nickText.x, y + playerBox.padding, x + nickText.x + nickText.width, y + playerBox.padding + nickText.height, nickText.color, nickText.size, nickText.font, nickText.alignH, nickText.alignV, true)
end

-- Обновление отрисовки лобби
local function OnLobbyRender()
	if not isLobbyShown then
        return
    end
    
    -- Получаем размер экрана
    local width, height = guiGetScreenSize()
    local w, h = width/2, height/2

    -- Отрисовываем окно и разделитель команд
    dxDrawRectangle(w - lobbyScreen.x, h - lobbyScreen.y, lobbyScreen.width, lobbyScreen.height, lobbyScreen.color)
    dxDrawLine(w, h - splitLine.height/2, w, h + splitLine.height/2, splitLine.color, splitLine.width)
    
    -- Отрисовываем окна названия команд
    dxDrawRectangle(w - teamNameBox.x1, h - teamNameBox.y, teamNameBox.width, teamNameBox.height, teamNameBox.color)
    dxDrawRectangle(w + teamNameBox.x2, h - teamNameBox.y, teamNameBox.width, teamNameBox.height, teamNameBox.color)

    -- Отрисовываем текст названия команд
    dxDrawText("BlUE", w - teamText.x1, h - teamText.y, w - teamText.x1 + teamText.width, h - teamText.y + teamText.height, teamText.color[1], teamText.size, teamText.font, teamText.align, teamText.align)
    dxDrawText("rED", w + teamText.x2, h - teamText.y, w + teamText.x2 + teamText.width, h - teamText.y + teamText.height, teamText.color[2], teamText.size, teamText.font, teamText.align, teamText.align)

    -- Отрисовываем кнопки присоединения команды команды 2
    local joinButtonBoxColor = joinButtonBox.color
    if IsMouseInPosition(w - joinButtonBox.x1, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height) then
        -- Если курсор над кнопкой, то изменяем ее цвет
        joinButtonBoxColor = joinButtonBox.hoverColor[1]
    end

    dxDrawRectangle(w - joinButtonBox.x1, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height, joinButtonBoxColor)
    
    -- Отрисовываем текст кнопки
    local joinButtonLabelText = "JOIn"
    if localPlayerTeam == "blue" then
        joinButtonLabelText = "rEADY"
    end

    dxDrawText(joinButtonLabelText, w - buttonText.x1, h + buttonText.y, w - buttonText.x1 + buttonText.width, h + buttonText.y + buttonText.height, buttonText.color, buttonText.size, buttonText.font, buttonText.align, buttonText.align)

    -- Отрисовываем кнопки присоединения команды команды 2
    joinButtonBoxColor = joinButtonBox.color
    if IsMouseInPosition(w + joinButtonBox.x2, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height) then
        -- Если курсор над кнопкой, то изменяем ее цвет
        joinButtonBoxColor = joinButtonBox.hoverColor[2]
    end
    
    dxDrawRectangle(w + joinButtonBox.x2, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height, joinButtonBoxColor)
    
    -- Отрисовываем текст кнопки
    joinButtonLabelText = "JOIn"
    if localPlayerTeam == "red" then
        joinButtonLabelText = "rEADY"
    end

    dxDrawText(joinButtonLabelText, w + buttonText.x2, h + buttonText.y, w + buttonText.x2 + buttonText.width, h + buttonText.y + buttonText.height, buttonText.color, buttonText.size, buttonText.font, buttonText.align, buttonText.align)

    ---
    -- Отрисовываем кнопки присоединения к наблюдателям
    local spectatorButtonBoxColor = spectatorButtonBox.color
    if IsMouseInPosition(w - spectatorButtonBox.x, h + spectatorButtonBox.y, spectatorButtonBox.width, spectatorButtonBox.height) then
        -- Если курсор над кнопкой, то изменяем ее цвет
        spectatorButtonBoxColor = spectatorButtonBox.hoverColor
    end

    dxDrawRectangle(w - spectatorButtonBox.x, h + spectatorButtonBox.y, spectatorButtonBox.width, spectatorButtonBox.height, spectatorButtonBoxColor)
    dxDrawText("SPECT", w - buttonText.x3, h + buttonText.y, w - buttonText.x3 + buttonText.width, h + buttonText.y + buttonText.height, buttonText.color, buttonText.size, buttonText.font, buttonText.align, buttonText.align)

    -- Отрисовываем список игроков команды команды 1
    local i = 0
    for _, player in pairs(teamsPlayers.blue) do
        if player.element and isElement(player.element) then
            DrawPlayer(player, w - playerBox.x1, h - playerBox.y + i * (playerBox.height + playerBox.margin))

            i = i + 1
        end
    end

    -- Отрисовываем список игроков команды команды 2
    i = 0
    for _, player in pairs(teamsPlayers.red) do
        if player.element and isElement(player.element) then
            DrawPlayer(player, w + playerBox.x2, h - playerBox.y + i * (playerBox.height + playerBox.margin))

            i = i + 1
        end
    end

    -- Отрисовываем таймер до начала игры
    if timerValue then
        dxDrawText(timerValue, w - timerText.x - timerText.shadowOffset, h - timerText.y - timerText.shadowOffset, w - timerText.x + timerText.width + timerText.shadowOffset*2, h - timerText.y + timerText.height + timerText.shadowOffset*2, timerText.shadowColor, timerText.size, timerText.font, timerText.align, timerText.align)
        dxDrawText(timerValue, w - timerText.x, h - timerText.y, w - timerText.x + timerText.width, h - timerText.y + timerText.height, timerText.color, timerText.size, timerText.font, timerText.align, timerText.align)
    end
end

-- Обработка клика мышью
local function OnClick(button, state)
    if button ~= "left" or state ~= "up" then
        return
    end

    -- Получаем размер экрана
    local width, height = guiGetScreenSize()
    local w, h = width/2, height/2
    
    -- Если курсор над кнопкой команды 1
    if IsMouseInPosition(w - joinButtonBox.x1, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height) then
        -- Проверяем нужно ли менять статус готовности или изменить команду игрока
        if localPlayerTeam == "blue" then
            triggerServerEvent("onPlayerSetReady", resourceRoot)
        else
            triggerServerEvent("onPlayerJoinTeam", resourceRoot, "blue")
        end
    -- Если курсор над кнопкой команды 2
    elseif IsMouseInPosition(w + joinButtonBox.x2, h + joinButtonBox.y, joinButtonBox.width, joinButtonBox.height) then
        -- Проверяем нужно ли менять статус готовности или изменить команду игрока
        if localPlayerTeam == "red" then
            triggerServerEvent("onPlayerSetReady", resourceRoot)
        else
            triggerServerEvent("onPlayerJoinTeam", resourceRoot, "red")
        end
    -- Если курсор над кнопкой наблюдателя
    elseif IsMouseInPosition(w - spectatorButtonBox.x, h + spectatorButtonBox.y, spectatorButtonBox.width, spectatorButtonBox.height) then
        triggerServerEvent("onPlayerJoinSpectator", resourceRoot)
    end
end

-- Переключение режима отображения лобби
local function OnToggleLobby(state)
    isLobbyShown = state
    timerValue = nil
    localPlayerTeam = nil
    teamsPlayers = {
        blue = {},
        red = {}
    }

    showCursor(state)
end

-- Изменение команды игроком
local function OnPlayerChangeTeam(player, avatar, team)
    -- Сбрасываем прошлые данные о команде игрока
    teamsPlayers.blue[player] = nil
    teamsPlayers.red[player] = nil

    -- Записываем новые данные
    if avatar and team then
        teamsPlayers[team][player] = {
            element = player,
            avatar = avatar,
            ready = false
        }
    end

    -- Сохраняем команду для локального игрока
    if player == localPlayer then
        localPlayerTeam = team
    end
end

-- Изменение статуса готовности игроком
local function OnPlayerChangeReady(player, ready)
    if teamsPlayers.blue[player] then
        teamsPlayers.blue[player].ready = ready
    elseif teamsPlayers.red[player] then
        teamsPlayers.red[player].ready = ready
    end
end

-- Обновление значения таймера
local function OnUpdateTimerValue(value)
    timerValue = value
end

-- Регистрируем новые события
addEvent("onToggleLobby", true)
addEvent("onPlayerChangeTeam", true)
addEvent("onPlayerChangeReady", true)
addEvent("onUpdateTimerValue", true)

-- Подписка на события
addEventHandler("onClientRender", root, OnLobbyRender)
addEventHandler("onClientClick", root, OnClick)
addEventHandler("onToggleLobby", root, OnToggleLobby)
addEventHandler("onPlayerChangeTeam", root, OnPlayerChangeTeam)
addEventHandler("onPlayerChangeReady", root, OnPlayerChangeReady)
addEventHandler("onUpdateTimerValue", root, OnUpdateTimerValue)