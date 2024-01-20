local freeAvatars = {"cat01", "cat02", "cat03", "cat04", "cat05", "cat06", "cat07", "cat08", "cat09", "cat10", "cat11", "cat12"}

local mapRoot = nil
local maxTeamPlayers = 0
local maxRounds = 0
local maxRoundTime = 0
local time = {hours = 12, minutes = 0}

local round = 0
local gameStartTimer = nil
local gameStartTimerValue = 0
local roundTimer = nil
local roundTimerValue = 0
local maxPlayersInTeam = 0

local endRoundTimer = nil
local nextRoundTimer = nil

-- Список игроков в текущем раунде
local teamsPlayers = {
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

-- Устанавливает для игрока случайную камеру из доступных пресетов карты
function SetRandomCamera(player)
    local cameras = getElementsByType("camera", mapRoot)
    local randomCamera = cameras[math.random(1, #cameras)]

    local x, y, z, tx, ty, tz = GetCameraValues(randomCamera)
    setCameraMatrix(player, x, y, z, tx, ty, tz)
end

-- Возвращает случайный свободный аватар для игрока
function GetNewAvatar()
    -- Если аватары кончились, возвращаем аватар по умолчанию
    if #freeAvatars == 0 then
        return "cat01"
    end

    -- Получаем аватар
    local avatarId = math.random(1, #freeAvatars)
    local avatar = freeAvatars[avatarId]

    -- Удаляем аватар из списка свободных
    table.remove(freeAvatars, avatarId)

    return avatar
end

-- Проверка, что все игроки готовы к игре
function IsEveryoneReady(teams)
    -- Если все игроки в командах готовы
    local isEveryoneReady = true

    for _, team in ipairs(teams) do
        for _, player in ipairs(getPlayersInTeam(team)) do
            isEveryoneReady = isEveryoneReady and getElementData(player, "isPlayerReady")
        end
    end

    return isEveryoneReady
end

-- Переключение режима управления машиной
function ToggleCarControls(player, state)
    toggleControl(player, "steer_forward", state)
    toggleControl(player, "steer_back", state)
    toggleControl(player, "accelerate", state)
    toggleControl(player, "brake_reverse", state)
end

-- Настройка игрока
function SetUpPlayer(player)
    toggleControl(player, "enter_exit", false)
    toggleControl(player, "enter_passenger", false)
    toggleControl(player, "handbrake", false)

    setPlayerHudComponentVisible(player, "all", false)

    setElementData(player, "avatar", nil)
    setElementData(player, "isPlayerReady", false)

    -- Сбрасываем позицию игрока
    spawnPlayer(player, 0, 0, 0)
end

-- Переключение режима отображения лобби
function ToggleLobby(player, state)
    triggerClientEvent(player, "onToggleLobby", player, state)
    fadeCamera(player, state)

    -- Настраиваем положение камеры
    if state then
        SetRandomCamera(player)
    end
end

-- Обновление таймера до старта игры
function UpdateGameStartTimer()
    -- Если таймер обнулен, пропускаем
    if gameStartTimer == nil then
        return
    end

    -- Если время закончилось, то начинаем первый раунд
    if gameStartTimerValue < 1 then
        StartRound()

        return
    end

    -- Обновляем значение таймера на клиенте
    triggerClientEvent("onUpdateTimerValue", resourceRoot, tostring(gameStartTimerValue))

    -- Обновляем значение таймера
    gameStartTimerValue = gameStartTimerValue - 1
end

-- Обновление таймера до конца раунда
function UpdateRoundTimer()
    -- Если таймер обнулен, пропускаем
    if roundTimer == nil then
        return
    end
    
    -- Если время закончилось, то завершаем раунд
    if roundTimerValue < 1 then
        EndRound()

        return
    end

    -- Проверяем условия завершения раунда
    local isEveryoneCompleted = true
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        if getElementData(player, "isPlayerReady") then
            -- Получаем команду игрока
            local team = getTeamName(getPlayerTeam(player))
            
            -- Получаем скорость движения игрока
            local speed = GetElementSpeed(player)

            -- Если игрок мертв или уже получил баллы (при условии, что его машина остановилась)
            isEveryoneCompleted = isEveryoneCompleted and (isPedDead(player) or teamsPlayers[team][player].scores > 0 and speed == 0)
        end
    end

    -- Если все игроки завершили действия, то завершаем раунд
    if isEveryoneCompleted then
        -- Прерываем отсчет до конца раунда
        if roundTimer and isTimer(roundTimer) then
            killTimer(roundTimer)
            roundTimer = nil

            -- Вызываем сброс таймера на клиенте
            triggerClientEvent("onUpdateRoundTimerValue", resourceRoot)
        end
        
        -- Завершаем раунд через несколько секунд
        endRoundTimer = setTimer(function()
            endRoundTimer = nil

            EndRound()
        end, 2500, 1)

        return
    end

    -- Обновляем значение таймера на клиенте
    triggerClientEvent("onUpdateRoundTimerValue", resourceRoot, tostring(roundTimerValue))

    -- Обновляем значение таймера
    roundTimerValue = roundTimerValue - 1
end

-- Начало нового раунда
function StartRound()
    -- Сбрасываем статус точек спавна
    for _, spawnPoint in ipairs(getElementsByType("pspawn")) do
        setElementData(spawnPoint, "isAlreadyUsed", nil)
    end

    -- Очищаем все машины оставшиеся с прошлого раунда
    local vehicles = getElementsByType("vehicle", resourceRoot)
    for _, vehicle in pairs(vehicles) do
        destroyElement(vehicle)
    end
    
    -- Для всех игроков
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        -- Скрываем лобби
        if round == 0 then
            ToggleLobby(player, false)
        end

        -- Если игрок был готов, то спавним его
        if getElementData(player, "isPlayerReady") then
            PlayerSpawn(player)

            -- Добавляем игрока к списку
            local team = getPlayerTeam(player)
            teamsPlayers[getTeamName(team)][player] = {
                element = player,
                avatar = getElementData(player, "avatar") or "cat01",
                scores = 0
            }
        else -- Иначе устанавливаем игроку камеру для наблюдения за мишенью
            fadeCamera(player, true)
            SetRandomCamera(player)
        end
    end

    -- Вычисляем максимальный размер команды
    local teams = getElementsByType("team")
    maxPlayersInTeam = math.max(countPlayersInTeam(teams[1]), countPlayersInTeam(teams[2]))

    -- Запускаем таймер раунда
    roundTimerValue = maxRoundTime
    roundTimer = setTimer(UpdateRoundTimer, 1000, roundTimerValue + 1)

    -- Увеличиваем номер раунда
    round = round + 1

    -- Активируем игровой интерфейс
    triggerClientEvent("onToggleGameUi", resourceRoot, true, teamsPlayers, maxPlayersInTeam, round .. " / " .. maxRounds)
end

-- Завершение раунда
function EndRound()
    -- Прерываем отсчет до конца раунда
    if roundTimer and isTimer(roundTimer) then
        killTimer(roundTimer)
        roundTimer = nil

        -- Вызываем сброс таймера на клиенте
        triggerClientEvent("onUpdateRoundTimerValue", resourceRoot)
    end
    
    -- Отключаем отображение игрового интерфейса
    triggerClientEvent("onToggleGameUi", resourceRoot, false)

    -- Затемняем экран для всех игроков
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        fadeCamera(player, false)
    end

    -- Обновляем баллы команды 1
    local blueTeamScores = 0
    for _, player in pairs(teamsPlayers.blue) do
        blueTeamScores = blueTeamScores + player.scores
        player.scores = 0
    end

    teamsPlayers.blue.total.scores = blueTeamScores

    -- Обновляем баллы команды 2
    local redTeamScores = 0
    for _, player in pairs(teamsPlayers.red) do
        redTeamScores = redTeamScores + player.scores
        player.scores = 0
    end

    teamsPlayers.red.total.scores = redTeamScores

    -- Отображаем экран с баллами за раунд
    triggerClientEvent("onToggleScoresUi", resourceRoot, { blue = blueTeamScores, red = redTeamScores }, round == maxRounds)

    -- Через некоторое время
    nextRoundTimer = setTimer(function()
        nextRoundTimer = nil

        -- Скрываем экран с баллами за раунд
        triggerClientEvent("onToggleScoresUi", resourceRoot)

        if round < maxRounds then
            -- Запускаем новый раунд
            StartRound()
        else
            -- Запускаем новую карту для режима
            StartNextMap()
        end
    end, 5000, 1)
end

-- Запуск новой карты для режима
function StartNextMap()
    -- Получаем текущую карту и режим
    local currentMap = exports["mapmanager"]:getRunningGamemodeMap()
    local currentGamemode = exports["mapmanager"]:getRunningGamemode()

    -- Получаем все карты, которые совместимы с режимом
    local maps = exports["mapmanager"]:getMapsCompatibleWithGamemode(currentGamemode)
    if #maps == 0 then
        return
    end

    -- Если карта всего одна, то перезапускаем ее
    if #maps == 1 then
        exports["mapmanager"]:changeGamemodeMap(currentMap, currentGamemode)

        return
    end

    -- Исключаем текущую карту из списка
    for i, map in ipairs(maps) do
        if map == currentMap then
            table.remove(maps, i)

            break
        end
    end

    -- Выбираем следующую карту случайно и запускаем ее
    local newMap = maps[math.random(1, #maps)]
    exports["mapmanager"]:changeGamemodeMap(newMap, currentGamemode)
end

-- Спавн игрока на случайной точке спавна
function PlayerSpawn(player)
    if not player or not isElement(player) then
        return
	end

    -- Получаем команду игрока
    local team = getPlayerTeam(player)
    if not team then
        return
    end

    -- Получаем точки спавна для команды
    local spawnPoints = getElementChildren(team, "pspawn")
    if #spawnPoints == 0 then
        return
    end

    -- Получаем следующую свободную точку спавна
    local spawn = nil
    for _, spawnPoint in ipairs(spawnPoints) do
        if not getElementData(spawnPoint, "isAlreadyUsed") then
            spawn = spawnPoint

            break
        end
    end

    -- Если точка спавна не найдена, выходим
    if not spawn or not isElement(spawn) then
        return
    end

    -- Отмечаем точку спавна как занятую
    setElementData(spawn, "isAlreadyUsed", true)

    -- Извлекаем позицию, вращение и доступные скины
    local x, y, z, r = GetTransform(spawn)
    local playerSkins = getValidPedModels()

    -- Уничтожаем транспортное средство, если оно уже существует
    local veh = getPedOccupiedVehicle(player)
    if veh then
        destroyElement(veh)
    end

    -- Спавним игрока
    spawnPlayer(player, 0, 0, 0, r, playerSkins[math.random(1, #playerSkins)], 0, 0)

    -- Создаем машину и настраиваем
    veh = createVehicle(402, x, y, z, 0, 0, r, " looser ")
    setVehicleDamageProof(veh, true)
    setVehicleColor(veh, getTeamColor(team))

    -- Помещаем в нее игрока
    warpPedIntoVehicle(player, veh)

    -- Включаем управление машиной
    ToggleCarControls(player, true)

    -- Настраиваем камеру
    fadeCamera(player, true)
    setCameraTarget(player, player)
end

-- Подключение нового игрока
function OnPlayerResourceStart(loadedResource)
    -- Если ресурс - карта, скрываем интерфейс игрока
    local resourceName = getResourceName(loadedResource)
    if StartsWith(resourceName, "orumble-m") then
        -- Скрываем экран с баллами за раунд
        triggerClientEvent("onToggleScoresUi", source)

        -- Отключаем отображение игрового интерфейса
        triggerClientEvent(source, "onToggleGameUi", source, false)
    end
    
    -- Если главный ресурс, настраиваем игрока
    if loadedResource == getThisResource() then
        SetUpPlayer(source)

        -- Настраиваем игрока на клиенте
        triggerClientEvent(source, "onPlayerSetUp", source, time)

        -- Если раунд не начался, активируем лобби
        if round == 0 then
            ToggleLobby(source, true)

            return
        end

        -- Активируем игровой интерфейс
        triggerClientEvent(source, "onToggleGameUi", source, true, teamsPlayers, maxPlayersInTeam, round .. " / " .. maxRounds)
    end    
end

-- Выход игрока с сервера
function OnPlayerQuit()
    -- Возвращаем аватар в список свободных
    local avatar = getElementData(source, "avatar")
    if avatar then
        table.insert(freeAvatars, avatar)
    end
end

-- Смерть игрока
function OnPlayerWasted()
    -- Если раунд завершен, то не обрабатываем
    if not roundTimer or not isTimer(roundTimer) then
        return
    end
    
    -- Переключаем камеру на наблюдение за площадкой
    fadeCamera(source, true)
    SetRandomCamera(source)
end

-- Попадание игрока в зону
function OnScoreZoneUpdate(scoreZone)
    -- Получаем баллы для зоны
    local score = (scoreZone and getElementData(scoreZone, "score")) or 0

    -- Получаем команду игрока
    local team = getPlayerTeam(client)
    if not team or not isElement(team) then
        return
    end

    -- Обновляем очки
    local teamName = getTeamName(team)
    teamsPlayers[teamName][client].scores = score

    -- Отключаем управление машиной
    if scoreZone ~= nil then
        ToggleCarControls(client, false)
    end

    -- Вызываем обновление очков на клиентах
    triggerClientEvent("onPlayerUpdatePoints", resourceRoot, client, teamsPlayers[teamName][client].avatar, teamName, tonumber(score))
end

-- Смена команды игрока
function OnPlayerJoinTeam(teamName)
    -- Получаем данные о команде
    local team = getTeamFromName(teamName)
    local teamPlayers = countPlayersInTeam(team)
    
    -- Проверяем число участников в команде
    if teamPlayers >= maxTeamPlayers then
        outputChatBox("В команде уже достаточно человек", client)

        return
    end

    -- Если уже идет отсчет до начала игры, то сбрасываем его
    if gameStartTimer and isTimer(gameStartTimer) then
        killTimer(gameStartTimer)

        -- Вызываем сброс таймера на клиенте
        triggerClientEvent("onUpdateTimerValue", resourceRoot)
    end

    -- Устанавливаем команду игрока
    setPlayerTeam(client, team)
    setElementData(client, "isPlayerReady", false)

    -- Получаем аватарку игрока или подбираем новую
    local avatar = getElementData(client, "avatar")
    if not avatar then
        avatar = GetNewAvatar()
        setElementData(client, "avatar", avatar)
    end

    -- Вызываем клиентскую часть команды
    triggerClientEvent("onPlayerChangeTeam", resourceRoot, client, avatar, teamName)
end

-- Перевод игрока в режим наблюдателя
function OnPlayerJoinSpectator()
    -- Получаем данные о команде
    local team = getPlayerTeam(client)
    if not team or not isElement(team) then
        return
    end

    -- Получаем список команд
    local teams = getElementsByType("team")

    -- Если уже идет отсчет до начала игры, то сбрасываем его
    if not IsEveryoneReady(teams) and gameStartTimer and isTimer(gameStartTimer) then
        killTimer(gameStartTimer)

        -- Вызываем сброс таймера на клиенте
        triggerClientEvent("onUpdateTimerValue", resourceRoot)
    end

    -- Сбрасываем команду игрока
    setPlayerTeam(client)
    setElementData(client, "isPlayerReady", false)

    -- Получаем аватарку игрока и освобождаем ее
    local avatar = getElementData(client, "avatar")
    if avatar then
        table.insert(freeAvatars, avatar)
        setElementData(client, "avatar", nil)
    end

    -- Вызываем клиентскую часть команды
    triggerClientEvent("onPlayerChangeTeam", resourceRoot, client)
end

-- Смена статуса готовности игрока
function OnPlayerSetReady()
    -- Обновлянем статус готовности игрока
    local ready = getElementData(client, "isPlayerReady") or false
    setElementData(client, "isPlayerReady", not ready)

    -- Вызываем клиентскую часть команды
    triggerClientEvent("onPlayerChangeReady", resourceRoot, client, not ready)

    -- Если статус сброшен, то пропускаем
    if ready then
        -- Если уже идет отсчет до начала игры, то сбрасываем его
        if gameStartTimer and isTimer(gameStartTimer) then
            killTimer(gameStartTimer)

            -- Вызываем сброс таймера на клиенте
            triggerClientEvent("onUpdateTimerValue", resourceRoot)
        end

        return
    end

    -- Если уже идет отсчет до начала игры, то пропускаем
    if gameStartTimer and isTimer(gameStartTimer) then
        return
    end

    -- Если игроков достаточно для начала игры
    local teams = getElementsByType("team")
    if countPlayersInTeam(teams[1]) == 0 or countPlayersInTeam(teams[2]) == 0 then
        --return
    end

    -- Запускаем отсчет до начала игры
    if IsEveryoneReady(teams) then
        gameStartTimerValue = 5
        gameStartTimer = setTimer(UpdateGameStartTimer, 1000, gameStartTimerValue + 1)
    end
end

-- Запуск ресура
function OnResourceStart(resource)
    -- Если запущена карта для режима
    local resourceName = getResourceName(resource)
    if StartsWith(resourceName, "orumble-m") then
        -- Если карта не загружена корректно, то выходим
        if #getElementsByType("pspawn") == 0 then
            return
        end

        -- Настройки для игроков
        local players = getElementsByType("player")
        for _, player in pairs(players) do
            SetUpPlayer(player)
        end

        -- Очищаем все машины оставшиеся с прошлого раунда
        local vehicles = getElementsByType("vehicle", resourceRoot)
        for _, vehicle in pairs(vehicles) do
            destroyElement(vehicle)
        end

        -- Очищаем все заны колизии оставшиеся с прошлого раунда
        local col = getElementsByType("colshape", resourceRoot)
        for _, col in pairs(col) do
            destroyElement(col)
        end
        
        -- Сохраняем коневой элемент карты и настройки ресурса
        mapRoot = getResourceRootElement(resource)
        maxTeamPlayers = (get(resourceName .. ".maxplayers") or 0) / 2
        maxRounds = get(resourceName .. ".rounds") or 0
        maxRoundTime = get(resourceName .. ".roundtime") or 60
        
        -- Сохраняем время из настроек карты
        local timeSetting = get(resourceName .. ".time") or "12:0"
        local timeParts = split(timeSetting, ":")
        time.hours = timeParts[1]
        time.minutes = timeParts[2]

        -- Сбрасываем настройки
        round = 0
        gameStartTimerValue = 0
        roundTimerValue = 0
        maxPlayersInTeam = 0
        
        teamsPlayers = {
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

        -- Сбрасываем таймер начала игры, если он запущен
        if gameStartTimer and isTimer(gameStartTimer) then
            killTimer(gameStartTimer)
        end

        gameStartTimer = nil

        -- Сбрасываем таймер конца раунда, если он запущен
        if roundTimer and isTimer(roundTimer) then
            killTimer(roundTimer)
        end

        roundTimer = nil

        -- Сбрасываем таймер конца раунда, если он запущен
        if endRoundTimer and isTimer(endRoundTimer) then
            killTimer(endRoundTimer)
        end

        endRoundTimer = nil

        -- Сбрасываем таймер сдедующего раунда, если он запущен
        if nextRoundTimer and isTimer(nextRoundTimer) then
            killTimer(nextRoundTimer)
        end

        nextRoundTimer = nil

        -- Отключаем удаленные объекты с карты
        toggleMapObjects(mapRoot, false)

        -- Загружаем дополнительные настройки карты
        loadMap(mapRoot)
        
        -- Активируем лобби
        local players = getElementsByType("player")
        for _, player in pairs(players) do
            ToggleLobby(player, true)
        end
    end
end

-- Остановка ресура
function OnResourceStop()
    -- Сбрасываем настройки для игроков
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        toggleControl(player, "enter_exit", true)
		toggleControl(player, "enter_passenger", true)
		toggleControl(player, "handbrake", true)
        ToggleCarControls(player, true)

        setPlayerHudComponentVisible(player, "all", true)
    end

    -- Включаем удаленные объекты с карты
    toggleMapObjects(mapRoot, true)

    -- Сбрасываем корневой элемент
    mapRoot = nil
end

-- Регистрируем новые события
addEvent("onPlayerJoinTeam", true)
addEvent("onPlayerJoinSpectator", true)
addEvent("onPlayerSetReady", true)
addEvent("onScoreZoneUpdate", true)

-- Подписка на события
addEventHandler("onPlayerQuit", root, OnPlayerQuit)
addEventHandler("onPlayerWasted", root, OnPlayerWasted)
addEventHandler("onPlayerJoinTeam", root, OnPlayerJoinTeam)
addEventHandler("onPlayerJoinSpectator", root, OnPlayerJoinSpectator)
addEventHandler("onPlayerSetReady", root, OnPlayerSetReady)
addEventHandler("onScoreZoneUpdate", root, OnScoreZoneUpdate)
addEventHandler("onResourceStart", root, OnResourceStart)
addEventHandler("onResourceStop", resourceRoot, OnResourceStop)
addEventHandler("onPlayerResourceStart", root, OnPlayerResourceStart)