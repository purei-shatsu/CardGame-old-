Match = createClass({
	AIMode = false,
	noEffects = true,
	thinkingTime = 0.01,
},
function(self)
	self.ai = {false, false} --true makes AI control that player
	self.player = {}
	self.zone = {}
	local deck = {'birds 1', 'benders 1'}
	--local deck = {'igniters 1', 'builders 1'}
	--local deck = {'igniters 1', 'benders 1'}
	for i=1,2 do
		self.player[i] = Player:new(deck[i], i)
		for j=1,5 do
			self.zone[#self.zone+1] = ZoneInterface:new(i, j)
		end
	end
	self.routine = {
		command = coroutine.create(function()
			return self:loop()
		end),
		condition = nil,
	}
	self.card = self.player[1]:getCards()
	table.merge(self.card, self.player[2]:getCards())
	self.grabbed = nil
	self.attacking = nil
	self.activating = nil
	self.button = {
		attackPhase = Button:new('attackPhase.png', 0, -0.075, 'normal', true),
		endTurn = Button:new('endTurn.png', 0.17, -0.075, 'normal', true),
	}
	self.list = {
		choose = CardList:new(),
		--here new lists are created on the go, also
	}
	self.listFlag = {{},{}} --one for each player
	self.listFlagInv = {}
	self.info = nil
	self.event = {}
	self.thoughtStart = nil
	self:createCanvas()
end)

function Match:createCanvas()
	--create background for position canvas
	self.canvas = {}
	
	local width, height = Screen.width, Screen.height
	self.canvas.screen = love.graphics.newCanvas(width, height)
	
	width, height = Screen.width*2, Screen.height
	self.canvas.table = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas(self.canvas.table)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('fill', 0, 0, width, height)
	
	width, height = Screen.width*2, Screen.height
	self.canvas.hand = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas(self.canvas.hand)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('fill', 0, 0, width, height)
	
	love.graphics.setCanvas()
end

function Match:loop()
	AI.initialize()
	while true do --play FOREVER!
		--draw starting hand
		for i,p in ipairs(self.player) do
			p:shuffleDeck() --disabling this bugs the AI for some reason, so never do it
			p:drawCard(6)
			self:mulligan(i)
		end
		
		--first turn
		self.phase = 'draw'
		self.tp = math.random(1,2)
		self.turnCount = 1
		self.victory = nil
		
		while not self.victory do
			self:anyPhase()
			if self.phase=='draw' then
				self:drawPhase()
			end
			if self.phase=='main' then
				self:mainPhase()
			end
			if self.phase=='attack' then
				self:attackPhase()
			end
			if self.phase=='end' then
				self:endPhase()
			end
			self:checkWinConditions()
			coroutine.yield()
		end
		
		print('Game Over', self.victory)
		self:resetMatch()
	end
end

------------------------------------------------------------------------
---------------------------------PHASES---------------------------------
------------------------------------------------------------------------

function Match:anyPhase()
	--buttons
	self:runButtons()
	
	--events
	self:triggerEvents()
	
	--enable cards
	for i=1,2 do
		self.player[i]:enable()
	end
end

function Match:drawPhase()
	if self.turnCount>2 then
		--normal draw
		self.player[self.tp]:drawCard(1)
	end
	
	self:changePhase('main')
end

function Match:mainPhase()
	if not self:isAI(self.tp) then
		--move cards
		if not self.grabbed then
			if not self.activating then
				if Game.hasMouseClicked(1) then
					self.grabbed = self.player[self.tp]:tryGrab(true)
				elseif Game.hasMouseClicked(2) then
					self.activating = self.player[self.tp]:tryActivate()
				end
			else
				if not love.mouse.isDown(2) then
					self.activating:finishActivation()
					self.activating = nil
				end
			end
		else
			if not love.mouse.isDown(1) then
				local ret = self.grabbed:ungrab()
				if ret=='fusion' then
					self.player[self.tp]:drawCard(1)
				end
				self.grabbed = nil
			end
		end
	else
		--AI Main Phase
		self:setAIMode(true)
		local ret = AI.mainPhase(self.tp)
		self:setAIMode(false)
		local command = ret.command
		if not command then
			--go to attack phase (end phase if turn 1)
			if self.turnCount>1 then
				self:changePhase('attack')
			else
				self:changePhase('end')
			end
		elseif command=='play' then
			--play a card
			local c = ret.card:getPlayableCard()
			local f = ret.component
			if f then
				for i,fc in ipairs(f) do
					f[i] = fc:getPlayableCard()
				end
			end
			if c:playAI(f)=='fusion' then --draw if fusion
				self.player[self.tp]:drawCard(1)
			end
		elseif command=='activate' then
			--activate an effect
			local c = ret.card:getPlayableCard()
			local e = ret.effect
			c:activateAI(e)
		elseif command=='move' then
			--move a card
			local c = ret.card:getPlayableCard()
			local z = ret.zone
			c:moveAI(z)
		end
	end
end

function chosenFilter(card, used)
	for i,c in ipairs(used) do
		if c==card then
			return false
		end
	end
	return true
end

function Match:attackPhase()
	if not self:isAI(self.tp) then
		--attack cards
		--[[
		if not self.attacking then
			if Game.hasMouseClicked(1) then
				self.attacking = self.player[self.tp]:tryAttack()
			end
		else
			if not love.mouse.isDown(1) then
				self.attacking:finishAttack()
				self.attacking = nil
			end
		end
		--]]
		if Game.hasMouseClicked(1) then
			local target = self.player[3-self.tp]:tryAttack()
			local power = self.player[self.tp]:getBattlePower()
			if target then
				local isDeck = target:isLocation('deck')
				local level = isDeck and 0 or target:getCard():getLevel()
				if power>level then
					local attacker = self.player[self.tp]:getAttackers()
					local chosen = {}
					local power = 0
					
					--choose until surpasses level
					while power<=level do
						local ch = self:chooseFromList(self.side, 'Choose attacker(s):', attacker, 1, 1)
						for i,c in ipairs(ch) do
							chosen[#chosen+1] = c
							power = power + c:getCard():getLevel()
						end
						attacker = table.filter(attacker, chosenFilter, ch)
					end
					
					for i,c in ipairs(chosen) do
						c:bind()
					end
					target:finishAttack()
				end
			end
		end
	else
		--TODO arrumar isso com novas regras
		--AI Attack Phase
		self:setAIMode(true)
		local ret = AI.attackPhase(self.tp)
		self:setAIMode(false)
		local command = ret.command
		if not command then
			--end turn
			self:changePhase('end')
		elseif command=='attack' then
			--attack
			local c = ret.attacker:getPlayableCard()
			local t = ret.target
			if class(t)==CardInterface then
				t = t:getPlayableCard()
			end
			c:attackAI(t)
		end
	end
end

function Match:endPhase()
	--unbind turn player cards
	self.player[self.tp]:unbind()
	
	--reset effects
	for i,c in ipairs(self.card) do
		c:resetEffects()
	end
	
	--swap turn player
	self.tp = 3-self.tp
	
	--increase turn count
	self.turnCount = self.turnCount + 1
	
	--go to draw phase
	self:changePhase('draw')
end

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

function Match:mulligan(tp)
	self.player[tp]:mulligan()
end

function Match:runButtons()
	if not self:isAI(self.tp) then
		--enter attack phase
		if self.phase=='main' and self.turnCount>1 then
			self.button.attackPhase:enable()
			if self.button.attackPhase:wasPressed() then
				self:changePhase('attack')
			end
		else
			self.button.attackPhase:disable()
		end
		
		--end turn
		if self.phase=='main' or self.phase=='attack' then
			self.button.endTurn:enable()
			if self.button.endTurn:wasPressed() then
				self:changePhase('end')
			end
		else
			self.button.endTurn:disable()
		end
	else
		--disable buttons for AI
		self.button.attackPhase:disable()
		self.button.endTurn:disable()
	end
end

function Match:checkWinConditions()
	local lost = {}
	local reason = {}
	for i=1,2 do
		lost[i], reason[i] = self.player[i]:hasLost()
	end
	
	if lost[1] and lost[2] then
		self.victory = 'draw'
		print(reason[1], reason[2])
		coroutine.yield(function()
			--TODO draw animation
			return true
		end)
	elseif lost[1] then
		self.victory = 1
		print(reason[1])
		coroutine.yield(function()
			--TODO defeat animation
			return true
		end)
	elseif lost[2] then
		self.victory = 2
		print(reason[2])
		coroutine.yield(function()
			--TODO victory animation
			return true
		end)
	end
end

function Match:triggerEvents()
	for i,e in ipairs(self.event) do
		e.card:triggerEvent(e.event, unpack(e.param))
	end
	self.event = {}
end

function Match:changePhase(phase)
	self.phase = phase
	for i=1,2 do
		self.player[i]:reachDestination()
	end
	AI.resetDP()
	coroutine.yield(function()
		--TODO wait for phase change (animation) to complete
		return true
	end)
end

function Match:update(dt)
	--routine
	local routine = self.routine
	local command = routine.command
	local status = coroutine.status(command)
	if status=='dead' then
		--TODO Game over
	elseif status=='suspended' then
		local condition = routine.condition
		if not condition or condition(dt) then
			self:startThinking()
			ok, routine.condition = coroutine.resume(command)
			if not ok then
				local errorMsg = routine.condition
				error('Coroutine Error\n' .. debug.traceback(command, errorMsg))
			end
		end
	end
	
	--temporarily disable AIMode
	local aiMode = Match.AIMode
	Match.AIMode = false
	
	--players
	for i,p in ipairs(self.player) do
		p:update(dt)
	end
	
	--buttons
	for i,b in pairs(self.button) do
		b:update(dt)
	end
	
	--lists
	for i,l in pairs(self.list) do
		l:update(dt)
	end
	
	--show info card
	for i=1,2 do
		local info = self.player[i]:tryInfo()
		if info~=false then
			self.info = info
		end
	end
	
	--show list if click on discard, damage or component
	if Game.hasMouseClicked(1) then
		for i=1,2 do
			local list = self.player[i]:tryList()
			if list then
				--check if that location isn't already opened
				local card = list[1]
				local side = card:getSide()
				local location = card:getLocation()
				local id = self.listFlag[side][location]
				if not id or not self.list[id]:isEnabled() then
					--find an disabled list
					for i,l in ipairs(self.list) do
						if not l:isEnabled() then
							id = i
							break
						end
					end
					--or create a new one
					if not id then
						id = #self.list+1
						self.list[id] = CardList:new()
						self.listFlagInv[id] = {}
					else
						local last = self.listFlagInv[id]
						self.listFlag[last.side][last.location] = nil
					end
					--and open it
					self.list[id]:open(self:getLocationString(location), list)
					self.listFlag[side][location] = id
					self.listFlagInv[id].side = side
					self.listFlagInv[id].location = location
				end
			end
		end
	end
	
	--restore AIMode
	Match.AIMode = aiMode
end

function Match:draw(x, y)
	love.graphics.push()
	--[[
	love.graphics.translate(Screen.width/2, Screen.height/2)
	love.graphics.rotate(love.mouse.getX()*math.pi*2/Screen.width)
	love.graphics.translate(-Screen.width/2, -Screen.height/2)
	--]]
	Selector.sendDiff(x, y)
	local canvas = {love.graphics.getCanvas()}
	love.graphics.setCanvas(self.canvas.screen)
	love.graphics.clear()
	local canvas1 = canvas[1]
	canvas[1] = self.canvas.screen
	love.graphics.setCanvas(unpack(canvas))
	
	--field
	Field.draw()
	
	--cards
	table.sort(self.card, PlayableCard.drawOrder)
	for i,c in ipairs(self.card) do
		c:draw()
	end
	
	--draw for position canvas
	self:drawPositionCanvas()
	
	--buttons
	for i,b in pairs(self.button) do
		b:draw()
	end
	
	--lists
	--[[
	for i,l in pairs(self.list) do
		l:draw()
	end
	--]]
	self.list.choose:draw()
	for i,l in ipairs(self.list) do
		l:draw()
	end
	
	love.graphics.pop()
	
	Game.setShader()
	love.graphics.setCanvas(canvas1)
	love.graphics.draw(self.canvas.screen, x, y)
	canvas[1] = canvas1
	love.graphics.setCanvas(unpack(canvas))
	
	--info card (directly on game canvas)
	Selector.sendId(0)
	local ix = x/2 + (Screen.width-Screen.height)/4
	local iy = Screen.height/2
	if self.info then
		self.info:drawFloat(ix, iy, 0.9)
	else
		Card.drawFloat(nil, ix, iy, 0.9)
	end
end

function Match:drawPositionCanvas()
	--draw screen for position canvas
	Game.shaderSend('positionFlag', 1)
	love.graphics.setColor(0,0,0,1)
	
	Game.setShader('table')
	local width, height = self.canvas.table:getDimensions()
	Game.shaderSend('width', width)
	Game.shaderSend('height', height)
	local rx,ry = Screen.width/2, Screen.height/2
	Game.shaderSend('rx', rx)
	Game.shaderSend('ry', ry)
	love.graphics.draw(self.canvas.table, rx, ry, 0, 1, nil, width/2, height/2)
	
	Game.setShader('hand')
	local width, height = self.canvas.hand:getDimensions()
	Game.shaderSend('width', width)
	Game.shaderSend('height', height)
	local rx,ry = Screen.width/2, Screen.height+height/2
	Game.shaderSend('rx', rx)
	Game.shaderSend('ry', ry)
	love.graphics.draw(self.canvas.hand, rx, ry, 0, 1, nil, width/2, height/2)
	local rx,ry = Screen.width/2, -height/2
	Game.shaderSend('rx', rx)
	Game.shaderSend('ry', ry)
	love.graphics.draw(self.canvas.hand, rx, ry, 0, 1, nil, width/2, height/2)
	
	love.graphics.setColor(255,255,255,255)
	Game.shaderSend('positionFlag', 0)
end

function Match:getHandSize(player)
	return self.player[player]:getHandSize()
end

function Match:getCards()
	local card = {}
	for i,c in ipairs(self.card) do
		card[i] = c
	end
	return card
end

function Match:getZones()
	local zone = {}
	for i,z in ipairs(self.zone) do
		zone[i] = z
	end
	return zone
end

function Match:getLocationString(location)
	if class(location)==PlayableCard then
		return 'Components'
	elseif location=='hand' then
		return 'Hand'
	elseif location=='deck' then
		return 'Deck'
	elseif location=='discard' then
		return 'Discard Pile'
	elseif location=='damage' then
		return 'Damage Zone'
	elseif location=='table' then
		return 'Table'
	end
end

function Match:canAttackBackrow(tp)
	return self.player[tp]:canAttackBackrow()
end

function Match:damage(tp, amount)
	self.player[tp]:damage(amount)
end

function Match:drawCard(tp, amount)
	self.player[tp]:drawCard(amount)
end

function Match:shuffleHand(tp)
	self.player[tp]:shuffleHand()
end

function Match:shuffleDeck(tp)
	self.player[tp]:shuffleDeck()
end

function Match:chooseFromList(tp, text, list, minimum, maximum)
	--reveal all cards in the list, ignoring AI (still necessary because of choices)
	for i,c in ipairs(list) do
		c:setUnknown(false, true)
	end
	
	--choose
	local chosen
	if self:isAI(tp) then
		local ret = AI.chooseFromList(tp, text, interface(list), minimum, maximum)
		chosen = ret and pcard(ret)
	else
		chosen = self.list.choose:choose(text, list, minimum, maximum)
	end
	
	--shuffle deck(s) if it was seen
	local deck = {}
	for i,c in ipairs(list) do
		if c:isLocation('deck') then
			deck[c:getSide()] = true
		end
	end
	for tp in pairs(deck) do
		self:shuffleDeck(tp)
	end
	
	--reveal chosen cards, ignoring AI
	if chosen then
		for i,c in ipairs(chosen) do
			c:setUnknown(false, true)
		end
	end
	
	return chosen
end

function Match:scheduleEvent(card, event, ...)
	self.event[#self.event+1] = {
		card = card,
		event = event,
		param = {...},
	}
end

function Match:getTurnCount()
	return self.turnCount
end

function Match:getTurnPlayer()
	return self.tp
end

function Match:isAI(tp)
	return Match.isAIMode() or self.ai[tp]
end

function Match:resetMatch()
	self:reachDestination()
	for i=1,2 do
		self.player[i]:resetMatch()
	end
end

function Match:reachDestination()
	for i=1,2 do
		self.player[i]:reachDestination()
	end
end

function Match:getLife(tp)
	return self.player[tp]:getLife()
end

function Match:hasLost(tp)
	return self.player[tp]:hasLost()
end

function Match:setAIMode(mode)
	if mode then
		for i,c in ipairs(self.card) do
			c:createState()
		end
	else
		for i,c in ipairs(self.card) do
			c:destroyState()
		end
	end
	Match.AIMode = mode
end

function Match.isAIMode()
	return Match.AIMode
end

function Match.setKnownMode(mode)
	Match.knownMode = mode
end

function Match.isKnownMode()
	return Match.knownMode
end

function Match:startThinking()
	self.thoughtStart = love.timer.getTime()
end

function Match:think()
	local elapsedTime = love.timer.getTime() - self.thoughtStart
	if elapsedTime>Match.thinkingTime then
		coroutine.yield()
		local diff = elapsedTime - Match.thinkingTime
		self.thoughtStart = self.thoughtStart - diff
	end
end

function Match:saveState()
	for i,c in ipairs(self.card) do
		c:saveState()
	end
end

function Match:loadState()
	for i,c in ipairs(self.card) do
		c:loadState()
	end
end
























