local function filter(c, tp)
	return c:isLocation('table') and not c:isSide(tp) and not c:isBound() and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	local tc = choose(tp, 'Bind 1 card:', getCards(filter, tp), 1, 1)
	if tc then
		tc:bind(c)
		tc:move(c)
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'fusion_water',
		description = "Bind 1 card from opponent's table, [move that card].",
	}
end
