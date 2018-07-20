local cost = 2

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c)
	return c:isLocation('table') and not c:isDisabled()
end

local function filter2(c, tp)
	return c:isLocation('hand') and not c:isSide(tp) and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Add 1 card to hand:', getCards(filter), 1, 1)
		if tc then
			if tc:add(c) then
				local hc = getCards(filter2, tp)
				local tc2 = hc:random()
				if tc2 then
					tc2:discard(c)
				end
			end
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = "Add 1 card from table to it's owner hand, opponent discards 1 random card from his/her hand.",
	}
end
