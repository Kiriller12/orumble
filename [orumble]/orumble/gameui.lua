-- Статус отображения лобби
local isGameUiShown = false

-- Количество столбцов игроков
local maxPlayersRows = 0

-- Список команд и игроков
local teamScores = {
    blue = {
        total = {
            scores = 0
        }
    },
    red = {
        total = {
            scores = 0
        }
    }
}

-- Текст с номером текущего раунда
local roundText = nil

-- Текущее значение таймера до конца раунда
local timerValue = nil

-- Активная всплывающая подсказка
local playerTooltip = nil

-- Экран очков
local scoreScreen = {
    right = 16,
    bottom = 16,
    width = 64,
    height = 152,
    color = tocolor(0, 0, 0, 100)
}

scoreScreen.x = scoreScreen.width + scoreScreen.right
scoreScreen.y = scoreScreen.height + scoreScreen.bottom

-- Текст раунда
local roundTextBox = {
    x = scoreScreen.x,
    y = scoreScreen.y,
    height = 40,
    color = tocolor(255, 255, 255, 255),
    size = 1.2,
    font = "pricedown",
    align = "center"
}

-- Панель очков
local scoresBox = {
    width = 48,
    height = 48,
    margin = 8,
    color = tocolor(255, 255, 255, 75),
    textSize = 1.5,
    textFont = "pricedown",
    textAlign = "center",
    textColor = {
        tocolor(0, 0, 150, 225),
        tocolor(150, 0, 0, 225)
    },
    imagePadding = 4,
    borderSize = 3
}

scoresBox.x = scoresBox.width + scoreScreen.right + scoresBox.margin
scoresBox.y2 = scoresBox.height + scoreScreen.bottom + scoresBox.margin
scoresBox.y1 = scoresBox.y2 + scoresBox.height + scoresBox.margin

-- Контекстная подсказка
local contextTip = {
    height = 48,
    padding = 8,
    margin = 8,
    color = tocolor(255, 255, 255, 125),
    borderColor = tocolor(0, 0, 0, 225),
    borderSize = 2,
    textSize = 1.5,
    textFont = "default-bold",
    textAlign = "center",
    textColor = tocolor(0, 0, 0, 225)
}

-- Текст таймера
local timerText = {
    size = 5.0,
    width = 0,
    height = 128,
    font = "pricedown",
    align = "center",
    color = tocolor(225, 225, 225, 225),
    shadowOffset = 6,
    shadowColor = tocolor(0, 0, 0, 225)
}

-- Отрисовка игрока
local function DrawPlayer(player, x, y, teamColor)
    -- Отрисовываем фон с рамкой, если это текущий игрок, чтобы выделить его
    if player.element == localPlayer then
        DxDrawBorderedRectangle(x, y, scoresBox.width, scoresBox.height, scoresBox.color, teamColor, scoresBox.borderSize)
    else
        dxDrawRectangle(x, y, scoresBox.width, scoresBox.height, scoresBox.color)
    end
    
    -- Отрисовываем аватар игрока
    dxDrawImage(x + scoresBox.imagePadding, y + scoresBox.imagePadding, scoresBox.height - scoresBox.imagePadding*2, scoresBox.height - scoresBox.imagePadding*2, "avatars/" .. player.avatar .. ".png")

    -- Если игрок мертв, то рисуем поверх крест
    if not isElement(player.element) or isPedDead(player.element) then
        dxDrawText("❌", x, y, x + scoresBox.width, y + scoresBox.height, teamColor, scoresBox.textSize, scoresBox.textFont, scoresBox.textAlign, scoresBox.textAlign)
    -- Если есть очки, то отображаем их
    elseif player.scores and player.scores > 0 then
        dxDrawText(tostring(player.scores), x, y, x + scoresBox.width, y + scoresBox.height, teamColor, scoresBox.textSize, scoresBox.textFont, scoresBox.textAlign, scoresBox.textAlign)
    end

    -- Если курсор над иконкой игрока, отрисовываем его имя в подсказке
    if IsMouseInPosition(x, y, scoresBox.width, scoresBox.height) then
        playerTooltip = {player, x, y}
    end
end

-- Отрисовка всплывающей подсказки
local function DrawTooltip(player, x, y)
    -- Получаем ник игрока
    local name = getPlayerName(player.element)
    if not name then
        name = "WASTED!"
    end
    
    -- Вычисляем длину ника
    local width = dxGetTextWidth(name, contextTip.textSize, contextTip.textFont) + contextTip.padding*2

    -- Отрисовываем прямоугольник с рамкой и текст ника
    DxDrawBorderedRectangle(x - width - contextTip.margin, y, width, contextTip.height, contextTip.color, contextTip.borderColor, contextTip.borderSize)
    dxDrawText(name, x - width - contextTip.margin, y, x - contextTip.margin, y + contextTip.height, contextTip.textColor, contextTip.textSize, contextTip.textFont, contextTip.textAlign, contextTip.textAlign)
end

-- Обновление отрисовки лобби
local function OnGameUiRender()
	if not isGameUiShown then
        return
    end
    
    -- Получаем размер экрана
    local w, h = guiGetScreenSize()
    
    -- Отрисовываем окно очков
    local scoreScreenWidth = scoreScreen.width + (scoresBox.width + scoresBox.margin) * maxPlayersRows
    dxDrawRectangle(w - scoreScreen.x - (scoresBox.width + scoresBox.margin) * maxPlayersRows, h - scoreScreen.y, scoreScreenWidth, scoreScreen.height, scoreScreen.color)

    -- Отрисовываем текст раунда
    local roundTextBoxX = w - roundTextBox.x - (scoresBox.width + scoresBox.margin) * maxPlayersRows
    dxDrawText(roundText, roundTextBoxX, h - roundTextBox.y, roundTextBoxX + scoreScreenWidth, h - roundTextBox.y + roundTextBox.height, roundTextBox.color, roundTextBox.size, roundTextBox.font, roundTextBox.align, roundTextBox.align)

    -- Сбрасываем всплывающую подсказку
    playerTooltip = nil

    -- Отрисовываем очки игроков команды 1
    local teamBlueScores = 0
    local i = 1
    for _, player in pairs(teamScores.blue) do
        -- Суммируем очки
        teamBlueScores = teamBlueScores + player.scores

        -- Если действительный игрок, то отрисовываем его
        if player.element then
            DrawPlayer(player, w - scoresBox.x - i * (scoresBox.width + scoresBox.margin), h - scoresBox.y1, scoresBox.textColor[1])

            i = i + 1
        end
    end

    -- Отрисовываем очки игроков команды 2
    local teamRedScores = 0
    i = 1
    for _, player in pairs(teamScores.red) do
        -- Суммируем очки
        teamRedScores = teamRedScores + player.scores

        -- Если действительный игрок, то отрисовываем его
        if player.element then
            DrawPlayer(player, w - scoresBox.x - i * (scoresBox.height + scoresBox.margin), h - scoresBox.y2, scoresBox.textColor[2])

            i = i + 1
        end
    end

    -- Отрисовка всплывающей подсказки
    if playerTooltip then
        DrawTooltip(unpack(playerTooltip))
    end

    -- Суммарные очки команды 1
    dxDrawRectangle(w - scoresBox.x, h - scoresBox.y1, scoresBox.width, scoresBox.height, scoresBox.color)
    dxDrawText(tostring(teamBlueScores), w - scoresBox.x, h - scoresBox.y1, w - scoresBox.x + scoresBox.width, h - scoresBox.y1 + scoresBox.height, scoresBox.textColor[1], scoresBox.textSize, scoresBox.textFont, scoresBox.textAlign, scoresBox.textAlign)

    -- Суммарные очки команды 2
    dxDrawRectangle(w - scoresBox.x, h - scoresBox.y2, scoresBox.width, scoresBox.height, scoresBox.color)
    dxDrawText(tostring(teamRedScores), w - scoresBox.x, h - scoresBox.y2, w - scoresBox.x + scoresBox.width, h - scoresBox.y2 + scoresBox.height, scoresBox.textColor[2], scoresBox.textSize, scoresBox.textFont, scoresBox.textAlign, scoresBox.textAlign)

    -- Отрисовываем таймер до конца раунда
    if timerValue then
        dxDrawText(timerValue, w/2 - timerText.shadowOffset, 0 - timerText.shadowOffset, w/2 + timerText.width + timerText.shadowOffset*2, 0 + timerText.height + timerText.shadowOffset*2, timerText.shadowColor, timerText.size, timerText.font, timerText.align, timerText.align)
        dxDrawText(timerValue, w/2, 0, w/2 + timerText.width, 0 + timerText.height, timerText.color, timerText.size, timerText.font, timerText.align, timerText.align)
    end
end

-- Переключение режима отображения игрового интерфейса
local function OnToggleGameUi(state, teamsPlayers, maxPlayersInTeam, round)
    isGameUiShown = state
    
    timerValue = nil
    roundText = nil
    maxPlayersRows = 0

    teamScores = {
        blue = {
            total = {
                scores = 0
            }
        },
        red = {
            total = {
                scores = 0
            }
        }
    }

    -- Если интерфейс активирован и передан список игроков, то обновляем список
    if state and teamsPlayers and maxPlayersInTeam and round then
        teamScores = teamsPlayers
        maxPlayersRows = maxPlayersInTeam
        roundText = round
    end
end

-- Обновление очков игрока
local function OnPlayerUpdatePoints(player, avatar, team, scores)
    -- Записываем новые данные
    teamScores[team][player] = {
        element = player,
        avatar = avatar,
        scores = scores
    }
end

-- Обновление значения таймера
local function OnUpdateRoundTimerValue(value)
    timerValue = value
end

-- Регистрируем новые события
addEvent("onToggleGameUi", true)
addEvent("onPlayerUpdatePoints", true)
addEvent("onUpdateRoundTimerValue", true)

-- Подписка на события
addEventHandler("onClientRender", root, OnGameUiRender)
addEventHandler("onToggleGameUi", root, OnToggleGameUi)
addEventHandler("onPlayerUpdatePoints", root, OnPlayerUpdatePoints)
addEventHandler("onUpdateRoundTimerValue", root, OnUpdateRoundTimerValue)