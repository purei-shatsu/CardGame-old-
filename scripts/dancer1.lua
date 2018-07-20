local cost = 1

local function filter(c, tp)
	return c:isPlayable() and c:isLevel(2) and c:isElement('water') and c:isSide(tp) and c:isLocation('deck')
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		c:shuffle(c)
		local tc = choose(tp, 'Play 1 card:', getCards(filter, tp), 1, 1)
		if tc then
			tc:play(c)
		end
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'bind',
		description = 'Discharge 1, shuffle this card into your deck, play 1 level 2 WATER from your deck.',
	}
end
