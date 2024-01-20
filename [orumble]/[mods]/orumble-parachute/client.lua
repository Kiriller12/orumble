-----------------------------------------------------------------------
-- Original parachute script for MTA: SA by Jax + Talidan
-- Parts of their code used for this car parachute script
-- Big thanks to them
-----------------------------------------------------------------------

-- Константы
local defaultGravity = 0.008
local benchmarkFPS = 30
local defaultGameSpeed = 1
local minGroundHeight = 1

-- Настройки парашюта
local fallSpeed = -0.15
local haltSpeed = 0.02
local haltHorizontalSpeed = 0.005
local moveSpeed = 0.2
local turnSpeed = 1.5 -- При изменении все ломается
local yMaxTurn = 45
local rotateAcceleration = 0.75

-- Текущие параметры парашюта
local parachuteVehicle = nil
local lastSpeed = 0.0
local lastHorizontalSpeed = 0.0
local lastTick = 0.0
local ry = 0

-- Вычисление значения скорости
function CalculateSpeed(speed)
    return speed * (getGravity() / defaultGravity)
end

-- Вычисление значения угла
function CalculateAngle(angle, tick)
	return ((tick * angle) / benchmarkFPS) * (getGameSpeed() / defaultGameSpeed)
end

-- Проверяет нажатие клавиши
function GetMoveState(key)
	return getAnalogControlState(key) > 0.5
end

-- Проверяет находится ли транспортное средство на земле
function IsVehicleGrounded(vehicle)
    return isVehicleWheelOnGround(vehicle, 0)
        or isVehicleWheelOnGround(vehicle, 1)
        or isVehicleWheelOnGround(vehicle, 2)
        or isVehicleWheelOnGround(vehicle, 3)
end

-- Обновление парашюта
function OnParachuteUpdate()
    -- Не обрабатываем, если нет парашюта
    if not parachuteVehicle or not isElement(parachuteVehicle) then
        return
    end

    -- Получаем позицию транспортного средства
    local x, y, z = getElementPosition(parachuteVehicle)

    -- Проверяем нужно ли сбросить парашют при приземлении
    if IsVehicleGrounded(parachuteVehicle) or processLineOfSight(x, y, z, x, y, z - minGroundHeight, true, true, false, true, true, false, false, false, parachuteVehicle) then
        OnDeactivateParachute()
        triggerServerEvent("onParachuteLanding", resourceRoot)

        return
    end

    -- Вычисляем значения тиков
    local currentTick = getTickCount()
    lastTick = lastTick or currentTick
	
	local tickDiff =  currentTick - lastTick
	lastTick = currentTick

	if tickDiff <= 0 then
        return
    end

    -- Получаем скорость и вращение автомобиля
    local _, _, rz = getElementRotation(parachuteVehicle)
    local vx, vy, vz = getElementVelocity(parachuteVehicle)

    -- Инвертируем вращаение
    rz = -rz

    -- Если нажата кнопка "назад", замедляем скорость
    local speedMultiplier = 1
    if GetMoveState("brake_reverse") then
        speedMultiplier = 0.5
    end

    -- Вычисляем значения скорости движения и падения
    local currentMoveSpeed = CalculateSpeed(moveSpeed)
    local currentFallSpeed = CalculateSpeed(fallSpeed * speedMultiplier)

    -- Если движемся слишком медленно, то ускоряемся
    if vz < currentFallSpeed then
        if lastSpeed < 0 then
            if lastSpeed >= currentFallSpeed then
                vz = currentFallSpeed
            else
                vz = lastSpeed + CalculateSpeed(haltSpeed)
            end
        end
    -- Если движемся слишком быстро, замедляемся
    elseif vz > currentFallSpeed then
        vz = currentFallSpeed

        if lastSpeed <= vz then
            currentMoveSpeed = currentMoveSpeed / 2
        end
    end

    -- Если движемся слишком медленно, то ускоряемся
    local horizontalMoveSpeed = Vector2(vx, vy).length 
    if horizontalMoveSpeed < currentMoveSpeed then
        horizontalMoveSpeed = lastHorizontalSpeed + CalculateSpeed(haltHorizontalSpeed)
    -- Если движемся слишком быстро, замедляемся
    elseif horizontalMoveSpeed > currentMoveSpeed then
        horizontalMoveSpeed = lastHorizontalSpeed - CalculateSpeed(haltHorizontalSpeed)
    end

    -- Обновляем последнюю известную скорость
    lastSpeed = vz
    lastHorizontalSpeed = horizontalMoveSpeed

    -- Вычисляем направление движения по вращению
    local dirX = math.sin(math.rad(rz))
    local dirY = math.cos(math.rad(rz))

    -- Вычисляем новую скорость вдижения
    vx = dirX * horizontalMoveSpeed
	vy = dirY * horizontalMoveSpeed

    if vz == currentFallSpeed then
        if GetMoveState("vehicle_left") then
            rz = rz - CalculateAngle(turnSpeed, tickDiff)

            if -yMaxTurn < ry then
                ry = ry - CalculateAngle(rotateAcceleration * speedMultiplier, tickDiff)
            end
        elseif GetMoveState("vehicle_right") then
            rz = rz + CalculateAngle(turnSpeed, tickDiff)

            if yMaxTurn > ry then
                ry = ry + CalculateAngle(rotateAcceleration * speedMultiplier, tickDiff)
            end
        else
            if math.floor(ry) < 0 then
                ry = ry + CalculateAngle(rotateAcceleration, tickDiff)
            elseif math.floor(ry) > 0 then
                ry = ry - CalculateAngle(rotateAcceleration, tickDiff)
            end
        end

        setElementRotation(parachuteVehicle, 0, ry, -rz)
    end

    -- Применяем настройки
    setElementVelocity(parachuteVehicle, vx, vy, vz)
end

-- Активация парашюта
function OnActivateParachute(veh)
    parachuteVehicle = veh

    lastSpeed = 0.0
    lastTick = 0.0
    ry = 0
end

-- Деактивация парашюта
function OnDeactivateParachute()
    parachuteVehicle = nil

    lastSpeed = 0.0
    lastTick = 0.0
    ry = 0
end

-- Обновление отрисовки
function OnClientRender()
	-- Если игрок мертв, то просто пропускаем
    if isPedDead(localPlayer) then
        return
    end
    
    -- Симуляция поведения парашюта
    OnParachuteUpdate()
end

-- Регистрируем новые события
addEvent("onActivateParachute", true)
addEvent("onDeactivateParachute", true)

-- Подписка на события
addEventHandler("onActivateParachute", localPlayer, OnActivateParachute)
addEventHandler("onDeactivateParachute", localPlayer, OnDeactivateParachute)
addEventHandler("onClientRender", root, OnClientRender)