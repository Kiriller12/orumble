-- Проверяет, что курсор мыши находится в указанном прямоугольнике
function IsMouseInPosition(x, y, width, height)
	if not isCursorShowing() then
		return false
	end

	local sx, sy = guiGetScreenSize()
	local cx, cy = getCursorPosition()
	local cx, cy = (cx * sx), (cy * sy)
	
	return ((cx >= x and cx <= x + width) and (cy >= y and cy <= y + height))
end

-- Отрисовка прямоугольника с рамкой
function DxDrawBorderedRectangle(x, y, width, height, color1, color2, _width, postGUI)
    local _width = _width or 1

    dxDrawRectangle ( x+1, y+1, width-1, height-1, color1, postGUI )
    dxDrawLine ( x, y, x+width, y, color2, _width, postGUI ) -- Top
    dxDrawLine ( x, y, x, y+height, color2, _width, postGUI ) -- Left
    dxDrawLine ( x, y+height, x+width, y+height, color2, _width, postGUI ) -- Bottom
    dxDrawLine ( x+width, y, x+width, y+height, color2, _width, postGUI ) -- Right
end

-- Проверяет находится ли транспортное средство на земле
function IsVehicleGrounded(vehicle)
    local x, y, z = getElementPosition(vehicle)

    return processLineOfSight(x, y, z, x, y, z - 2, true, true, false, true, false, false, true, false, vehicle)
end