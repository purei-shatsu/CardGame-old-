local fov = 2
c = {} --global table for effects (indexed by code)

Game = {
	card = {},
	player = {},
	angle = 45*math.pi/180,
}

function Game.initialize()
	Game.pressed = {}
	Game.loadDb()
	Game.createShader()
	Game.createCanvas()
	Selector.initialize()
	Field.initialize()
	Game.startMatch()
end

local speed = 45*math.pi/180/5
function Game.wheelmoved(x, y)
	Game.angle = Game.angle + speed*y
	Game.shader:send('angle', Game.angle)
end

function Game.update(dt)
	--update mouse and keyboard
	Game.pressed.mouse = {}
	Game.pressed.keyboard = {}
	
	--select
	Selector.createImageData()
	
	--match
	Game.match:update(dt)
	
	--fullscreen
	if (Game.hasKeyPressed{'kpenter', 'return'}) and (love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen(), 'desktop')
		Game.resetScreen()
	end
end

function Game.draw()
	--clear and set canvas
	local objectCanvas, positionCanvas = Selector.getCanvas()
	love.graphics.setCanvas(Game.canvas, objectCanvas, positionCanvas)
	love.graphics.clear()
	
	--match
	Game.match:draw((Screen.width-Screen.height)/2.3, 0)
	
	--copy to screen
	love.graphics.setCanvas()
	Game.setShader()
	--[[
	love.graphics.draw(positionCanvas)
	love.graphics.draw(objectCanvas)
	--]]
	love.graphics.draw(Game.canvas)
end

function Game.resetScreen()
	Screen.width, Screen.height = love.graphics.getDimensions()
	Game.createCanvas()
	Game.match:createCanvas()
	Selector.initialize()
end

function Game.loadDb()
	--load db
	local cmd = io.popen('sqlite3 < sqlOpen.txt')
	local data = cmd:read('*a')
	local start = 1
	while true do
		local query
		_,start,query = data:find("(.-|.-|.-|.-|.-|.-|.-|.-)\n", start)
		if query then
			start = start + 1
			local c = Card:new(query)
			local id = c:getId()
			Game.card[id] = c
		else
			break
		end
	end
    cmd:close()
end

function Game.createShader()
	--field shader
	Game.shader = love.graphics.newShader('shader.glsl')
	Game.shader:send('fov', fov)
	Game.shader:send('angle', Game.angle)
	Game.shader:sendColor('selCol', {0, 0, 0, 0})
end

function Game.createCanvas()
	--screen canvas
	Game.canvas = love.graphics.newCanvas(Screen.width, Screen.height)
	
	--font
	Game.font = love.graphics.newFont('font.ttf', Screen.height/30)
	Game.font:setLineHeight(Game.font:getHeight()/1.8)
	love.graphics.setFont(Game.font)
end

function Game.startMatch()
	Game.match = Match:new()
end

function Game.getCard(id)
	local card = Game.card[id]
	if card then
		return card
	else
		error('Card ' .. id .. ' does not exist.')
	end
end

function Game.setShader(y)
	if y=='hand' then
		y = 0.6
	end
	if y=='table' then
		y = 0.0
	end
	
	if y==nil then
		love.graphics.setShader(Game.shader)
		Game.shaderSend('shader', 2)
	elseif y>0.5 or y<-0.5 then --hand
		love.graphics.setShader(Game.shader)
		Game.shaderSend('shader', 0)
	else --everywhere else
		love.graphics.setShader(Game.shader)
		Game.shaderSend('shader', 1)
	end
end

function Game.shaderSend(variable, value)
	Game.shader:send(variable, value)
end

function Game.shaderSendColor(variable, value)
	Game.shader:sendColor(variable, value)
end

function Game.getMousePosition()
	return Selector.getPosition()
end

function Game.getMouseScreenPosition()
	return Field.getGamePosition(Selector.getMousePosition())
end

function Game.getMatch()
	return Game.match
end

function Game.getFont()
	return Game.font
end

function Game.hasMouseClicked(button)
	if type(button)~='table' then
		--turn button into table if it's not yet
		button = {button}
	end
	
	for i,b in ipairs(button) do
		if Game.pressed.mouse[b]==nil then
			Game.pressed.mouse[b] = love.mouse.btnpressed(b)
		end
		if Game.pressed.mouse[b] then
			return true
		end
	end
	return false
end

function Game.hasKeyPressed(key)
	if type(key)~='table' then
		--turn key into table if it's not yet
		key = {key}
	end
	
	for i,k in ipairs(key) do
		if Game.pressed.keyboard[k]==nil then
			Game.pressed.keyboard[k] = love.keyboard.keypressed(k, Game.pressed.key)
		end
		if Game.pressed.keyboard[k] then
			return true
		end
	end
	return false
end





































