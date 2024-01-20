-- Текущая зона очков
local scoreZone = nil

-- Обновление отрисовки
local function OnClientRender()
	-- Если игрок мертв, то просто пропускаем
    if isPedDead(localPlayer) then
        return
    end

    -- Получаем машину игрока
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh and not isElement(veh) then
        return
    end

    -- Получаем координаты игрока и его машину
    local x, y, z = getElementPosition(veh)
    
    -- Получаем элементы типа "смертельная зона"
    local deathZone = getElementsByType("deathzone")

    -- Если зона найдена
    if deathZone and isElement(deathZone[1]) then
        -- Получаем минимальную позицию и позицию игрока
        local minZ = getElementData(deathZone[1], "minZ")

        -- Если позиция игрока ниже минимума, то убиваем его
        if z < tonumber(minZ) then
            blowVehicle(veh, true)
        end
    end

    -- Проверяем находится ли транспортное средство на земле
    if not IsVehicleGrounded(veh) then
        -- Обнуляем очки, если они еще не обнулены
        if scoreZone ~= nil then
            -- Обновляем текущую зону
            scoreZone = nil

            -- Обновляем данные на сервере
            triggerServerEvent("onScoreZoneUpdate", resourceRoot, scoreZone)
        end

        return
    end

    -- Проверяем нахождение в зоне очков
    local newScoreZone = nil
    local colShapes = getElementsByType("colshape", mapRoot)
    for _, col in ipairs(colShapes) do
        -- Проверяем находится ли центр машины в зоне
        if isInsideColShape(col, x, y, z) then
            -- Сохраняем зону
            newScoreZone = col

            break
        end
    end

    -- Обновляем только если новая зона отличается
    if scoreZone ~= newScoreZone then
        -- Обновляем текущую зону
        scoreZone = newScoreZone

        -- Обновляем данные на сервере
        triggerServerEvent("onScoreZoneUpdate", resourceRoot, scoreZone)
    end
end

-- Получение урона автомобилем
local function OnClientVehicleDamage()
    -- Обратбатываем событие только для машины игрока, если он жив
    if isPedDead(localPlayer) or getVehicleOccupant(source) ~= localPlayer then
        return
    end

    -- Восстанавливаем машину визуально
    fixVehicle(source)    

    -- Отменяем урон
    cancelEvent()
end

-- Настройка игрока
local function OnPlayerSetUp(time)
    setTime(time.hours, time.minutes)
end

-- Регистрируем новые события
addEvent("onPlayerSetUp", true)

-- Подписка на события
addEventHandler("onClientRender", root, OnClientRender)
addEventHandler("onClientVehicleDamage", root, OnClientVehicleDamage)
addEventHandler("onPlayerSetUp", root, OnPlayerSetUp)