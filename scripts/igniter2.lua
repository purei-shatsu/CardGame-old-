local cost = 2

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c, tp)
	return c:isPlayable() and c:isLevel(1) and c:isElement('fire') and c:isSide(tp) and c:isLocation('deck')
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Play 1 card:', getCards(filter, tp), 1, 1)
		if tc then
			tc:play(c)
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = 'Play 1 level 1 FIRE from your deck.',
	}
end
