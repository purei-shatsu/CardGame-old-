local function filter(c)
	return c:isLocation('table') and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	local tc = choose(tp, 'Destroy 1 card:', getCards(filter), 1, 1)
	if tc then
		tc:destroy(c)
	end
end

return function(c)
	c:createEffect {
		operation = operation,
		event = 'destroy',
		description = 'Destroy 1 card from table.',
	}
end
