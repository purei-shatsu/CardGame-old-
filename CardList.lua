CardList = createClass({
	cardAmount = 5,
}, function(self)
	self.x = 0
	self.y = 0
	self.button = {
		ok = Button:new('ok.png', 0, 0, 'normal', false),
		left = Button:new('left.png', 0, 0, 'instant', false),
		right = Button:new('right.png', 0, 0, 'instant', false),
	}
	self.enabled = false
	self.selector = {
		box = Selector.create(),
		card = {},
	}
	for i=1,CardList.cardAmount do
		self.selector.card[i] = Selector.create()
	end
	self.grabbed = false
	self.selected = nil
	self.mouseDx = nil
	self.mouseDy = nil
end)

local function amountSelected(chosen)
	local count = 0
	for i in pairs(chosen) do
		count = count + 1
	end
	return count
end

function CardList:update(dt)
	for i,b in pairs(self.button) do
		b:update(dt)
	end
	if self.enabled then
		local amount = math.min(CardList.cardAmount, #self.list)
		
		--ok button
		if amountSelected(self.chosen)>=self.minimum then
			self.button.ok:enable()
			if self.button.ok:wasPressed() then
				self.enabled = false
			end
		else
			self.button.ok:disable()
		end
		
		--left button
		if self.position>0 then
			self.button.left:enable()
			if self.button.left:wasPressed() then
				self.position = self.position - 1
			end
		else
			self.button.left:disable()
		end
		
		--right button
		if CardList.cardAmount+self.position<#self.list then
			self.button.right:enable()
			if self.button.right:wasPressed() then
				self.position = self.position + 1
			end
		else
			self.button.right:disable()
		end
		
		--check clicks in the list
		if not self.grabbed then
			if not self.selected then
				if Game.hasMouseClicked(1) then
					--box
					if Selector.isId(self.selector.box) then
						self.grabbed = true
						self.mouseDx, self.mouseDy = Game.getMouseScreenPosition()
						self.mouseDx = self.x - self.mouseDx
						self.mouseDy = self.y - self.mouseDy
					end
					
					--cards
					for i=1,amount do
						if Selector.isId(self.selector.card[i]) then
							--check if not max amount or unselecting card
							if amountSelected(self.chosen)<self.maximum or self.chosen[i+self.position] then
								self.selected = i
							end
							break
						end
					end
				end
			else
				if not love.mouse.isDown(1) then
					if Selector.isId(self.selector.card[self.selected]) then
						--put/remove card into/from chosen list
						local i = self.selected + self.position
						if self.chosen[i] then
							self.chosen[i] = nil
						else
							self.chosen[i] = true
							---[[
							if amountSelected(self.chosen)==self.maximum then
								--close list if last card was selected
								self.enabled = false
							end
							--]]
						end
					end
					self.selected = nil
				end
			end
		else
			if love.mouse.isDown(1) then
				--drag box
				self.x, self.y = Game.getMouseScreenPosition()
				self.x = self.x + self.mouseDx
				self.y = self.y + self.mouseDy
				self.x = math.min(math.max(self.x, -0.5), 0.5)
				self.y = math.min(math.max(self.y, -0.5), 0.5)
			else
				--ungrab box
				self.grabbed = false
			end
		end
	else
		for i,b in pairs(self.button) do
			b:disable()
		end
	end
end

function CardList:draw()
	--show the list if choose or open has been called
	if self.enabled then
		local list = self.list
		local amount = math.min(CardList.cardAmount, #list)
		local cardDist = 0.01
		local cardHeight = PlayableCard.listingSize
		local cardWidth = PlayableCard.listingSize/Card.proportion + cardDist
		local buttonHeight = Button.size
		local distX = (amount-1)*cardWidth/2
		local distY = 0.01
		
		local cardRealHeight = PlayableCard.listingSize*Screen.height
		local cardRealWidth = cardRealHeight/Card.proportion
		
		local font = Game.getFont()
		local fontHeight = font:getLineHeight()/Screen.height
		local fontOriginalHeight = font:getHeight()/Screen.height
		
		--box
		Selector.sendId(self.selector.box)
		love.graphics.setColor(127, 127, 127, 255)
		local w = (cardDist*2 + math.max(math.max(amount,2)*cardWidth, font:getWidth(self.text)/Screen.height))*Screen.height
		local h = (distY*4 + cardHeight + buttonHeight + fontHeight)*Screen.height
		local x, y = Field.getScreenPosition(self.x, self.y)
		love.graphics.rectangle('fill', x-w/2, y-h/2, w, h)
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle('line', x-w/2, y-h/2, w, h)
		love.graphics.rectangle('line', x-w/2-1, y-h/2-1, w+2, h+2)
		love.graphics.setColor(255, 255, 255, 255)
		
		--text
		love.graphics.printf(self.text, x-w/2, y-h/2 + (fontHeight/2 - fontOriginalHeight/2 + distY)*Screen.height, w, 'center')
		
		--cards
		for i=1,amount do
			local selector = self.selector.card[i]
			Selector.setObject(selector, self.list[i+self.position])
			Selector.sendId(selector)
			if self.selected==i and Selector.isId(selector) then
				love.graphics.setColor(200, 200, 200, 255)
			end
			local c = list[i+self.position]
			local cx = self.x + (i-1)*cardWidth - distX
			local cy = self.y - buttonHeight/2 + fontHeight/2
			c:drawListing(cx, cy)
			if self.chosen[i+self.position] then
				--draw selected
				local rcx, rcy = Field.getScreenPosition(cx, cy)
				love.graphics.setColor(255, 255, 0, 255)
				love.graphics.rectangle('line', rcx-cardRealWidth/2, rcy-cardRealHeight/2, cardRealWidth, cardRealHeight)
				love.graphics.rectangle('line', rcx-cardRealWidth/2-1, rcy-cardRealHeight/2-1, cardRealWidth+2, cardRealHeight+2)
			end
			love.graphics.setColor(255, 255, 255, 255)
		end
		
		--buttons
		local buttonDist = 0.08
		local by = self.y + distY + cardHeight/2 + fontHeight/2
		self.button.ok:draw(self.x, by)
		self.button.left:draw(self.x - buttonDist, by)
		self.button.right:draw(self.x + buttonDist, by)
	end 
end

function CardList:open(text, list, minimum, maximum)
	--open list (just to see the cards)
	self.minimum = minimum or 0
	self.maximum = maximum or self.minimum
	self.maximum = math.min(self.maximum, #list)
	self.position = 0
	self.enabled = true
	self.list = list
	self.text = text
	self.chosen = {}
end

function CardList:choose(text, list, minimum, maximum)
	--check if list is valid
	if minimum and #list<minimum then
		print('Not enough cards in the list.')
		return nil
	end
	
	--open list and waits for cards to be chosen (with yield)
	self:open(text, list, minimum, maximum)
	coroutine.yield(function(dt)
		return not self.enabled
	end)
	
	--return the chosen list
	local chosen = {}
	for i in pairs(self.chosen) do
		chosen[#chosen+1] = list[i]
	end
	return chosen
end

function CardList:isEnabled()
	return self.enabled
end
















