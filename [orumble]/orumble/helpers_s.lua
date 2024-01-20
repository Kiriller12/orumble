-- Проверяет, что строка начинается с указанной строки
function StartsWith(str, start)
    return string.sub(str, 1, #start) == start
end

-- Возвращает позицию и вращение
function GetTransform(spawnPoint)
    local x = getElementData(spawnPoint, "posX")
    local y = getElementData(spawnPoint, "posY")
    local z = getElementData(spawnPoint, "posZ")
    local r = getElementData(spawnPoint, "rot")

    return x, y, z, r
end

-- Возвращает позицию и цель камеры
function GetCameraValues(camera)
    local x = getElementData(camera, "posX")
    local y = getElementData(camera, "posY")
    local z = getElementData(camera, "posZ")
    local tx = getElementData(camera, "targetX")
    local ty = getElementData(camera, "targetY")
    local tz = getElementData(camera, "targetZ")

    return x, y, z, tx, ty, tz
end

-- Возвращает позицию после вращения системы координат
function GetPointAfterAxisRotation(x, y, angle)
    local a = math.rad(angle)
 
    local nx = x * math.cos(a) + y * math.sin(a)
    local ny = - x * math.sin(a) + y * math.cos(a)
 
    return nx, ny
end

-- Возвращает скорость движения элемента
function GetElementSpeed(element)
    return Vector3(getElementVelocity(element)).length
end