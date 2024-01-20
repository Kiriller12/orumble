-- Удаление или восстановление объектов карты
function toggleMapObjects(mapRoot, state)
	-- Если корневой элемент не задан
	if not mapRoot or not isElement(mapRoot) then
		return
	end
	
	local removeObjects = getElementsByType("removeWorldObject", mapRoot)
	
	for _, objectElement in ipairs(removeObjects) do
		local objectModel = getElementData(objectElement, "model")
		local objectLODModel = getElementData(objectElement, "lodModel")
		local posX = getElementData(objectElement, "posX")
		local posY = getElementData(objectElement, "posY")
		local posZ = getElementData(objectElement, "posZ")
		local objectInterior = getElementData(objectElement, "interior") or 0
		local objectRadius = getElementData(objectElement, "radius")

		if state then
			restoreWorldModel(objectModel, objectRadius, posX, posY, posZ, objectInterior)
			restoreWorldModel(objectLODModel, objectRadius, posX, posY, posZ, objectInterior)
		else
			removeWorldModel(objectModel, objectRadius, posX, posY, posZ, objectInterior)
			removeWorldModel(objectLODModel, objectRadius, posX, posY, posZ, objectInterior)
		end
	end
end

-- Загрузка карты
function loadMap(mapRoot)
	-- Если корневой элемент не задан
	if not mapRoot or not isElement(mapRoot) then
		return
	end
	
	-- Получаем все группы
	local objectGroups = getElementsByType("objectgroup", mapRoot)

	for _, group in ipairs(objectGroups) do
		-- Получаем координаты и вращение группы
		local gx, gy, gz, gr = GetTransform(group)

		-- Получаем все дочерние элементы группы
		local children = getElementChildren(group)
		for _, child in ipairs(children) do
			-- Получаем координаты и вращение элемента
			local x, y, z = getElementPosition(child)
			local rx, ry, rz = getElementRotation(child)

			-- Вычисляем новые координаты после вращения точки отсчета
			local nx, ny = GetPointAfterAxisRotation(x, y, gr)

			-- Обновляем координаты и вращение элемента относительно группы
			setElementPosition(child, gx + nx, gy + ny, gz + z)
			setElementRotation(child, rx, ry, rz - gr)
		end
	end

	-- Получаем зоны очков
	local scoreZones = getElementsByType("scorezone", mapRoot)

	for _, zone in ipairs(scoreZones) do
		-- Параметры зоны начисления баллов
		local x = getElementData(zone, "posX")
		local y = getElementData(zone, "posY")
		local z = getElementData(zone, "posZ")
		local radius = getElementData(zone, "radius")
		local height = getElementData(zone, "height")
		local score = getElementData(zone, "score")

		-- Создаем зоны колизии
		local colShape = createColTube(x, y, z, radius, height)
		setElementData(colShape, "score", tonumber(score))

		-- Уничтожаем исходный элемент
		destroyElement(zone)
	end
end