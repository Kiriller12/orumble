-- Включение/выключение парашюта
function ToggleParachute(player)
    -- Если игрок мертв или не существует, то просто пропускаем
    if not player or not isElement(player) or isPedDead(player) then
        return
    end
    
    -- Получаем машину игрока
    local veh = getPedOccupiedVehicle(player)
    if not veh or not isElement(veh) then
        return
    end

    -- Получаем текущий парашют
    local parachute = getElementData(player, "carParachute")

    -- Если парашют есть, то сбрасываем его
    if parachute and isElement(parachute) then
        DeactivateParachute(player, parachute)

        -- Вызываем клиентскую часть команды
        triggerClientEvent(player, "onDeactivateParachute", player)
    else -- Иначе открываем новый
        if isVehicleOnGround(veh) then
            return
        end

        -- Создаем модель парашюта и прикрепляем к машине
        local x, y, z = getElementPosition(veh)
        local rx, ry, rz = getElementRotation(veh)

        parachute = createObject(3131, x, y - 0.5, z, rx, ry, rz)
        attachElements(parachute, veh, 0, -0.5, 0)
        setElementData(player, "carParachute", parachute)

        -- Вызываем клиентскую часть команды
        triggerClientEvent(player, "onActivateParachute", player, veh)
    end
end

-- Деактивация парашюта
function DeactivateParachute(player, parachute)
    -- Если парашют есть, то сбрасываем его
    detachElements(parachute)
    setTimer(destroyElement, 1500, 1, parachute)

    setElementData(player, "carParachute", nil)
end

-- Ускорение автомобиля игрока
function AcceleratePlayerVehicle(player, value)
    -- Получаем машину игрока
    local veh = getPedOccupiedVehicle(player)
    if not veh or not isElement(veh) then
        return
    end

    -- Получаем вращаение автомобиля
    local _, _, rz = getElementRotation(veh)

    -- Вычисляем направление движения по вращению
    local dirX = math.sin(math.rad(-rz))
    local dirY = math.cos(math.rad(-rz))

    -- Придаем ускорение
    local vx, vy, vz = getElementVelocity(veh)
    setElementVelocity(veh, vx + dirX * value, vy + dirY * value, vz)
end

-- Сброс парашюта при приземлении
function OnParachuteLanding()
    -- Если игрок мертв или не существует, то просто пропускаем
    if not client or not isElement(client) or isPedDead(client) then
        return
    end
    
    -- Получаем текущий парашют
    local parachute = getElementData(client, "carParachute")
    if not parachute or not isElement(parachute) then
        return
    end

    -- Сбрасываем парашют
    DeactivateParachute(client, parachute)

    -- Придаем набольшое ускорение
    AcceleratePlayerVehicle(client, 0.05)
end

-- Взрыв машины
function OnVehicleExplode()
    -- Если игрок-водитель не существует, то просто пропускаем
    local player = getVehicleOccupant(source)
    if not player or not isElement(player) then
        return
    end

    -- Получаем текущий парашют
    local parachute = getElementData(player, "carParachute")

    -- Если парашют есть, то сбрасываем его
    if parachute and isElement(parachute) then
        DeactivateParachute(player, parachute)

        -- Вызываем клиентскую часть команды
        triggerClientEvent(player, "onDeactivateParachute", player)
    end
end

-- Смерть игрока
function OnPlayerWasted()
    -- Получаем текущий парашют
    local parachute = getElementData(source, "carParachute")

    -- Если парашют есть, то сбрасываем его
    if parachute and isElement(parachute) then
        DeactivateParachute(source, parachute)

        -- Вызываем клиентскую часть команды
        triggerClientEvent(source, "onDeactivateParachute", source)
    end
end

-- Респавн игрока
function OnPlayerSpawn()
    -- Получаем текущий парашют
    local parachute = getElementData(source, "carParachute")

    -- Если парашют есть, то сбрасываем его
    if parachute and isElement(parachute) then
        DeactivateParachute(source, parachute)

        -- Вызываем клиентскую часть команды
        triggerClientEvent(source, "onDeactivateParachute", source)
    end
end

-- Запуск ресура
function OnResourceStart(resource)
    -- Устанавливаем настройки для игроков
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        setElementData(player, "carParachute", nil)

        bindKey(player, "space", "down", "parachute")
    end
end

-- Остановка ресура
function OnResourceStop()
    -- Сбрасываем настройки для игроков
    local players = getElementsByType("player")
    for _, player in pairs(players) do
        unbindKey(player, "space", "down", "parachute")
    end
end

-- Подключение нового игрока
function OnPlayerJoin()
    setElementData(source, "carParachute", nil)

    bindKey(source, "space", "down", "parachute")
end

-- Регистрируем новые события
addEvent("onParachuteLanding", true)

-- Подписка на события
addEventHandler("onParachuteLanding", root, OnParachuteLanding)
addEventHandler("onVehicleExplode", root, OnVehicleExplode)
addEventHandler("onPlayerWasted", root, OnPlayerWasted)
addEventHandler("onPlayerSpawn", root, OnPlayerSpawn)
addEventHandler("onPlayerJoin", root, OnPlayerJoin)
addEventHandler("onResourceStart", root, OnResourceStart)
addEventHandler("onResourceStop", resourceRoot, OnResourceStop)

-- Подписка на команды
addCommandHandler("parachute", ToggleParachute)