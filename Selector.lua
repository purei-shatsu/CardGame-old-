Selector = {
	count = 0,
	object = {},
}

function Selector.initialize()
	Selector.canvas = {
		object = love.graphics.newCanvas(Screen.width, Screen.height),
		position = love.graphics.newCanvas(Screen.width, Screen.height),
	}
	Selector.imageData = {}
	Selector.diffX = 0
	Selector.diffY = 0
end

function Selector.create(object)
	Selector.count = Selector.count + 1
	Selector.object[Selector.count] = object
	return Selector.count
end

function Selector.getCanvas()
	return Selector.canvas.object, Selector.canvas.position
end

function Selector.setObject(id, object)
	Selector.object[id] = object
end

function Selector.sendId(id)
	if id==0 then
		Game.shaderSendColor('selCol', {0, 0, 0, 0})
	else
		local b = id%256
		local g = (id/256)%256
		local r = (id/256/256)%256
		Game.shaderSendColor('selCol', {r, g, b, 255})
	end
end

function Selector.sendDiff(x, y)
	Selector.diffX = x
	Selector.diffY = y
end

function Selector.createImageData()
	Selector.imageData.object = Selector.canvas.object:newImageData()
	Selector.imageData.position = Selector.canvas.position:newImageData()
end

function Selector.getMousePosition()
	return love.mouse.getX()-Selector.diffX, love.mouse.getY()-Selector.diffY
end

function Selector.getId()
	local imgData = Selector.imageData
	imgData = imgData.object
	if not imgData then
		error('Image Data was not created.', 2)
	end
	local x,y = Selector.getMousePosition()
	x = math.min(Screen.width-1, math.max(0, x))
	y = math.min(Screen.height-1, math.max(0, y))
	local r,g,b = imgData:getPixel(x, y)
	return (r*256 + g)*256 + b
end

function Selector.isId(id)
	return id==Selector.getId()
end

function Selector.getObject()
	return Selector.object[Selector.getId()]
end

function Selector.isObject(object)
	return object==Selector.getObject()
end

function Selector.getPosition()
	local imgData = Selector.imageData
	imgData = imgData.position
	if not imgData then
		error('Image Data was not created.', 2)
	end
	local x,y = Selector.getMousePosition()
	x = math.min(Screen.width-1, math.max(0, x))
	y = math.min(Screen.height-1, math.max(0, y))
	local r,g,b = imgData:getPixel(x, y)
	x = b + (g%16-8)*256
	y = r + math.floor(g/16-8)*256
	--x = (x/Screen.width - 0.5)*Screen.width/Screen.height
	x = x/Screen.width - 0.5
	y = y/Screen.height - 0.5
	return x,y
end
















