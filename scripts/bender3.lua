local cost = 3

local function condition(c, rc)
	return c:isLocation('table')
end

local function filter(c, tp)
	return c:isLocation('table') and not c:isSide(tp) and not c:isDisabled()
end

local function enableCon(c, turn)
	return getTurnCount()>=turn
end

local function operation(c, rc)
	local tp = c:getSide()
	if discharge(tp, cost, c) then
		local tc = choose(tp, 'Disable 1 card:', getCards(filter, tp), 1, 1)
		if tc then
			local turn = getTurnCount() + 3
			tc:disable({
				condition = enableCon,
				param = {turn},
			}, c)
		end
	end
end

return function(c)
	c:createEffect {
		condition = condition,
		operation = operation,
		description = "Disable 1 card from opponent's table until the end of your next turn.",
	}
end
