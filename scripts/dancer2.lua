local cost = 2

local function filter(c, tp)
	return c:isPlayable() and c:isLevel(3) and c:isElement('water') and c:isSide(tp) and c:isLocation('deck')
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Play 1 card:', getCards(filter, tp), 1, 1)
		if tc then
			tc:playOver(c, c)
		end
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'bind',
		description = 'Discharge 2, play 1 level 3 WATER from your deck over this card.',
	}
end
