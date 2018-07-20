local cost = 2

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c)
	return c:isLocation('table') and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Destroy 1 card:', getCards(filter), 1, 1)
		if tc then
			tc:destroy(c)
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = 'Destroy 1 card from table.',
	}
end
