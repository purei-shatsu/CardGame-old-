AI = {}

function AI.initialize()
	AI.card = getCards()
	local match = Game.getMatch()
	AI.zone = match:getZones()
	AI.resetDP()
end

function AI.resetDP()
	AI.dp = {}
end

local function canPlay(c, tp, card, emptyZone)
	--opponent's card
	if not c:isSide(tp) then
		return false
	end
	
	--not on hand
	if not c:isLocation('hand') then
		return false
	end
	
	--unknown
	if c:isUnknown() then
		return false
	end
	
	--level 0
	local level = c:getLevel()
	if level==0 then
		--TODO permitir que levels 0 sejam jogados
		return false
	end
	
	--level 1
	if level==1 then
		return emptyZone>0
	end
	
	--level >=2: check fusion
	local mg = table.filter(card, PlayableCard.mfilter, tp, level)
	return c:getPlayableCard():canFusionPlay()
end

local function emptyZone(z, tp)
	return z:isSide(tp) and z:isEmpty()
end

local function validZone(z, tp)
	--opponent's zone
	if not z:isSide(tp) then
		return false
	end
	
	--occupied and bound or disabled
	local c = z:getCard()
	if c and (c:isBound() or c:isDisabled()) then
		return false
	end
	
	return true
end

local function canMove(c, tp)
	--opponent's card
	if not c:isSide(tp) then
		return false
	end
	
	--not on table
	if not c:isLocation('table') then
		return false
	end
	
	--bound or disabled
	if c:isBound() or c:isDisabled() then
		return false
	end
	
	return true
end

function AI.mainPhase(tp)
	local best = AI.playPhase(tp)
	
	if best.command then
		--return best move (if any)
		return best
	else
		--otherwise, position table cards
		local ret = AI.move(tp)
		if ret then
			best = ret
			best.command = 'move'
			return best
		end
	end
	
	return {}
end

local function playLevel1Filter(c, tp)
	return c:isSide(tp) and c:isLocation('table') and c:isLevelAbove(2)
end

function AI.playPhase(tp)
	local match = Game.getMatch()
	match:think()
	
	--test DP
	local ret = AI.loadDP(tp)
	if ret then
		return ret
	end
	
	--get current state
	local state = {
		value = AI.calculateAdvantage(tp),
		--check if level 1s can attack deck or be protected
		playLevel1 = Game.getMatch():canAttackBackrow(3-tp) or table.exists(AI.card, playLevel1Filter, tp),
	}
	local best = {
		value = state.value,
		playLevel1 = state.playLevel1,
	}
	
	--play cards
	ret = AI.play(tp, {
		value = state.value,
		playLevel1 = state.playLevel1,
	})
	if ret.value>best.value then
		best = ret
		best.command = 'play'
	end
	
	--activate effects
	ret = AI.activate(tp, {
		value = state.value,
		playLevel1 = state.playLevel1,
	})
	if ret.value>best.value then
		best = ret
		best.command = 'activate'
	end
	
	--save DP
	AI.saveDP(tp, best)
	
	return best
end

local function canAttack(c, tp)
	--opponent's card
	if not c:isSide(tp) then
		return false
	end
	
	--not on table
	if not c:isLocation('table') then
		return false
	end
	
	--can attack
	return c:canAttack()
end

local function canBeAttacked(c, tp)
	--own card
	if c:isSide(tp) then
		return false
	end
	
	--not on table
	if not c:isLocation('table') then
		return false
	end
	
	--disabled
	if c:isDisabled() then
		return false
	end
	
	--protected
	if not Game.getMatch():canAttackBackrow(3-tp) and c:getPosition()>3 then
		return false
	end
	
	return true
end

local function canActivate(c, tp)
	--opponent's card
	if not c:isSide(tp) then
		return false
	end
	
	--unknown
	if c:isUnknown() then
		return false
	end
	
	--disabled
	if c:isDisabled() then
		return false
	end
	
	--check if has activable effects
	return #c:getActivableEffects()>0
end

function AI.attackPhase(tp)
	local ret, best
	
	--attack
	best = AI.attack(tp)
	if best.attacker then
		best.command = 'attack'
	end
	
	return best
end

local function highestLevel(a, b)
	return a:getLevel()>b:getLevel()
end

function AI.chooseFromList(tp, text, list, minimum, maximum)
	--check if list is valid
	if minimum and #list<minimum then
		print('Not enough cards in the list.')
		return nil
	end
	
	--default parameters
	minimum = minimum or 0
	maximum = maximum or minimum
	maximum = math.min(maximum, #list)
	
	--TODO criar uma função separada para fazer isso, que retorne alguma coisa
	--choosing logic
	if text=='Choose substitute:' then
		--order by level
		table.sort(list, highestLevel)
	end
	
	--choose as many as possible
	local chosen = {}
	for i=1,maximum do
		chosen[i] = list[i]
	end
	return chosen
end

local function valueFilter(c, tp)
	return c:isSide(tp) and c:isLocation('table') and not c:isDisabled()
end

local function calculateValue(tp, card)
	--get table cards for this player
	local tableCard = table.filter(card, valueFilter, tp)
	
	--iterate table cards
	local level = {}
	for i,c in ipairs(tableCard) do
		--add card level to table
		level[#level+1] = c:getLevel()
		
		--add component's levels, without repeating
		local flag = {
			[0] = true, --ignore level 0s
		}
		for j,cc in ipairs(c:getComponents()) do
			local lv = cc:getLevel()
			if not flag[lv] then
				flag[lv] = true
				level[#level+1] = lv
			end
		end
	end
	
	--count cards in hand as level 0.1s
	for i=1,Game.getMatch():getHandSize(tp) do
		level[#level+1] = 0.1
	end
	
	--sort table
	table.sort(level)
	
	--calculate value
	local value = 0
	for i,lv in ipairs(level) do
		value = value/10
		value = value + lv
	end
		
	return value
end

function AI.calculateAdvantage(tp)
	local card = AI.card
	--TODO test lose conditions and attribute constant values if someone lost (AI.attack style)
	return calculateValue(tp, card) - calculateValue(3-tp, card)
end

local function componentFilter(c, tp, used, level, elem)
	return not used[c] and c:isLocation('table') and c:isSide(tp) and c:isLevelBelow(level) and (not elem or c:isElement(elem, 'left'))
end

function chooseComponents(tp, card, list, used, level, chosen, elem)
	if level==0 then
		--all components chosen, play card
		saveState()
		
		--continue search
		card:playAI(chosen)
		local ret = AI.playPhase(tp)
		
		--save chosen components
		ret.card = card
		ret.component = {}
		for i,cc in ipairs(chosen) do
			ret.component[i] = cc
		end
		
		loadState()
		return ret
	end
	
	local best
	
	--choose next component
	local comp = table.filter(list, componentFilter, tp, used, level, elem)
	for i,c in ipairs(comp) do
		--mark choice
		used[c] = true
		chosen[#chosen+1] = c
		
		--continue
		local ret = chooseComponents(tp, card, list, used, level-c:getLevel(), chosen, c:getElement('right'))
		
		--save move if best so far
		if ret and (not best or ret.value>best.value) then
			best = ret
		end
		
		--undo choice
		chosen[#chosen] = nil
		used[c] = false
	end
	
	return best
end

local function dpFilter(c, tp)
	--cards that are relevant to the virtual game state
	return (c:isLocation('table') or c:isComponent())
end

local function dpCode(c)
	local code = 0
	
	--disabled (yes or no)
	code = code*2
	if c:isDisabled() then
		code = code + 1
	end
	
	--bound (yes or no)
	code = code*2
	if c:isBound() then
		code = code + 1
	end
	
	--binary effects (activable or not)
	local effect = c:getEffects()
	for i,e in ipairs(effect) do
		code = code*2
		if e:canActivate(nil, c) then
			code = code + 1
		end
	end
	return code
end

function AI.loadDP(tp)
	local card = table.filter(AI.card, dpFilter, tp)
	local ret = AI.dp
	for i,c in ipairs(card) do
		local location = c:getLocation()
		local code = dpCode(c)
		ret = ret[c] and ret[c][location] and ret[c][location][code]
		if not ret then
			return false
		end
	end
	return ret.dp
end

function AI.saveDP(tp, best)
	local card = table.filter(AI.card, dpFilter, tp)
	local ret = AI.dp
	for i,c in ipairs(card) do
		ret[c] = ret[c] or {}
		ret = ret[c]
		
		local location = c:getLocation()
		ret[location] = ret[location] or {}
		ret = ret[location]
		
		local code = dpCode(c)
		ret[code] = ret[code] or {}
		ret = ret[code]
	end
	ret.dp = best
end

function AI.play(tp, best)
	local ret
	
	--get all cards that can be played now
	local emptyZone = table.filter(AI.zone, emptyZone, tp)
	local card = table.filter(AI.card, canPlay, tp, AI.card, #emptyZone)
	
	--test plays
	for i,c in ipairs(card) do
		saveState()
		
		if c:isLevel(1) then
			--just play
			c:playAI()
			local ret = AI.playPhase(tp)
			
			--save move if best so far and should play level 1
			if ret.value>best.value and ret.playLevel1 then
				best.card = c
				best.component = nil
				best.value = ret.value
				best.playLevel1 = ret.playLevel1
			end
		else
			--choose components
			local used = {}
			local ret = chooseComponents(
				tp,
				c,
				table.filter(AI.card, componentFilter, tp, used, c:getLevel()-1),
				used,
				c:getLevel(),
				{},
				nil)
			
			--save move if best so far
			if ret.value>best.value then
				best.card = c
				best.component = ret.component
				best.value = ret.value
				best.playLevel1 = ret.playLevel1
			end
		end
		
		loadState()
	end
	
	return best
end

function AI.activate(tp, best)
	local ret
	
	--get all cards with effects that can be activated now
	local card = table.filter(AI.card, canActivate, tp)
	
	--test effects
	for i,c in ipairs(card) do
		for j,e in ipairs(c:getActivableEffects()) do
			saveState()
			
			c:activateAI(e)
			local ret = AI.playPhase(tp)
			
			--save move if best so far
			if ret.value>best.value then
				best.card = c
				best.effect = e
				best.value = ret.value
				best.playLevel1 = ret.playLevel1
			end
			
			loadState()
		end
	end
	
	return best
end

function AI.move(tp)
	local card = table.filter(AI.card, canMove, tp)
	local zone = table.filter(AI.zone, validZone, tp)
	if #card>0 and #zone>0 then
		--order cards by level
		table.sort(card, highestLevel)
		
		--order zones by position
		table.sort(zone, ZoneInterface.minPosition)
		
		--swap position 1 and 2 (if possible)
		for i,zi in ipairs(zone) do
			if zi:getPosition()==1 then
				for j,zj in ipairs(zone) do
					if zj:getPosition()==2 then
						zone[i] = zj
						zone[j] = zi
						break
					end
				end
				break
			end
		end
		
		--[[
		--put highest level on first position
		local c = card[1]
		local z = zone[1]
		if c:getPosition()~=z:getPosition() then
			return {
				card = c,
				zone = z,
			}
		end
		
		--put lowest levels on back row
		local j = #zone
		for i=#card,math.max(2, #card-1),-1 do
			c = card[i]
			z = zone[j]
			if c:getPosition()~=z:getPosition() then
				return {
					card = c,
					zone = z,
				}
			end
			j = j - 1
		end
		--]]
		
		--put cards in level order
		for i,c in ipairs(card) do
			local z = zone[i]
			if c:getPosition()~=z:getPosition() then
				return {
					card = c,
					zone = z,
				}
			end
		end
	end
	print('final', calculateValue(tp, AI.card))
	
	return nil
end

function AI.attack(tp)
	local match = Game.getMatch()
	match:think()
	
	--test DP
	local ret = AI.loadDP(tp)
	if ret then
		return ret
	end
	
	local best = {
		attacker = nil,
		target = nil,
		value = 0,
	}
	
	local lost1 = match:hasLost(tp)
	local lost2 = match:hasLost(3-tp)
	if lost1 and lost2 then
		--draw (go for it unless a victory is possible)
		best.value = 50000
		return best
	elseif lost1 then
		--defeat (never go for it)
		best.value = -100000
		return best
	elseif lost2 then
		--victory (always go for it)
		best.value = 100000
		return best
	end
	
	local attacker = getCards(canAttack, tp)
	local target = getCards(canBeAttacked, tp)
	if match:canAttackBackrow(3-tp) then
		target[#target+1] = 'deck'
	end
	
	for i,a in ipairs(attacker) do
		saveState()
		
		for j,t in pairs(target) do
			saveState()
			
			--attack
			local levelDiff, damageDiff = a:attackAI(t)
			
			--continue search
			local ret = AI.attackPhase(tp)
			ret.value = ret.value + levelDiff + damageDiff/100
			
			--save move if best so far
			if ret.value>best.value then
				best.attacker = a
				best.target = t
				best.value = ret.value
			end
			
			loadState()
		end
		
		loadState()
	end
	
	--save DP
	AI.saveDP(tp, best)
	
	return best
end

















