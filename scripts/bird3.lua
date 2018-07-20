local cost = 3

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c, tp)
	return c:isElement('sky') and c:isSide(tp) and c:isLocation('damage') and not c:isDisabled()
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Add 1 card to hand:', getCards(filter, tp), 1, 1)
		if tc then
			tc:add(c)
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = 'Add 1 SKY from your damage zone to your hand.',
	}
end
