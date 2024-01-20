-- Баллы команд
local teamScores = nil
local lastRound = false

-- Текст баллов команд
local scoresText = {
    size = 2.0,
    font = "pricedown",
    align = "center",
    color = tocolor(255, 255, 255, 255),
    colorCoded = true
}

-- Обновление отрисовки лобби
local function OnScoresUiRender()
	if not teamScores then
        return
    end
    
    -- Получаем размер экрана
    local w, h = guiGetScreenSize()

    -- Если раунд последний, то отрисовываем экран победы
    if lastRound then
        local winText = "no one can beat the life..."
        if teamScores.blue > teamScores.red then
            winText = "#0000FFBlUE #FFFFFFteam wins with " .. tostring(teamScores.blue - teamScores.red) .. " points ahead"
        elseif teamScores.red > teamScores.blue then
            winText = "#FF0000rED #FFFFFFteam wins with " .. tostring(teamScores.red - teamScores.blue) .. " points ahead"
        end

        -- Отрисовываем сообщение победы
        dxDrawText("Winner\n\n " .. winText, w/2, h/2, w/2, h/2, scoresText.color, scoresText.size, scoresText.font, scoresText.align, scoresText.align, _, _, _, scoresText.colorCoded)
    
        return
    end

    -- Отрисовываем сообщение о том, какая команда на сколько очков лидирует
    local leadingText = ""
    if teamScores.blue > teamScores.red then
        leadingText = "\n\n#0000FFBlUE #FFFFFFteam is " .. tostring(teamScores.blue - teamScores.red) .. " points ahead"
    elseif teamScores.red > teamScores.blue then
        leadingText = "\n\n#FF0000rED #FFFFFFteam is " .. tostring(teamScores.red - teamScores.blue) .. " points ahead"
    end

    -- Отрисовываем очки
    dxDrawText("round scores\n\n#0000FFBlUE #FFFFFFteam: " .. tostring(teamScores.blue) .. "\n#FF0000rED #FFFFFFteam: " .. tostring(teamScores.red) .. leadingText, w/2, h/2, w/2, h/2, scoresText.color, scoresText.size, scoresText.font, scoresText.align, scoresText.align, _, _, _, scoresText.colorCoded)
end

-- Переключение режима отображения интерфейса результатов раунда
local function OnToggleScoresUi(scores, isLastRound)
    teamScores = scores
    lastRound = isLastRound
end

-- Регистрируем новые события
addEvent("onToggleScoresUi", true)

-- Подписка на события
addEventHandler("onClientRender", root, OnScoresUiRender)
addEventHandler("onToggleScoresUi", root, OnToggleScoresUi)