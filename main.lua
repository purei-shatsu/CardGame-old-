require 'utils'
require 'Game'
require 'Card'
require 'Player'
require 'PlayableCard'
require 'Field'
require 'Match'
require 'Selector'
require 'Button'
require 'CardList'
require 'Effect'
require 'CardInterface'
require 'ZoneInterface'
require 'AI'
require 'Group'
require 'scriptCommands'

function love.load()
	math.randomseed(os.time())
	Screen = {
		width = 1280,
		height = 720,
	}
	Screen.proportion = Screen.width/Screen.height
	love.window.setMode(Screen.width, Screen.height)
	--love.graphics.setBackgroundColor(122, 182, 255)
	love.graphics.setBackgroundColor(145, 88, 18)
	
	Game.initialize()
end

function love.wheelmoved(x, y)
	Game.wheelmoved(x, y)
end

local spaceFlag = true
local runGame = true
local fps
function love.update(dt)
	fps = love.timer.getFPS()
	if love.keyboard.isDown('space') then
		if not spaceFlag then
			spaceFlag = true
			runGame = not runGame
			if runGame then
				print('running')
			else
				print('not running')
			end
		end
	else
		spaceFlag = false
	end
	if not runGame then
		dt = 0
	end
	
	Game.update(dt)
end

function love.draw()
	Game.draw()
end

















